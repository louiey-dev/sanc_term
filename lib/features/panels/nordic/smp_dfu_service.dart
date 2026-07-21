import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

/// SMP (Simple Management Protocol / MCUMGR) Service and Characteristic UUIDs
class SmpUuids {
  static const service = '8d53a89d-0601-4952-b5e1-0f6222b4e723';
  static const characteristic = 'da2e7828-fb13-4ae6-a727-71bf98180c3a';
  static const serviceShort = 'aa55';
}

/// DFU Status states
enum SmpDfuStatus {
  idle,
  connecting,
  querying,
  uploading,
  verifying,
  resetting,
  completed,
  paused,
  error,
}

/// Parsed MCUboot Header metadata
class McuBootHeader {
  final bool isValidMagic;
  final int loadAddr;
  final int hdrSize;
  final int imgSize;
  final int flags;
  final String version;

  const McuBootHeader({
    required this.isValidMagic,
    required this.loadAddr,
    required this.hdrSize,
    required this.imgSize,
    required this.flags,
    required this.version,
  });

  /// MCUboot Header Magic: 0x96F3B83D (Little-Endian: 0x3D, 0xB8, 0xF3, 0x96)
  static const int magicLE = 0x96F3B83D;

  factory McuBootHeader.fromBytes(Uint8List bytes) {
    if (bytes.length < 32) {
      return const McuBootHeader(
        isValidMagic: false,
        loadAddr: 0,
        hdrSize: 0,
        imgSize: 0,
        flags: 0,
        version: 'Unknown (<32B)',
      );
    }

    final byteData = ByteData.sublistView(bytes);
    final magic = byteData.getUint32(0, Endian.little);
    final isValid = magic == magicLE;

    final loadAddr = byteData.getUint32(4, Endian.little);
    final hdrSize = byteData.getUint16(8, Endian.little);
    final imgSize = byteData.getUint32(12, Endian.little);
    final flags = byteData.getUint32(16, Endian.little);

    final major = bytes[20];
    final minor = bytes[21];
    final revision = byteData.getUint16(22, Endian.little);
    final build = byteData.getUint32(24, Endian.little);

    final versionStr = '$major.$minor.$revision+$build';

    return McuBootHeader(
      isValidMagic: isValid,
      loadAddr: loadAddr,
      hdrSize: hdrSize,
      imgSize: imgSize,
      flags: flags,
      version: versionStr,
    );
  }
}

/// Individual firmware image representation for single or multi-core DFU
class DfuImage {
  final int imageIndex;
  final String fileName;
  final Uint8List bytes;
  final String sha256Hex;
  final McuBootHeader header;

  const DfuImage({
    required this.imageIndex,
    required this.fileName,
    required this.bytes,
    required this.sha256Hex,
    required this.header,
  });
}

/// Processed Firmware payload container (supports multi-image ZIP packages)
class ProcessedFirmware {
  final List<DfuImage> images;
  final String fileName;
  final String? warningMessage;

  const ProcessedFirmware({
    required this.images,
    required this.fileName,
    this.warningMessage,
  });

  Uint8List get bytes => images.isNotEmpty ? images.first.bytes : Uint8List(0);
  String get sha256Hex => images.isNotEmpty ? images.first.sha256Hex : '';
  McuBootHeader get header => images.isNotEmpty
      ? images.first.header
      : const McuBootHeader(
          isValidMagic: false,
          loadAddr: 0,
          hdrSize: 0,
          imgSize: 0,
          flags: 0,
          version: 'Unknown',
        );

