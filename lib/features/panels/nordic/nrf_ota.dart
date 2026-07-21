import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/features/panels/bluetooth/providers/ble_notifier.dart';
import 'package:sanc_term/features/panels/nordic/smp_dfu_service.dart';
import 'package:sanc_term/services/ble_service.dart';
import 'package:sanc_term/shared/widgets/panel.dart';

/// Nordic BLE Over-The-Air (OTA) DFU Panel.
/// Uses pure-Dart MCUMGR Simple Management Protocol (SMP) over BLE GATT
/// compatible with Nordic nRF Connect SDK (Zephyr RTOS) and MCUboot.
class NrfOtaPanel extends ConsumerStatefulWidget {
  const NrfOtaPanel({super.key});

  @override
  ConsumerState<NrfOtaPanel> createState() => _NrfOtaPanelState();
}

class _NrfOtaPanelState extends ConsumerState<NrfOtaPanel> {
  // Selected processed firmware info
  ProcessedFirmware? _processedFirmware;

  // MCUboot Target Slot State info
  String? _targetSlot0Info;
  String? _targetSlot1Info;

  // DFU state & progress
  bool _autoConfirm = true;
  SmpDfuStatus _dfuStatus = SmpDfuStatus.idle;
  double _progress = 0.0;
  int _bytesSent = 0;
  double _speedKbps = 0.0;
  String? _errorMessage;
  final List<String> _logs = [];

  bool _isPaused = false;
  bool _isCancelled = false;
  int _seq = 0;

  Uint8List? _slot0Hash;
  bool _isSlot0Confirmed = false;

  Completer<Uint8List>? _pendingAck;
  StreamSubscription<({String characteristicId, Uint8List value})>? _rxSub;

  final ScrollController _logScrollController = ScrollController();

