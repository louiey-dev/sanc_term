import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xterm/xterm.dart';
import 'package:sanc_term/features/connection/providers/board_console.dart';
import 'package:sanc_term/features/terminal/models/terminal_tab.dart';
import 'package:sanc_term/features/terminal/providers/terminal_instances.dart';
import 'package:sanc_term/services/file_logger_service.dart';
import 'package:sanc_term/shared/models/serial_config.dart';

part 'serial_pane_provider.g.dart';

enum SerialStatus { disconnected, connecting, connected }

class SerialPaneState {
  const SerialPaneState({
    this.config = const SerialConfig(),
    this.status = SerialStatus.disconnected,
    this.error,
  });

  final SerialConfig config;
  final SerialStatus status;
  final String? error;

  bool get isConnected => status == SerialStatus.connected;

  // Sentinel so `error` is preserved when omitted; pass `error: null` to clear.
  static const _unset = Object();

  SerialPaneState copyWith({
    SerialConfig? config,
    SerialStatus? status,
    Object? error = _unset,
  }) {
    return SerialPaneState(
      config: config ?? this.config,
      status: status ?? this.status,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

/// Per-pane serial connection. Each SERIAL tab gets its own instance keyed by
/// tab id, so two panes can each hold an independent COM port.
@riverpod
class SerialPaneNotifier extends _$SerialPaneNotifier {
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription<Uint8List>? _sub;
  final ConsoleCommandSession _cmd = ConsoleCommandSession();

  bool get isConnected => state.isConnected;

  /// Fire-and-forget write to the open port (no capture).
  void send(String data) {
    final port = _port;
    if (port == null) return;
    try {
      port.write(Uint8List.fromList(utf8.encode(data)));
    } catch (_) {}
  }

  /// Runs [command] over this serial connection and returns its output.
  /// Errors if the port is not open.
  Future<String> runCommand(
    String command, {
    Duration timeout = const Duration(seconds: 4),
  }) {
    if (_port == null) {
      return Future.error(StateError('serial port is not connected'));
    }
    return _cmd.run(
      (data) => _port?.write(Uint8List.fromList(utf8.encode(data))),
      command,
      timeout: timeout,
    );
  }

  @override
  SerialPaneState build(String tabId) {
    ref.onDispose(_cleanup);
    return const SerialPaneState();
  }

  void setPort(String port) =>
      state = state.copyWith(config: state.config.copyWith(port: port));
  void setBaudRate(int baud) =>
      state = state.copyWith(config: state.config.copyWith(baudRate: baud));
  void setEncoding(SerialEncoding enc) =>
      state = state.copyWith(config: state.config.copyWith(encoding: enc));
  void setNewLine(NewLine nl) =>
      state = state.copyWith(config: state.config.copyWith(newLine: nl));

  Future<void> connect() async {
    final cfg = state.config;
    if (cfg.port.isEmpty || state.isConnected) return;
    // Clear any stale error from a previous attempt.
    state = state.copyWith(status: SerialStatus.connecting, error: null);

    try {
      final port = SerialPort(cfg.port);
      if (!port.openReadWrite()) {
        port.dispose();
        throw SerialPortError(SerialPort.lastError?.message ?? 'open failed');
      }
      port.config = SerialPortConfig()
        ..baudRate = cfg.baudRate
        ..bits = 8
        ..parity = SerialPortParity.none
        ..stopBits = 1
        ..setFlowControl(SerialPortFlowControl.none);
      _port = port;

      final terminal = _terminal();
      final reader = SerialPortReader(port);
      _reader = reader;
      _sub = reader.stream.listen(
        (data) {
          // Read encoding live so changes mid-connection take effect.
          final text = _decode(data, state.config.encoding);
          // Command capture must keep running even while paused.
          _cmd.feed(text);
          // Pause only gates what reaches the terminal view and the log file.
          if (!ref.read(terminalPausedProvider)) {
            terminal?.write(text);
            ref.read(fileLoggerNotifierProvider.notifier).log(text);
          }
        },
        onError: (Object e) {
          state = state.copyWith(
            status: SerialStatus.disconnected,
            error: '$e',
          );
          _cleanup();
        },
      );

      // Forward keystrokes from the terminal to the port. Read newLine live so
      // changes mid-connection take effect.
      terminal?.onOutput = (data) {
        final nl = state.config.newLine;
        final out =
            nl == NewLine.none ? data : data.replaceAll('\r', nl.suffix);
        try {
          _port?.write(Uint8List.fromList(utf8.encode(out)));
        } catch (_) {}
      };

      state = state.copyWith(status: SerialStatus.connected, error: null);
    } catch (e) {
      _cleanup();
      state = state.copyWith(status: SerialStatus.disconnected, error: '$e');
    }
  }

  void disconnect() {
    _cleanup();
    state = state.copyWith(status: SerialStatus.disconnected, error: null);
  }

  Terminal? _terminal() {
    for (final t in ref.read(terminalTabsNotifierProvider)) {
      if (t.id == tabId && t.type == TerminalTabType.serial) return t.terminal;
    }
    return null;
  }

  String _decode(Uint8List data, SerialEncoding enc) => switch (enc) {
        SerialEncoding.utf8 =>
          const Utf8Decoder(allowMalformed: true).convert(data),
        SerialEncoding.latin1 => latin1.decode(data, allowInvalid: true),
        SerialEncoding.raw => String.fromCharCodes(data),
        SerialEncoding.hex =>
          '${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')} ',
      };

  void _cleanup() {
    _sub?.cancel();
    _sub = null;
    _reader?.close();
    _reader = null;
    _port?.close();
    _port?.dispose();
    _port = null;
  }
}

/// Explicitly selected active SERIAL tab id (set when a pane is tapped).
final serialActiveTabIdProvider = StateProvider<String?>((ref) => null);

/// The SERIAL tab the connection bar currently acts on: the explicit selection
/// if it still exists, otherwise the first SERIAL pane. Null if none.
@riverpod
String? effectiveActiveSerialTabId(Ref ref) {
  final serials = ref
      .watch(terminalTabsNotifierProvider)
      .where((t) => t.type == TerminalTabType.serial)
      .toList();
  if (serials.isEmpty) return null;
  final activeId = ref.watch(activeTabIdProvider);
  if (activeId != null && serials.any((t) => t.id == activeId)) return activeId;
  final selected = ref.watch(serialActiveTabIdProvider);
  if (selected != null && serials.any((t) => t.id == selected)) return selected;
  return serials.first.id;
}