  static ProcessedFirmware process({
    required String fileName,
    required Uint8List rawBytes,
  }) {
    List<DfuImage> extractedImages = [];
    String actualName = fileName;
    String? warning;

    if (fileName.toLowerCase().endsWith('.zip')) {
      try {
        final archive = ZipDecoder().decodeBytes(rawBytes);

        // 1. Try manifest.json parsing for multi-image packages
        ArchiveFile? manifestFile;
        for (final file in archive) {
          if (file.isFile && file.name.endsWith('manifest.json')) {
            manifestFile = file;
            break;
          }
        }

        if (manifestFile != null) {
          try {
            final contentStr = utf8.decode(manifestFile.content as List<int>);
            final map = jsonDecode(contentStr);
            Map<String, dynamic> manifestRoot = {};
            if (map is Map) {
              if (map['manifest'] is Map) {
                manifestRoot = Map<String, dynamic>.from(map['manifest'] as Map);
              } else {
                manifestRoot = Map<String, dynamic>.from(map);
              }
            }

            List filesList = [];
            if (manifestRoot['files'] is List) {
              filesList = manifestRoot['files'] as List;
            } else if (manifestRoot['application'] is Map) {
              filesList = [manifestRoot['application']];
            }

            for (final f in filesList) {
              if (f is Map) {
                final fileStr = (f['file'] ?? f['bin_file'] ?? f['file_name'])?.toString();
                int parseIndex(dynamic raw) {
                  if (raw is int) return raw;
                  if (raw is String) return int.tryParse(raw) ?? 0;
                  return 0;
                }

                final rawIdx = f['image_index'] ?? f['image'];
                final imageIndex = rawIdx != null ? parseIndex(rawIdx) : 0;

                if (fileStr != null) {
                  for (final archiveFile in archive) {
                    if (archiveFile.isFile &&
                        (archiveFile.name == fileStr || archiveFile.name.endsWith(fileStr))) {
                      final imgBytes = Uint8List.fromList(archiveFile.content as List<int>);
                      final hdr = McuBootHeader.fromBytes(imgBytes);
                      final sha = sha256
                          .convert(imgBytes)
                          .bytes
                          .map((b) => b.toRadixString(16).padLeft(2, '0'))
                          .join()
                          .toUpperCase();

                      extractedImages.add(DfuImage(
                        imageIndex: imageIndex,
                        fileName: archiveFile.name,
                        bytes: imgBytes,
                        sha256Hex: sha,
                        header: hdr,
                      ));
                      break;
                    }
                  }
                }
              }
            }
          } catch (e) {
            warning = 'Failed to parse manifest.json: $e';
          }
        }

        // 2. Fallback matching if manifest.json was absent or yielded no images
        if (extractedImages.isEmpty) {
          final binFiles = archive.where((f) => f.isFile && f.name.endsWith('.bin')).toList();
          // Filter out unsigned binaries if signed versions exist
          final signedFiles = binFiles.where((f) => f.name.toLowerCase().contains('signed')).toList();
          final targetFiles = signedFiles.isNotEmpty ? signedFiles : binFiles;

          for (final file in targetFiles) {
            final nameLower = file.name.toLowerCase();
            final isNet = nameLower.contains('ipc_radio') ||
                nameLower.contains('net_core') ||
                nameLower.contains('cpunet') ||
                nameLower.contains('hci_rpmsg');
            final imgIdx = isNet ? 1 : 0;

            final imgBytes = Uint8List.fromList(file.content as List<int>);
            final hdr = McuBootHeader.fromBytes(imgBytes);
            final sha = sha256
                .convert(imgBytes)
                .bytes
                .map((b) => b.toRadixString(16).padLeft(2, '0'))
                .join()
                .toUpperCase();

            // Avoid duplicate additions
            if (!extractedImages.any((img) => img.fileName == file.name)) {
              extractedImages.add(DfuImage(
                imageIndex: imgIdx,
                fileName: file.name,
                bytes: imgBytes,
                sha256Hex: sha,
                header: hdr,
              ));
            }
          }
        }
      } catch (e) {
        warning = 'Failed to extract ZIP archive: $e';
      }
    } else {
      // Single .bin file
      final hdr = McuBootHeader.fromBytes(rawBytes);
      final sha = sha256.convert(rawBytes).bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join()
          .toUpperCase();

      extractedImages.add(DfuImage(
        imageIndex: 0,
        fileName: fileName,
        bytes: rawBytes,
        sha256Hex: sha,
        header: hdr,
      ));
    }

    // Sort by imageIndex (Index 0 App core first, then Index 1 Net core)
    extractedImages.sort((a, b) => a.imageIndex.compareTo(b.imageIndex));

    if (extractedImages.isEmpty) {
      warning = 'No binary image found in file.';
      extractedImages.add(DfuImage(
        imageIndex: 0,
        fileName: fileName,
        bytes: rawBytes,
        sha256Hex: '',
        header: const McuBootHeader(
          isValidMagic: false,
          loadAddr: 0,
          hdrSize: 0,
          imgSize: 0,
          flags: 0,
          version: 'Unknown',
        ),
      ));
    }

    return ProcessedFirmware(
      images: extractedImages,
      fileName: actualName,
      warningMessage: warning,
    );
  }
}

/// Translated MCUMGR Error codes (Zephyr / MCUboot mgmt_err_t)
class McuMgrRc {
  static const int ok = 0; // MGMT_ERR_EOK
  static const int unknown = 1; // MGMT_ERR_EUNKNOWN
  static const int noMem = 2; // MGMT_ERR_ENOMEM
  static const int invalidValue = 3; // MGMT_ERR_EINVAL
  static const int timeout = 4; // MGMT_ERR_ETIMEOUT
  static const int noEntry = 5; // MGMT_ERR_ENOENT
  static const int inUse = 6; // MGMT_ERR_EBUSY
  static const int accessDenied = 7; // MGMT_ERR_EACCESSDENIED
  static const int corrupt = 8; // MGMT_ERR_ECORRUPT
  static const int notSupported = 9; // MGMT_ERR_ENOTSUP

