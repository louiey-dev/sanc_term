import 'dart:async';
import 'dart:convert';

import 'package:flutter_pty/flutter_pty.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which transport a [BoardConsole] speaks over.
enum ConsoleKind { pty, serial }

/// A console we can run a shell command on and capture its output.
///
/// Implemented by [PtyConsole] (a running PTY/SSH pane) and by the serial
/// adapter in `board_console_selector.dart`.
abstract class BoardConsole {
  String get id;
  ConsoleKind get kind;
  bool get isConnected;

  /// Runs [command] and returns only its stdout (echo + prompt stripped).
  Future<String> run(
    String command, {
    Duration timeout = const Duration(seconds: 4),
  });

  /// Writes raw [data] to the console with no capture (fire-and-forget); output
  /// flows to the terminal pane as usual. Used by panels that just run a command
  /// and let the user watch the terminal.
  void send(String data);
}

/// Runs one command at a time on an interactive console and captures the
/// output between the echoed command and a unique end marker.
///
/// Protocol: send `<command>; echo SANC"END"<nonce><CR>`. The shell joins the
/// quoted pieces and prints `SANCEND<nonce>`, while the *echoed* command line
/// keeps the quotes (`SANC"END"<nonce>`) — so a substring search for the marker
/// matches only the real output, never our own echo. This also handles output
/// with no trailing newline (e.g. `/proc/device-tree/model`), where the marker
/// is glued onto the value.
class ConsoleCommandSession {
  /// ANSI/VT escape sequences (CSI), e.g. the `ESC[?2004l` bracketed-paste
  /// markers bash emits around the prompt, and colour codes like `ESC[0m`.
  static final RegExp _ansi = RegExp(r'\x1B\[[0-9;?]*[ -/]*[@-~]');

  Completer<String>? _completer;
  final StringBuffer _buf = StringBuffer();
  String _marker = '';
  String _sent = '';
  Timer? _timeout;

  bool get busy => _completer != null;

  /// Feed every chunk of console output here (raw decoded text).
  void feed(String text) {
    if (_completer == null) return;
    _buf.write(text);
    // The echoed command keeps the quotes (SANC"END"...), so a plain substring
    // search for the joined marker only matches the real output.
    if (_buf.toString().contains(_marker)) _complete();
  }

  Future<String> run(
    void Function(String data) write,
    String command, {
    Duration timeout = const Duration(seconds: 4),
  }) {
    if (_completer != null) {
      return Future.error(StateError('console is busy with another command'));
    }
    final nonce = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    _marker = 'SANCEND$nonce';
    // Quote-split so the echoed line differs from the printed marker.
    _sent = '$command; echo SANC"END"$nonce';
    _buf.clear();
    final completer = _completer = Completer<String>();
    _timeout = Timer(timeout, () {
      if (_completer == completer && !completer.isCompleted) {
        _reset();
        completer.completeError(TimeoutException('command timed out'));
      }
    });
    write('$_sent\r');
    return completer.future;
  }

  void _complete() {
    final completer = _completer!;
    final raw = _buf.toString();
    final result = _extract(raw);
    _reset();
    if (!completer.isCompleted) completer.complete(result);
  }

  String _extract(String raw) {
    // Keep only text before the printed marker (handles the marker being glued
    // onto output that has no trailing newline).
    final idx = raw.indexOf(_marker);
    final before = idx >= 0 ? raw.substring(0, idx) : raw;
    final out = <String>[];
    for (final rawLine in before.split('\n')) {
      final line =
          rawLine.replaceAll(_ansi, '').replaceAll('\r', '').trimRight();
      if (line.trim().isEmpty) continue;
      if (line.contains(_sent)) continue; // drop the echoed command line
      out.add(line);
    }
    return out.join('\n').trim();
  }

  void _reset() {
    _timeout?.cancel();
    _timeout = null;
    _completer = null;
    _buf.clear();
  }
}

/// A [BoardConsole] backed by a running PTY (e.g. a shell or SSH session).
class PtyConsole implements BoardConsole {
  PtyConsole({required this.id, required Pty pty}) : _pty = pty;

  @override
  final String id;
  final Pty _pty;
  final ConsoleCommandSession _session = ConsoleCommandSession();
  bool _alive = true;

  @override
  ConsoleKind get kind => ConsoleKind.pty;

  @override
  bool get isConnected => _alive;

  /// Called by the PTY owner for every output chunk.
  void feed(String text) => _session.feed(text);

  void markClosed() => _alive = false;

  @override
  Future<String> run(
    String command, {
    Duration timeout = const Duration(seconds: 4),
  }) =>
      _session.run(
        (data) => _pty.write(const Utf8Encoder().convert(data)),
        command,
        timeout: timeout,
      );

  @override
  void send(String data) => _pty.write(const Utf8Encoder().convert(data));
}

/// Holds the consoles backed by live PTY panes so other features (panels) can
/// find one to run commands on. PTY owners register/unregister here.
class BoardConsoleRegistry {
  final Map<String, BoardConsole> _consoles = {};

  void register(BoardConsole console) => _consoles[console.id] = console;
  void unregister(String id) => _consoles.remove(id);

  Iterable<BoardConsole> get all => _consoles.values;
}

final boardConsoleRegistryProvider = Provider<BoardConsoleRegistry>(
  (_) => BoardConsoleRegistry(),
);
