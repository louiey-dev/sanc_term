import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanc_term/services/udp_service.dart';

part 'udp_notifier.g.dart';

/// One line in the traffic log — a datagram we sent or received.
class UdpLogEntry {
  UdpLogEntry({
    required this.outgoing,
    required this.peer,
    required this.text,
    required this.time,
  });

  final bool outgoing;
  final String peer;
  final String text;
  final DateTime time;
}

/// UI-facing state for the UDP panel: whether we are listening, on which port,
/// the rolling traffic log, and the last error. Input fields (target ip/port,
/// message) live in the widget as controllers; this only holds what the panel
/// cannot derive synchronously.
class UdpState {
  const UdpState({
    this.listening = false,
    this.boundPort,
    this.log = const [],
    this.error,
  });

  final bool listening;
  final int? boundPort;
  final List<UdpLogEntry> log;
  final String? error;

  static const _unset = Object();

  UdpState copyWith({
    bool? listening,
    Object? boundPort = _unset,
    List<UdpLogEntry>? log,
    Object? error = _unset,
  }) {
    return UdpState(
      listening: listening ?? this.listening,
      boundPort:
          identical(boundPort, _unset) ? this.boundPort : boundPort as int?,
      log: log ?? this.log,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

@riverpod
class UdpNotifier extends _$UdpNotifier {
  // Keep the log bounded so a chatty peer can't grow it without limit.
  static const _maxLog = 200;

  StreamSubscription<UdpDatagram>? _sub;

  /// Optional hook fired for every received datagram (after it is logged).
  /// Assign it to plug in custom handling — e.g. parse a protocol, forward the
  /// bytes elsewhere, trigger a command. Left null by default:
  ///
  /// ```dart
  /// ref.read(udpNotifierProvider.notifier).onReceive = (dg) {
  ///   // dg.address, dg.port, dg.data
  /// };
  /// ```
  void Function(UdpDatagram datagram)? onReceive;

  UdpService get _udp => ref.read(udpServiceProvider);

  @override
  UdpState build() {
    ref.onDispose(() => _sub?.cancel());
    _sub = _udp.incoming.listen(_handleReceived);
    return const UdpState();
  }

  /// Called for each datagram arriving on the bound port. Logs it, then invokes
  /// the [onReceive] hook. Add any always-on receive handling right here.
  void _handleReceived(UdpDatagram datagram) {
    _append(
      UdpLogEntry(
        outgoing: false,
        peer: datagram.peer,
        text: _decode(datagram.data),
        time: DateTime.now(),
      ),
    );

    // --- UDP receive extension point -------------------------------------
    // Add custom handling of incoming datagrams here, or assign [onReceive]
    // from outside the notifier.
    onReceive?.call(datagram);
    // ---------------------------------------------------------------------
  }

  Future<void> toggleListen(int port) =>
      state.listening ? stopListen() : startListen(port);

  Future<void> startListen(int port) async {
    try {
      await _udp.bind(port);
      state = state.copyWith(
        listening: true,
        boundPort: _udp.boundPort,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(listening: false, boundPort: null, error: '$e');
    }
  }

  Future<void> stopListen() async {
    _udp.close();
    state = state.copyWith(listening: false, boundPort: null);
  }

  Future<void> send(String host, int port, String message) async {
    if (host.isEmpty) {
      state = state.copyWith(error: 'Target IP is empty');
      return;
    }
    try {
      final bytes = utf8.encode(message);
      await _udp.send(host, port, bytes);
      // Reflect the ephemeral bind that send() may have created.
      final bound = _udp.boundPort;
      state = state.copyWith(boundPort: bound, error: null);
      _append(
        UdpLogEntry(
          outgoing: true,
          peer: '$host:$port',
          text: message,
          time: DateTime.now(),
        ),
      );
    } catch (e) {
      state = state.copyWith(error: '$e');
    }
  }

  void clearLog() => state = state.copyWith(log: const []);

  void _append(UdpLogEntry entry) {
    final log = [...state.log, entry];
    if (log.length > _maxLog) log.removeRange(0, log.length - _maxLog);
    state = state.copyWith(log: log);
  }

  String _decode(List<int> data) =>
      const Utf8Decoder(allowMalformed: true).convert(data);
}