  static String describe(int rc) {
    switch (rc) {
      case ok:
        return 'OK';
      case unknown:
        return 'UNKNOWN_ERROR';
      case noMem:
        return 'NO_MEMORY (Buffer overflow on target)';
      case invalidValue:
        return 'INVALID_VALUE (Unaligned write/offset, bad parameter, or invalid binary)';
      case timeout:
        return 'TIMEOUT';
      case noEntry:
        return 'NO_ENTRY';
      case inUse:
        return 'IN_USE (Image slot busy / locked)';
      case accessDenied:
        return 'ACCESS_DENIED';
      case corrupt:
        return 'CORRUPT (Image signature/hash mismatch)';
      case notSupported:
        return 'NOT_SUPPORTED';
      default:
        return 'ERROR_CODE_$rc';
    }
  }
}

/// Lightweight CBOR Encoder / Decoder for MCUMGR SMP messages.
class SimpleCbor {
  static Uint8List encodeMap(Map<String, dynamic> map, {int smpHeaderLen = 8}) {
    final builder = BytesBuilder();
    if (map.length <= 23) {
      builder.addByte(0xA0 + map.length);
    } else {
      builder.addByte(0xB8);
      builder.addByte(map.length);
    }

    for (final entry in map.entries) {
      final keyBytes = utf8.encode(entry.key);
      _addHeader(builder, 3, keyBytes.length);
      builder.add(keyBytes);

      final val = entry.value;

      if (val is int) {
        _addHeader(builder, 0, val);
      } else if (val is Uint8List) {
        _addHeader(builder, 2, val.length);
        builder.add(val);
      } else if (val is List<int>) {
        final bytes = Uint8List.fromList(val);
        _addHeader(builder, 2, bytes.length);
        builder.add(bytes);
      } else if (val is bool) {
        builder.addByte(val ? 0xF5 : 0xF4);
      } else if (val is String) {
        final strBytes = utf8.encode(val);
        _addHeader(builder, 3, strBytes.length);
        builder.add(strBytes);
      } else {
        throw ArgumentError('Unsupported CBOR type: ${val.runtimeType}');
      }
    }
    return builder.toBytes();
  }

  static void _addHeader(BytesBuilder builder, int majorType, int val) {
    final mt = (majorType & 0x07) << 5;
    if (val < 24) {
      builder.addByte(mt | val);
    } else if (val <= 0xFF) {
      builder.addByte(mt | 24);
      builder.addByte(val);
    } else if (val <= 0xFFFF) {
      builder.addByte(mt | 25);
      builder.addByte((val >> 8) & 0xFF);
      builder.addByte(val & 0xFF);
    } else if (val <= 0xFFFFFFFF) {
      builder.addByte(mt | 26);
      builder.addByte((val >> 24) & 0xFF);
      builder.addByte((val >> 16) & 0xFF);
      builder.addByte((val >> 8) & 0xFF);
      builder.addByte(val & 0xFF);
    } else {
      builder.addByte(mt | 27);
      for (int i = 56; i >= 0; i -= 8) {
        builder.addByte((val >> i) & 0xFF);
      }
    }
  }

  static Map<String, dynamic> decodeMap(Uint8List bytes, [int offset = 0]) {
    final item = _decodeItem(bytes, offset);
    if (item.value is Map<String, dynamic>) {
      return item.value as Map<String, dynamic>;
    }
    if (item.value is Map) {
      return Map<String, dynamic>.from(item.value as Map);
    }
    return {};
  }

