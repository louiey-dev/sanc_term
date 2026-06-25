import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanc_term/shared/models/serial_config.dart';

part 'connection_provider.g.dart';

sealed class ConnState {
  const ConnState();
}

class Disconnected extends ConnState {
  const Disconnected();
}

class Connecting extends ConnState {
  const Connecting(this.port);
  final String port;
}

class Connected extends ConnState {
  const Connected({required this.port, required this.baudRate});
  final String port;
  final int baudRate;
}

@riverpod
class ConnectionNotifier extends _$ConnectionNotifier {
  @override
  ConnState build() => const Disconnected();

  Future<void> connect(SerialConfig config) async {
    state = Connecting(config.port);
    // TODO: delegate to SerialService
    state = Connected(port: config.port, baudRate: config.baudRate);
  }

  void disconnect() {
    // TODO: delegate to SerialService
    state = const Disconnected();
  }
}
