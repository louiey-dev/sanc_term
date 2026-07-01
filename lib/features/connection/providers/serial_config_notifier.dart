import 'dart:io';
import 'dart:isolate';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'serial_config_notifier.g.dart';

@riverpod
class SerialScanLoading extends _$SerialScanLoading {
  @override
  bool build() => false;

  void setLoading(bool loading) => state = loading;
}

@riverpod
class AvailablePortsNotifier extends _$AvailablePortsNotifier {
  @override
  List<String> build() => [];

  Future<void> scan() async {
    final loadingNotifier = ref.read(serialScanLoadingProvider.notifier);
    if (ref.read(serialScanLoadingProvider)) return;

    loadingNotifier.setLoading(true);
    try {
      state = await _listPorts();
    } catch (_) {
      state = [];
    } finally {
      loadingNotifier.setLoading(false);
    }
  }
}

/// Enumerates serial port names.
///
/// On Windows, `SerialPort.availablePorts` (libserialport's `sp_list_ports`)
/// opens and probes every device for USB metadata we never use — Bluetooth
/// virtual COM ports in particular can each stall for seconds. We only need the
/// names for the dropdown, so we read them straight from
/// `HKLM\HARDWARE\DEVICEMAP\SERIALCOMM`, which is effectively instant. Other
/// platforms keep the libserialport path, run off the UI thread in an isolate.
Future<List<String>> _listPorts() async {
  if (Platform.isWindows) return _listWindowsPorts();
  final ports = await Isolate.run(() => SerialPort.availablePorts);
  return ports.toSet().toList();
}

/// Reads active COM ports from the Windows registry. Each value line looks like
/// `\Device\Serial0    REG_SZ    COM3`; the port name is the data after REG_SZ.
Future<List<String>> _listWindowsPorts() async {
  final result = await Process.run('reg', [
    'query',
    r'HKLM\HARDWARE\DEVICEMAP\SERIALCOMM',
  ]);
  // Exit code 1 means the key is absent, i.e. no serial ports are present.
  if (result.exitCode != 0) return const [];

  const marker = 'REG_SZ';
  final ports = <String>{};
  for (final line in (result.stdout as String).split('\n')) {
    final i = line.indexOf(marker);
    if (i == -1) continue;
    final name = line.substring(i + marker.length).trim();
    if (name.isNotEmpty) ports.add(name);
  }

  // Natural sort so COM2 precedes COM10 instead of lexical order.
  final sorted = ports.toList()
    ..sort((a, b) {
      final na = int.tryParse(a.replaceAll(RegExp(r'\D'), ''));
      final nb = int.tryParse(b.replaceAll(RegExp(r'\D'), ''));
      if (na != null && nb != null) return na.compareTo(nb);
      return a.compareTo(b);
    });
  return sorted;
}