  static _CborItem _decodeItem(Uint8List bytes, int index) {
    if (index >= bytes.length) return _CborItem(null, index);
    final header = bytes[index++];
    final mt = (header >> 5) & 0x07;
    int info = header & 0x1F;
    int val = 0;
    if (info < 24) {
      val = info;
    } else if (info == 24) {
      val = bytes[index++];
    } else if (info == 25) {
      val = (bytes[index] << 8) | bytes[index + 1];
      index += 2;
    } else if (info == 26) {
      val =
          (bytes[index] << 24) |
          (bytes[index + 1] << 16) |
          (bytes[index + 2] << 8) |
          bytes[index + 3];
      index += 4;
    }

    switch (mt) {
      case 0:
        return _CborItem(val, index);
      case 1:
        return _CborItem(-1 - val, index);
      case 2: // Byte string
        if (info == 31) {
          final builder = BytesBuilder();
          int bIndex = index;
          while (bIndex < bytes.length) {
            if (bytes[bIndex] == 0xFF) {
              bIndex++;
              break;
            }
            final chunk = _decodeItem(bytes, bIndex);
            bIndex = chunk.nextIndex;
            if (chunk.value is Uint8List) {
              builder.add(chunk.value as Uint8List);
            } else if (chunk.value is List<int>) {
              builder.add(Uint8List.fromList(chunk.value as List<int>));
            }
          }
          return _CborItem(builder.toBytes(), bIndex);
        }
        final end = (index + val).clamp(0, bytes.length);
        final data = bytes.sublist(index, end);
        return _CborItem(data, end);
      case 3: // Text string
        if (info == 31) {
          final sb = StringBuffer();
          int sIndex = index;
          while (sIndex < bytes.length) {
            if (bytes[sIndex] == 0xFF) {
              sIndex++;
              break;
            }
            final chunk = _decodeItem(bytes, sIndex);
            sIndex = chunk.nextIndex;
            if (chunk.value != null) sb.write(chunk.value);
          }
          return _CborItem(sb.toString(), sIndex);
        }
        final end = (index + val).clamp(0, bytes.length);
        final str = utf8.decode(
          bytes.sublist(index, end),
          allowMalformed: true,
        );
        return _CborItem(str, end);
      case 4: // Array
        final list = <dynamic>[];
        int elemIndex = index;
        if (info == 31) {
          while (elemIndex < bytes.length) {
            if (bytes[elemIndex] == 0xFF) {
              elemIndex++;
              break;
            }
            final itemRes = _decodeItem(bytes, elemIndex);
            elemIndex = itemRes.nextIndex;
            list.add(itemRes.value);
          }
        } else {
          for (int i = 0; i < val && elemIndex < bytes.length; i++) {
            if (bytes[elemIndex] == 0xFF) break;
            final itemRes = _decodeItem(bytes, elemIndex);
            elemIndex = itemRes.nextIndex;
            list.add(itemRes.value);
          }
        }
        return _CborItem(list, elemIndex);
      case 5: // Map
        final result = <String, dynamic>{};
        int mIndex = index;
        if (info == 31) {
          while (mIndex < bytes.length) {
            if (bytes[mIndex] == 0xFF) {
              mIndex++;
              break;
            }
            final keyRes = _decodeItem(bytes, mIndex);
            mIndex = keyRes.nextIndex;
            if (keyRes.value == null || bytes[mIndex - 1] == 0xFF) break;
            final key = keyRes.value.toString();

            if (mIndex >= bytes.length || bytes[mIndex] == 0xFF) {
              if (mIndex < bytes.length && bytes[mIndex] == 0xFF) mIndex++;
              break;
            }
            final valRes = _decodeItem(bytes, mIndex);
            mIndex = valRes.nextIndex;
            result[key] = valRes.value;
          }
        } else {
          for (int i = 0; i < val && mIndex < bytes.length; i++) {
            if (bytes[mIndex] == 0xFF) break;
            final keyRes = _decodeItem(bytes, mIndex);
            mIndex = keyRes.nextIndex;
            if (keyRes.value == null) break;
            final key = keyRes.value.toString();

            final valRes = _decodeItem(bytes, mIndex);
            mIndex = valRes.nextIndex;
            result[key] = valRes.value;
          }
        }
        return _CborItem(result, mIndex);
      case 7:
        if (info == 20) return _CborItem(false, index);
        if (info == 21) return _CborItem(true, index);
        return _CborItem(val, index);
      default:
        return _CborItem(null, index);
    }
  }
}

class _CborItem {
  final dynamic value;
  final int nextIndex;
  _CborItem(this.value, this.nextIndex);
}

/// Helper class for SMP Packet building and parsing
class SmpPacket {
  static const int opRead = 0;
  static const int opReadResp = 1;
  static const int opWrite = 2;
  static const int opWriteResp = 3;

  static const int groupOs = 0;
  static const int groupImage = 1;

  static const int imgCmdState = 0;
  static const int imgCmdUpload = 1;
  static const int imgCmdErase = 5;

  static const int osCmdReset = 5;

  static Uint8List build({
    required int op,
    required int group,
    required int seq,
    required int id,
    required Map<String, dynamic> payloadMap,
  }) {
    final payloadBytes = SimpleCbor.encodeMap(payloadMap);
    final header = Uint8List(8);
    header[0] = op & 0xFF;
    header[1] = 0; // flags
    header[2] = (payloadBytes.length >> 8) & 0xFF;
    header[3] = payloadBytes.length & 0xFF;
    header[4] = (group >> 8) & 0xFF;
    header[5] = group & 0xFF;
    header[6] = seq & 0xFF;
    header[7] = id & 0xFF;

    final result = Uint8List(8 + payloadBytes.length);
    result.setRange(0, 8, header);
    result.setRange(8, result.length, payloadBytes);
    return result;
  }

  static Uint8List calculateSha256(Uint8List data) {
    final digest = sha256.convert(data);
    return Uint8List.fromList(digest.bytes);
  }
}
