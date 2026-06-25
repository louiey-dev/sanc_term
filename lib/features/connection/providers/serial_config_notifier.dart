import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanc_term/shared/models/serial_config.dart';

part 'serial_config_notifier.g.dart';

@riverpod
class SerialConfigNotifier extends _$SerialConfigNotifier {
  @override
  SerialConfig build() => const SerialConfig();

  void setPort(String port) => state = state.copyWith(port: port);
  void setBaudRate(int baudRate) => state = state.copyWith(baudRate: baudRate);
  void setEncoding(SerialEncoding encoding) =>
      state = state.copyWith(encoding: encoding);
  void setNewLine(NewLine newLine) => state = state.copyWith(newLine: newLine);
}

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