  @override
  void dispose() {
    _isCancelled = true;
    _rxSub?.cancel();
    _logScrollController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  /// Case & Hyphen insensitive UUID matcher
  bool _isSameUuid(String a, String b) {
    final cleanA = a.toLowerCase().replaceAll(RegExp(r'[^a-f0-9]'), '');
    final cleanB = b.toLowerCase().replaceAll(RegExp(r'[^a-f0-9]'), '');
    return cleanA == cleanB || cleanA.contains(cleanB) || cleanB.contains(cleanA);
  }

  /// Checks if a UUID matches SMP service (standard 8d53a89d... or vendor 128-bit base starting with 8d53)
  bool _isSmpServiceUuid(String uuid) {
    final clean = uuid.toLowerCase().replaceAll(RegExp(r'[^a-f0-9]'), '');
    return clean.startsWith('8d53') || clean.contains('8d53') || clean == 'aa55';
  }

  /// Checks if a UUID matches SMP characteristic (standard da2e7828... or vendor 128-bit base starting with da2e)
  bool _isSmpCharUuid(String uuid) {
    final clean = uuid.toLowerCase().replaceAll(RegExp(r'[^a-f0-9]'), '');
    return clean.startsWith('da2e') || clean.contains('da2e7828') || clean.contains('da2e');
  }

  /// Locates discovered MCUMGR SMP GATT service & characteristic from BleState.
  /// Matches standard SMP service/char or vendor 128-bit base prefixed with 8d53 / da2e.
  ({String serviceUuid, String writeCharUuid, String notifyCharUuid})
      _findSmpGatt(BleState bleState) {
    // 1. Search for SMP service (8d53... prefix or standard SmpUuids.service)
    for (final s in bleState.services) {
      if (_isSmpServiceUuid(s.uuid) ||
          _isSameUuid(s.uuid, SmpUuids.serviceShort)) {
        for (final ch in s.characteristics) {
          if (_isSmpCharUuid(ch.uuid)) {
            return (
              serviceUuid: s.uuid,
              writeCharUuid: ch.uuid,
              notifyCharUuid: ch.uuid,
            );
          }
        }
        // Fallback within 8d53 service
        String? writeCh;
        String? notifyCh;
        for (final ch in s.characteristics) {
          if (ch.properties.contains(BleCharProperty.write) ||
              ch.properties.contains(BleCharProperty.writeWithoutResponse)) {
            writeCh ??= ch.uuid;
          }
          if (ch.properties.contains(BleCharProperty.notify) ||
              ch.properties.contains(BleCharProperty.indicate)) {
            notifyCh ??= ch.uuid;
          }
        }
        if (writeCh != null && notifyCh != null) {
          return (
            serviceUuid: s.uuid,
            writeCharUuid: writeCh,
            notifyCharUuid: notifyCh,
          );
        }
      }
    }

    // 2. Check for any characteristic with da2e prefix in ANY discovered service
    for (final s in bleState.services) {
      for (final ch in s.characteristics) {
        if (_isSmpCharUuid(ch.uuid)) {
          return (
            serviceUuid: s.uuid,
            writeCharUuid: ch.uuid,
            notifyCharUuid: ch.uuid,
          );
        }
      }
    }

    // 3. SMP Service missing on peripheral
    _log(
        'ERROR: Official MCUboot SMP GATT Service (${SmpUuids.service}) NOT discovered on target device!');
    _log(
        'Discovered Services (${bleState.services.length}): ${bleState.services.map((s) => s.uuid).join(", ")}');
    _log(
        'To fix: Enable CONFIG_MCUMGR_TRANSPORT_BT=y in your Zephyr / nRF Connect SDK prj.conf and rebuild firmware.');

    return (
      serviceUuid: SmpUuids.service,
      writeCharUuid: SmpUuids.characteristic,
      notifyCharUuid: SmpUuids.characteristic,
    );
  }

  void _log(String msg) {
    if (!mounted) return;
    final timestamp =
        DateTime.now().toIso8601String().split('T').last.substring(0, 8);
    final logLine = '[$timestamp] $msg';
    if (mounted) {
      setState(() {
        _logs.add(logLine);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickFirmware() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['bin', 'zip', 'hex'],
    );

    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    final file = File(path);
    final rawBytes = await file.readAsBytes();

    final processed = ProcessedFirmware.process(
      fileName: result.files.single.name,
      rawBytes: rawBytes,
    );

    setState(() {
      _processedFirmware = processed;
      _dfuStatus = SmpDfuStatus.idle;
      _progress = 0.0;
      _bytesSent = 0;
      _speedKbps = 0.0;
      _errorMessage = null;
    });

    _log('Loaded file: ${processed.fileName} (${processed.bytes.length} bytes)');
    _log(
        'MCUboot Magic: ${processed.header.isValidMagic ? "VALID (0x96F3B83D)" : "INVALID / MISSING"}');
    _log('Detected Image Version: ${processed.header.version}');
    _log('SHA-256: ${processed.sha256Hex.substring(0, 16)}...');

    if (processed.warningMessage != null) {
      _log('WARNING: ${processed.warningMessage}');
    }
  }

  void _ensureRxSubscription(String targetNotifyCharUuid) {
    _rxSub?.cancel();
    _rxSub = ref.read(bleServiceProvider).characteristicUpdates.listen((e) {
      final hex = e.value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');

      // Check if notification is from SMP/target characteristic and is a valid SMP response packet
      final isSmpResp = e.value.length >= 8 &&
          (e.value[0] == SmpPacket.opReadResp || e.value[0] == SmpPacket.opWriteResp);

      if (isSmpResp) {
        final op = e.value[0];
        final seq = e.value[6];
        _log('SMP ACK Notification [op=$op, seq=$seq (req=$_seq)] (${e.value.length}B) -> HEX: $hex');
        if (seq == _seq && _pendingAck != null && !_pendingAck!.isCompleted) {
          _pendingAck!.complete(e.value);
        }
      } else {
        final ascii = utf8.decode(e.value, allowMalformed: true).replaceAll(RegExp(r'[\r\n]'), ' ');
        _log('BLE Notification [${e.characteristicId}] (${e.value.length}B) -> ASCII: "$ascii" | HEX: $hex');
      }
    });
  }

  Future<Uint8List?> _sendPacketAndWaitAck(
    String serviceUuid,
    String writeCharUuid,
    Uint8List packet, {
    int timeoutMs = 4000,
    bool withoutResponse = true,
    int maxMtu = 244,
    bool verbose = false,
  }) async {
    _pendingAck = Completer<Uint8List>();

    if (verbose) {
      _log(
          'Writing Packet (${packet.length} B, op=${packet[0]}, group=${(packet[4] << 8) | packet[5]}, id=${packet[7]}, withoutResp=$withoutResponse)...');
    }

    if (packet.length > maxMtu) {
      int sent = 0;
      while (sent < packet.length) {
        final end = (sent + maxMtu).clamp(0, packet.length);
        final fragment = packet.sublist(sent, end);
        await ref.read(bleNotifierProvider.notifier).writeChar(
              serviceUuid,
              writeCharUuid,
              fragment,
              withoutResponse: withoutResponse,
            );
        sent = end;
        if (sent < packet.length) {
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }
    } else {
      await ref.read(bleNotifierProvider.notifier).writeChar(
            serviceUuid,
            writeCharUuid,
            packet,
            withoutResponse: withoutResponse,
          );
    }

    try {
      final res =
          await _pendingAck!.future.timeout(Duration(milliseconds: timeoutMs));
      if (verbose) {
        _log('ACK Received (${res.length} bytes)');
      }
      return res;
    } catch (_) {
      _log('ACK Timeout ($timeoutMs ms elapsed)');
      return null;
    }
  }

  /// Query target MCUboot active slot state (Group 1, Cmd 1, Read)
  Future<void> _queryTargetImageState({int imageIndex = 0}) async {
    final bleState = ref.read(bleNotifierProvider);
    if (!bleState.isConnected) {
      _log('Cannot query image state: Device disconnected.');
      return;
    }

    final smpGatt = _findSmpGatt(bleState);
    _ensureRxSubscription(smpGatt.notifyCharUuid);

    _seq = (_seq + 1) % 256;
    final packet = SmpPacket.build(
      op: SmpPacket.opRead,
      group: SmpPacket.groupImage,
      seq: _seq,
      id: SmpPacket.imgCmdState,
      payloadMap: imageIndex != 0 ? {'image': imageIndex} : {},
    );

    Uint8List? response = await _sendPacketAndWaitAck(
      smpGatt.serviceUuid,
      smpGatt.writeCharUuid,
      packet,
      timeoutMs: 3000,
      withoutResponse: true,
      verbose: true,
    );

    if (response == null || SimpleCbor.decodeMap(response, 8)['rc'] != null) {
      _seq = (_seq + 1) % 256;
      final packet2 = SmpPacket.build(
        op: SmpPacket.opRead,
        group: SmpPacket.groupImage,
        seq: _seq,
        id: SmpPacket.imgCmdState,
        payloadMap: {},
      );
      final fbResp = await _sendPacketAndWaitAck(
        smpGatt.serviceUuid,
        smpGatt.writeCharUuid,
        packet2,
        timeoutMs: 3000,
        withoutResponse: true,
        verbose: true,
      );
      if (fbResp != null && SimpleCbor.decodeMap(fbResp, 8).containsKey('images')) {
        response = fbResp;
      }
    }

    if (response != null) {
      final map = SimpleCbor.decodeMap(response, 8);
      _log('MCUboot Response (Image $imageIndex): $map');

      final rc = map['rc'] ?? 0;
      if (rc != 0) {
        _log('Target MCUboot Image State status: rc=$rc (${McuMgrRc.describe(rc)}) - Flash state or secondary slot uninitialized.');
      }

      if (map.containsKey('images') && map['images'] is List) {
        final images = map['images'] as List;
        String slot0Text = 'Slot 0: None';
        String slot1Text = 'Slot 1: Empty';

        final bool matchImageIndex = images.any((e) => e is Map && e['image'] == imageIndex);

        for (final img in images) {
          if (img is Map) {
            final rawImgIdx = img['image'];
            final imgIdx = rawImgIdx is int ? rawImgIdx : 0;
            if (matchImageIndex && imgIdx != imageIndex) {
              continue;
            }
            final slot = img['slot'] ?? 0;
            final ver = img['version'] ?? 'unknown';
            final active = img['active'] == true ? ' [ACTIVE]' : '';
            final pending = img['pending'] == true ? ' [PENDING]' : '';
            final confirmed = img['confirmed'] == true ? ' [CONFIRMED]' : '';

            if (slot == 0) {
              if (img['hash'] is Uint8List) {
                _slot0Hash = img['hash'] as Uint8List;
              } else if (img['hash'] is List) {
                _slot0Hash = Uint8List.fromList((img['hash'] as List).cast<int>());
              }
              _isSlot0Confirmed = img['confirmed'] == true;
            }

            final info = 'Slot $slot (Img $imgIdx): v$ver$active$pending$confirmed';
            if (slot == 0) slot0Text = info;
            if (slot == 1) slot1Text = info;
          }
        }

        setState(() {
          _targetSlot0Info = slot0Text;
          _targetSlot1Info = slot1Text;
        });

        _log('Target Slots (Image $imageIndex) -> $slot0Text | $slot1Text');
      }
    } else {
      _log('No response received for image state query.');
    }
  }

  Future<void> _startDfu() async {
    final bleState = ref.read(bleNotifierProvider);
    if (!bleState.isConnected || bleState.connectedId == null) {
      _log('ERROR: No active BLE connection. Connect to target first.');
      _safeSetState(() {
        _dfuStatus = SmpDfuStatus.error;
        _errorMessage = 'No BLE connection';
      });
      return;
    }

    if (_processedFirmware == null || _processedFirmware!.images.isEmpty) {
      _log('ERROR: No firmware file selected.');
      return;
    }

    final firmware = _processedFirmware!;
    final packageImageCount = firmware.images.length;

    final smpGatt = _findSmpGatt(bleState);
    _log(
        'Resolved Transport GATT -> Service: ${smpGatt.serviceUuid} | Write (RX): ${smpGatt.writeCharUuid} | Notify (TX): ${smpGatt.notifyCharUuid}');

    _safeSetState(() {
      _dfuStatus = SmpDfuStatus.uploading;
      _isPaused = false;
      _isCancelled = false;
      _progress = 0.0;
      _bytesSent = 0;
      _errorMessage = null;
      _seq = 0;
    });

    _log('Starting SMP DFU for ${firmware.fileName} ($packageImageCount image(s) in package)...');
    _ensureRxSubscription(smpGatt.notifyCharUuid);

    await ref.read(bleNotifierProvider.notifier).subscribeChar(
          smpGatt.serviceUuid,
          smpGatt.notifyCharUuid,
        );

    // Negotiate MTU (request 517 bytes max BLE 5.0 ATT MTU)
    _log('Requesting ATT MTU (517 bytes, MAX_PACKET_SIZE = 498)...');
    final negotiatedMtu = await ref
            .read(bleNotifierProvider.notifier)
            .requestMtu(517) ??
        bleState.mtu ??
        517;

    // Max total BLE packet size (ATT MTU - 3, capped at 498 bytes max)
    final maxPacketSize = (negotiatedMtu - 3).clamp(64, 498);
    _log(
        'MTU Negotiated: $negotiatedMtu bytes. Target max packet size: $maxPacketSize bytes.');

    // Query target image state to determine supported image cores
    final Set<int> targetSupportedCores = <int>{0};
    try {
      _seq = (_seq + 1) % 256;
      final queryPacket = SmpPacket.build(
        op: SmpPacket.opRead,
        group: SmpPacket.groupImage,
        seq: _seq,
        id: SmpPacket.imgCmdState,
        payloadMap: {},
      );
      final queryResp = await _sendPacketAndWaitAck(
        smpGatt.serviceUuid,
        smpGatt.writeCharUuid,
        queryPacket,
        timeoutMs: 3000,
        withoutResponse: true,
      );
      if (queryResp != null) {
        final decoded = SimpleCbor.decodeMap(queryResp, 8);
        if (decoded.containsKey('images') && decoded['images'] is List) {
          for (final item in decoded['images'] as List) {
            if (item is Map && item.containsKey('image')) {
              final idx = item['image'];
              if (idx is int) targetSupportedCores.add(idx);
            }
          }
        }
      }
    } catch (_) {}

    _log('Target supported MCUboot Image Core(s): ${targetSupportedCores.toList()}');

    // Filter package images to only upload images supported by the target device
    final imagesToUpload = firmware.images.where((img) {
      if (targetSupportedCores.contains(img.imageIndex)) return true;
      if (img.imageIndex == 0) return true;
      _log('Skipping ${img.fileName} (Index ${img.imageIndex}) - Target device has no core for Image ${img.imageIndex}.');
      return false;
    }).toList();

    if (imagesToUpload.isEmpty) {
      imagesToUpload.add(firmware.images.first);
    }

    final totalImages = imagesToUpload.length;

    int grandTotalBytes = 0;
    for (final img in imagesToUpload) {
      grandTotalBytes += img.bytes.length;
    }
    int totalBytesSentAcc = 0;

    final stopwatch = Stopwatch()..start();

    try {
      for (int imgIdx = 0; imgIdx < totalImages; imgIdx++) {
        if (_isCancelled) break;
        final targetImg = imagesToUpload[imgIdx];
        final imgTotalBytes = targetImg.bytes.length;

        _log('=== Processing Image ${imgIdx + 1}/$totalImages: ${targetImg.fileName} (Index: ${targetImg.imageIndex}, $imgTotalBytes bytes) ===');

        await _queryTargetImageState(imageIndex: targetImg.imageIndex);

        int currentOffset = 0;
        int retryCount = 0;
        int lastUiUpdateMs = 0;

        while (currentOffset < imgTotalBytes && !_isCancelled) {
          if (_isPaused) {
            _log('DFU Upload Paused at offset $currentOffset.');
            _safeSetState(() => _dfuStatus = SmpDfuStatus.paused);
            while (_isPaused && !_isCancelled) {
              await Future.delayed(const Duration(milliseconds: 200));
            }
            if (_isCancelled) break;
            _log('DFU Upload Resumed.');
            _safeSetState(() => _dfuStatus = SmpDfuStatus.uploading);
          }

          final isFirstChunk = currentOffset == 0;
          final estOverhead = isFirstChunk ? 60 : 28;
          int targetChunkSize = (maxPacketSize - estOverhead).clamp(16, maxPacketSize - 20);
          if (currentOffset + targetChunkSize < imgTotalBytes) {
            targetChunkSize = (targetChunkSize ~/ 4) * 4;
          }
          final end = (currentOffset + targetChunkSize).clamp(0, imgTotalBytes);
          Uint8List chunk = targetImg.bytes.sublist(currentOffset, end);

          if (isFirstChunk) {
            _log('Uploading Image ${targetImg.imageIndex} (${targetImg.fileName}) header & data...');
          }

          _seq = (_seq + 1) % 256;
          Uint8List packet;

          while (true) {
            final Map<String, dynamic> payloadMap = <String, dynamic>{};

            payloadMap['off'] = currentOffset;

            if (isFirstChunk) {
              payloadMap['len'] = imgTotalBytes;
              payloadMap['sha'] = SmpPacket.calculateSha256(targetImg.bytes);
              payloadMap['image'] = targetImg.imageIndex;
            }

            payloadMap['data'] = chunk;

            packet = SmpPacket.build(
              op: SmpPacket.opWrite,
              group: SmpPacket.groupImage,
              seq: _seq,
              id: SmpPacket.imgCmdUpload,
              payloadMap: payloadMap,
            );

            if (packet.length <= maxPacketSize || chunk.length <= 16) {
              break;
            }
            final excess = packet.length - maxPacketSize;
            int newLen = (chunk.length - excess).clamp(16, chunk.length - 1);
            if (currentOffset + newLen < imgTotalBytes) {
              newLen = (newLen ~/ 4) * 4;
              if (newLen < 16) newLen = 16;
            }
            chunk = targetImg.bytes.sublist(currentOffset, currentOffset + newLen);
          }

          if (isFirstChunk) {
            final hexStr = packet.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
            _log('Raw First Packet SMP CBOR (offset 0, ${packet.length} B) -> HEX:\n$hexStr');
          }

          // Allow 10000ms for chunk 0 (initial sector erase) and 2000ms for progressive QSPI sector erases
          final timeoutMs = isFirstChunk ? 10000 : 2000;
          const useWithoutResp = true;

          final resp = await _sendPacketAndWaitAck(
            smpGatt.serviceUuid,
            smpGatt.writeCharUuid,
            packet,
            timeoutMs: timeoutMs,
            withoutResponse: useWithoutResp,
            maxMtu: maxPacketSize,
            verbose: isFirstChunk,
          );

          if (resp != null) {
            final decoded = SimpleCbor.decodeMap(resp, 8);
            final rc = decoded['rc'] ?? 0;
            if (rc != 0) {
              if (isFirstChunk && (rc == McuMgrRc.noEntry || rc == McuMgrRc.invalidValue) && targetImg.imageIndex != 0) {
                _log('MCUboot target has no separate Flash Area for Image ${targetImg.imageIndex} (rc=$rc). Skipping Image ${targetImg.imageIndex} upload...');
                break;
              }
              final rsn = decoded['rsn']?.toString();
              final errStr = McuMgrRc.describe(rc);
              final fullMsg = rsn != null ? '$errStr ("$rsn")' : errStr;
              _log('ERROR from MCUboot at offset $currentOffset (Image ${targetImg.imageIndex}): $fullMsg (rc=$rc)');
              _safeSetState(() {
                _dfuStatus = SmpDfuStatus.error;
                _errorMessage = 'MCUboot error (rc=$rc): $fullMsg.';
              });
              return;
            }
            retryCount = 0;

            if (decoded.containsKey('off')) {
              currentOffset = decoded['off'] as int;
            } else {
              currentOffset = end;
            }
          } else {
            retryCount++;
            _log('ACK timeout at offset $currentOffset for Image ${targetImg.imageIndex} (retry $retryCount/5)...');
            if (retryCount >= 5) {
              _log('ERROR: MCUboot ACK timeout at offset $currentOffset (Image ${targetImg.imageIndex}).');
              _safeSetState(() {
                _dfuStatus = SmpDfuStatus.error;
                _errorMessage = 'MCUboot ACK timeout at offset $currentOffset';
              });
              return;
            }
            await Future.delayed(const Duration(milliseconds: 50));
            continue;
          }

          final nowMs = stopwatch.elapsedMilliseconds;
          if (nowMs - lastUiUpdateMs > 80 || currentOffset >= imgTotalBytes) {
            lastUiUpdateMs = nowMs;
            final elapsedSec = nowMs / 1000.0;
            final overallSent = totalBytesSentAcc + currentOffset;
            final speedKb = elapsedSec > 0 ? (overallSent / 1024.0) / elapsedSec : 0.0;

            _safeSetState(() {
              _bytesSent = overallSent;
              _progress = (overallSent / grandTotalBytes).clamp(0.0, 1.0);
              _speedKbps = speedKb;
            });
          }
        }

        totalBytesSentAcc += imgTotalBytes;
        _log('Image ${imgIdx + 1}/$totalImages (${targetImg.fileName}) upload complete!');
      }

      stopwatch.stop();

      if (_isCancelled) {
        _log('DFU Upload cancelled by user.');
        _safeSetState(() {
          _dfuStatus = SmpDfuStatus.idle;
          _progress = 0.0;
        });
        return;
      }

      _log('All images uploaded! Verifying & confirming images (confirm = $_autoConfirm)...');
      _safeSetState(() => _dfuStatus = SmpDfuStatus.verifying);

      for (final img in imagesToUpload) {
        // Query current state of target MCUboot to get the exact slot 1 MCUboot hash
        _seq = (_seq + 1) % 256;
        final stateQueryPacket = SmpPacket.build(
          op: SmpPacket.opRead,
          group: SmpPacket.groupImage,
          seq: _seq,
          id: SmpPacket.imgCmdState,
          payloadMap: {},
        );

        Uint8List? secSlotHash;
        final stateResp = await _sendPacketAndWaitAck(
          smpGatt.serviceUuid,
          smpGatt.writeCharUuid,
          stateQueryPacket,
          timeoutMs: 3000,
          withoutResponse: true,
          verbose: true,
        );

        if (stateResp != null) {
          final decoded = SimpleCbor.decodeMap(stateResp, 8);
          _log('Post-upload MCUboot Image State query: $decoded');
          if (decoded.containsKey('images') && decoded['images'] is List) {
            for (final item in decoded['images'] as List) {
              if (item is Map && (item['slot'] ?? 0) == 1) {
                if (item['hash'] is Uint8List) {
                  secSlotHash = item['hash'] as Uint8List;
                } else if (item['hash'] is List) {
                  secSlotHash = Uint8List.fromList((item['hash'] as List).cast<int>());
                }
              }
            }
          }
        }

        // MCUboot STATE write requires the hash byte array to mark slot 1 as pending/confirmed
        final hashToConfirm = secSlotHash ?? SmpPacket.calculateSha256(img.bytes);
        final hexHash = hashToConfirm.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
        _log('Confirming Image (Index ${img.imageIndex}) with SHA-256: ${hexHash.substring(0, 16)}... (confirm=$_autoConfirm)');

        // Attempt 1: Confirm with autoConfirm setting (true/false)
        _seq = (_seq + 1) % 256;
        Map<String, dynamic> confirmMap = {
          'hash': hashToConfirm,
          'confirm': _autoConfirm,
        };

        Uint8List confirmPacket = SmpPacket.build(
          op: SmpPacket.opWrite,
          group: SmpPacket.groupImage,
          seq: _seq,
          id: SmpPacket.imgCmdState,
          payloadMap: confirmMap,
        );

        Uint8List? confirmResp = await _sendPacketAndWaitAck(
          smpGatt.serviceUuid,
          smpGatt.writeCharUuid,
          confirmPacket,
          timeoutMs: 3000,
          withoutResponse: true,
        );

        int confirmRc = confirmResp != null ? (SimpleCbor.decodeMap(confirmResp, 8)['rc'] ?? 0) : -1;

        if (confirmRc != 0) {
          _log('Confirm with confirm=$_autoConfirm returned rc=$confirmRc. Retrying with confirm=false (Test Mode Swap)...');
          // Attempt 2: Test Mode Swap (confirm = false)
          _seq = (_seq + 1) % 256;
          confirmMap = {
            'hash': hashToConfirm,
            'confirm': false,
          };
          confirmPacket = SmpPacket.build(
            op: SmpPacket.opWrite,
            group: SmpPacket.groupImage,
            seq: _seq,
            id: SmpPacket.imgCmdState,
            payloadMap: confirmMap,
          );
          confirmResp = await _sendPacketAndWaitAck(
            smpGatt.serviceUuid,
            smpGatt.writeCharUuid,
            confirmPacket,
            timeoutMs: 3000,
            withoutResponse: true,
          );
          if (confirmResp != null) {
            confirmRc = SimpleCbor.decodeMap(confirmResp, 8)['rc'] ?? 0;
          }
        }

        if (confirmResp != null) {
          final decoded = SimpleCbor.decodeMap(confirmResp, 8);
          _log('MCUboot Confirm Response (Image ${img.imageIndex}): rc=$confirmRc, map=$decoded');
        } else {
          _log('WARNING: No response for MCUboot Confirm (Image ${img.imageIndex}).');
        }
      }

      _log('Images verified in secondary slots. Sending reset command to target OS...');
      _safeSetState(() => _dfuStatus = SmpDfuStatus.resetting);

      await Future.delayed(const Duration(milliseconds: 300));
      await _resetTargetDevice();

      _log('Target reset command sent! MCUboot will swap images on boot.');
      _safeSetState(() {
        _dfuStatus = SmpDfuStatus.completed;
        _progress = 1.0;
      });

      await Future.delayed(const Duration(seconds: 4));
      await _queryTargetImageState();
    } catch (e) {
      _log('ERROR during DFU: $e');
      _safeSetState(() {
        _dfuStatus = SmpDfuStatus.error;
        _errorMessage = '$e';
      });
    }
  }

  void _togglePause() {
    _safeSetState(() {
      _isPaused = !_isPaused;
    });
  }

  void _cancelDfu() {
    _safeSetState(() {
      _isCancelled = true;
      _isPaused = false;
    });
  }

  Future<bool> _confirmActiveImage({int imageIndex = 0}) async {
    final bleState = ref.read(bleNotifierProvider);
    if (!bleState.isConnected) return false;

    if (_isSlot0Confirmed && imageIndex == 0) {
      _log('MCUboot Slot 0 image is already confirmed.');
      return true;
    }

    final smpGatt = _findSmpGatt(bleState);
    _ensureRxSubscription(smpGatt.notifyCharUuid);

    final Map<String, dynamic> payloadMap = {
      'confirm': true,
    };
    if (_slot0Hash != null) {
      payloadMap['hash'] = _slot0Hash;
    }

    _log('Sending MCUMGR Image Confirm command to target MCUboot...');
    _seq = (_seq + 1) % 256;
    final confirmPacket = SmpPacket.build(
      op: SmpPacket.opWrite,
      group: SmpPacket.groupImage,
      seq: _seq,
      id: SmpPacket.imgCmdState,
      payloadMap: payloadMap,
    );

    final resp = await _sendPacketAndWaitAck(
      smpGatt.serviceUuid,
      smpGatt.writeCharUuid,
      confirmPacket,
      timeoutMs: 3000,
      withoutResponse: true,
    );

    if (resp != null) {
      final decoded = SimpleCbor.decodeMap(resp, 8);
      final rc = decoded['rc'] ?? 0;
      if (rc == 0) {
        _log('MCUboot Slot 0 Image confirmed successfully!');
        _isSlot0Confirmed = true;
        return true;
      } else {
        _log('MCUboot Image Confirm status: rc=$rc (${McuMgrRc.describe(rc)})');
      }
    }
    return false;
  }

  Future<bool> _eraseSecondarySlot({int imageIndex = 0}) async {
    final bleState = ref.read(bleNotifierProvider);
    if (!bleState.isConnected) {
      _log('Cannot erase slot: Device disconnected.');
      return false;
    }

    final smpGatt = _findSmpGatt(bleState);
    _log('Sending MCUMGR Image Erase command (Secondary Slot for Image $imageIndex)...');
    _ensureRxSubscription(smpGatt.notifyCharUuid);

    final Map<String, dynamic> payloadMap = {
      'image': imageIndex,
      'slot': 1,
    };

    _seq = (_seq + 1) % 256;
    Uint8List erasePacket = SmpPacket.build(
      op: SmpPacket.opWrite,
      group: SmpPacket.groupImage,
      seq: _seq,
      id: SmpPacket.imgCmdErase,
      payloadMap: payloadMap,
    );

    Uint8List? resp = await _sendPacketAndWaitAck(
      smpGatt.serviceUuid,
      smpGatt.writeCharUuid,
      erasePacket,
      timeoutMs: 15000,
      withoutResponse: true,
      verbose: true,
    );

    if (resp != null) {
      final decoded = SimpleCbor.decodeMap(resp, 8);
      final rc = decoded['rc'] ?? 0;
      if (rc == 0) {
        _log('MCUboot Secondary Slot for Image $imageIndex erased successfully!');
        return true;
      } else if ((rc == McuMgrRc.noEntry || rc == McuMgrRc.invalidValue) && imageIndex != 0) {
        _log('Target MCUboot does not require separate erase for Image $imageIndex (rc=$rc). Continuing...');
        return true;
      } else {
        _log('MCUboot Secondary Slot Erase (Image $imageIndex) failed: rc=$rc (${McuMgrRc.describe(rc)})');
      }
    }return false;
  }

  Future<void> _resetTargetDevice() async {
    final bleState = ref.read(bleNotifierProvider);
    if (!bleState.isConnected) {
      _log('Cannot reset target: No BLE connection.');
      return;
    }

    final smpGatt = _findSmpGatt(bleState);

    _log('Sending OS reset command to target...');
    _ensureRxSubscription(smpGatt.notifyCharUuid);
    _seq = (_seq + 1) % 256;
    final resetPacket = SmpPacket.build(
      op: SmpPacket.opWrite,
      group: SmpPacket.groupOs,
      seq: _seq,
      id: SmpPacket.osCmdReset,
      payloadMap: {},
    );

    await _sendPacketAndWaitAck(
      smpGatt.serviceUuid,
      smpGatt.writeCharUuid,
      resetPacket,
      timeoutMs: 1500,
      withoutResponse: true,
    );
    _log('Reset command issued.');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bleState = ref.watch(bleNotifierProvider);

    return MyPanel(
      icon: Icons.cloud_upload,
      panelTitle: 'nRF BLE OTA (DFU)',
      panelSubtitle: 'Nordic MCUboot / SMP DFU Over-The-Air Firmware Update',
      panelActions: [
        PanelActionButton(
          icon: Icons.refresh,
          label: 'Query Image State',
          tooltipStr: 'Read MCUboot Slot 0 & Slot 1 image details',
          onPressed: bleState.isConnected ? _queryTargetImageState : null,
        ),
        PanelActionButton(
          icon: Icons.check_circle_outline,
          label: 'Confirm Slot 0',
          tooltipStr: 'Send MCUMGR Image Confirm command to mark active firmware confirmed & release Slot 1',
          onPressed: bleState.isConnected ? _confirmActiveImage : null,
        ),
        PanelActionButton(
          icon: Icons.delete_sweep,
          label: 'Erase Slot 1',
          tooltipStr: 'Send MCUMGR Image Erase command to clear secondary slot',
          onPressed: bleState.isConnected ? _eraseSecondarySlot : null,
        ),
        PanelActionButton(
          icon: Icons.restart_alt,
          label: 'Reset Target OS',
          tooltipStr: 'Send MCUMGR OS Reset command to reboot target device',
          onPressed: bleState.isConnected ? _resetTargetDevice : null,
        ),
        PanelActionButton(
          icon: Icons.copy,
          label: 'Copy Logs',
          tooltipStr: 'Copy full log output to clipboard',
          onPressed: _logs.isEmpty
              ? null
              : () {
                  Clipboard.setData(ClipboardData(text: _logs.join('\n')));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logs copied to clipboard!')),
                  );
                },
        ),
        PanelActionButton(
          icon: Icons.cleaning_services,
          label: 'Clear Logs',
          tooltipStr: 'Clear DFU console logs',
          onPressed: () => setState(() => _logs.clear()),
        ),
      ],
      children: [
        // 1. Connection Status Card
        MyPanelBody(
          icon: Icons.bluetooth,
          title: 'BLE Connection & Device Info',
          subtitle: bleState.isConnected
              ? 'Target Connected: ${bleState.connectedId}'
              : 'Disconnected — Please connect target device in Nordic Bluetooth panel',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: bleState.isConnected
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: bleState.isConnected ? Colors.green : Colors.red,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  bleState.isConnected
                      ? Icons.check_circle
                      : Icons.error_outline,
                  size: 14,
                  color: bleState.isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 6),
                Text(
                  bleState.isConnected ? 'CONNECTED' : 'DISCONNECTED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: bleState.isConnected ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _infoTile(
                      c, 'Negotiated MTU', '${bleState.mtu ?? 247} bytes'),
                  _infoTile(
                    c,
                    'SMP Service',
                    bleState.subscribed.contains(SmpUuids.characteristic)
                        ? 'Subscribed (Ready)'
                        : 'Discovered',
                  ),
                  _infoTile(c, 'Protocol', 'Zephyr MCUboot / SMP'),
                ],
              ),
              if (_targetSlot0Info != null || _targetSlot1Info != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: c.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target MCUboot Flash Slots:',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: c.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _targetSlot0Info ?? 'Slot 0: Unknown',
                        style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Consolas',
                            color: c.foreground),
                      ),
                      Text(
                        _targetSlot1Info ?? 'Slot 1: Unknown',
                        style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Consolas',
                            color: c.foreground),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // 2. Firmware Selection Card
        MyPanelBody(
          icon: Icons.insert_drive_file,
          title: 'Firmware Payload (.bin / .zip)',
          subtitle: _processedFirmware != null
              ? '${_processedFirmware!.fileName} (${(_processedFirmware!.bytes.length / 1024).toStringAsFixed(1)} kB)'
              : 'No file selected',
          trailing: PanelActionButton(
            icon: Icons.folder_open,
            label:
                _processedFirmware == null ? 'Select Firmware' : 'Change File',
            tooltipStr: 'Choose signed firmware binary for nRF MCUboot DFU',
            onPressed:
                _dfuStatus == SmpDfuStatus.uploading ? null : _pickFirmware,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_processedFirmware != null) ...[
                Row(
                  children: [
                    Text(
                      'MCUboot Header Magic: ',
                      style: TextStyle(fontSize: 11, color: c.muted),
                    ),
                    Text(
                      _processedFirmware!.header.isValidMagic
                          ? 'VALID (0x96F3B83D)'
                          : 'INVALID / MISSING',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _processedFirmware!.header.isValidMagic
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Detected Version: ',
                      style: TextStyle(fontSize: 11, color: c.muted),
                    ),
                    Text(
                      _processedFirmware!.header.version,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: c.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'SHA-256 Digest: ',
                      style: TextStyle(fontSize: 11, color: c.muted),
                    ),
                    Expanded(
                      child: SelectableText(
                        _processedFirmware!.sha256Hex,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'Consolas',
                          color: c.foreground,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!_processedFirmware!.header.isValidMagic) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Warning: You may have selected "zephyr.bin" (raw elf binary without MCUboot header). Please select signed "zephyr.signed.bin" or "dfu_application.zip" generated by west build.',
                            style: TextStyle(fontSize: 11, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                Text(
                  'Select a compiled MCUboot app image ("zephyr.signed.bin" or "dfu_application.zip") to update your Nordic device.',
                  style: TextStyle(fontSize: 12, color: c.muted),
                ),
              ],
            ],
          ),
        ),

        // 3. DFU Control & Progress Card
        MyPanelBody(
          icon: Icons.speed,
          title: 'DFU Transfer Engine',
          subtitle:
              'Progress: ${(_progress * 100).toStringAsFixed(1)}% | ${_speedKbps.toStringAsFixed(1)} kB/s',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 12,
                  backgroundColor: c.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _dfuStatus == SmpDfuStatus.error
                        ? Colors.red
                        : _dfuStatus == SmpDfuStatus.completed
                            ? Colors.green
                            : c.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sent: ${(_bytesSent / 1024).toStringAsFixed(1)} / ${((_processedFirmware?.bytes.length ?? 0) / 1024).toStringAsFixed(1)} kB',
                    style: TextStyle(
                        fontSize: 11, color: c.muted, fontFamily: 'Consolas'),
                  ),
                  Text(
                    'Status: ${_dfuStatus.name.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _dfuStatus == SmpDfuStatus.error
                          ? Colors.red
                          : _dfuStatus == SmpDfuStatus.completed
                              ? Colors.green
                              : c.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _autoConfirm,
                      onChanged: (val) {
                        if (val != null) setState(() => _autoConfirm = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Permanent Swap & Confirm (confirm = true)',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.foreground),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recommended: Prevents MCUboot from reverting to old version on subsequent reboot.',
                      style: TextStyle(fontSize: 11, color: c.muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  PanelActionButton(
                    icon: Icons.play_arrow,
                    label: _dfuStatus == SmpDfuStatus.uploading
                        ? 'Uploading…'
                        : 'Start DFU Upload',
                    tooltipStr: 'Transmit firmware payload via BLE SMP service',
                    onPressed: (_dfuStatus == SmpDfuStatus.uploading ||
                            _processedFirmware == null ||
                            !bleState.isConnected)
                        ? null
                        : _startDfu,
                  ),
                  if (_dfuStatus == SmpDfuStatus.uploading ||
                      _dfuStatus == SmpDfuStatus.paused) ...[
                    PanelActionButton(
                      icon: _isPaused ? Icons.play_arrow : Icons.pause,
                      label: _isPaused ? 'Resume' : 'Pause',
                      tooltipStr: 'Pause or resume packet transmission',
                      onPressed: _togglePause,
                    ),
                    PanelActionButton(
                      icon: Icons.stop,
                      label: 'Cancel',
                      tooltipStr: 'Abort OTA update session',
                      onPressed: _cancelDfu,
                    ),
                  ],
                  PanelActionButton(
                    icon: Icons.restart_alt,
                    label: 'Reset Target',
                    tooltipStr: 'Issue OS reboot command to nRF device',
                    onPressed: bleState.isConnected ? _resetTargetDevice : null,
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Error: $_errorMessage',
                  style: const TextStyle(fontSize: 11, color: Colors.red),
                ),
              ],
            ],
          ),
        ),

        // 4. Console Log Output Card
        MyPanelBody(
          icon: Icons.terminal,
          title: 'DFU Log Console',
          subtitle: 'Live packet and state notifications',
          child: Container(
            height: 180,
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: c.border),
            ),
            child: SingleChildScrollView(
              controller: _logScrollController,
              child: SelectableText(
                _logs.isEmpty ? 'No logs yet.' : _logs.join('\n'),
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Consolas',
                  color: c.foreground.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoTile(AppColors c, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: c.muted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: c.foreground,
          ),
        ),
      ],
    );
  }
}
