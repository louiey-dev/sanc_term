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
      // Run the blocking SerialPort.availablePorts call in a background isolate
      final ports = await Isolate.run(() => SerialPort.availablePorts);
      state = ports.toSet().toList();
    } catch (_) {
      state = [];
    } finally {
      loadingNotifier.setLoading(false);
    }
  }
}

