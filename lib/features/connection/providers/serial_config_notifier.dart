import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'serial_config_notifier.g.dart';

@riverpod
class AvailablePortsNotifier extends _$AvailablePortsNotifier {
  @override
  List<String> build() => [];

  void scan() {
    try {
      state = SerialPort.availablePorts.toSet().toList();
    } catch (_) {
      state = [];
    }
  }
}
