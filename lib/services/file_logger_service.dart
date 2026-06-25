import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_logger_service.g.dart';

class FileLoggerState {
  const FileLoggerState({
    this.isLogging = false,
    this.timestampEnabled = true,
  });
  final bool isLogging;
  final bool timestampEnabled;
}

@Riverpod(keepAlive: true)
class FileLoggerNotifier extends _$FileLoggerNotifier {
  IOSink? _sink;
  String _buffer = '';
  bool _needsTimestamp = true;

  static final _ansiEscape = RegExp(r'\x1b\[[0-?]*[ -/]*[@-~]');
  static final _controlChars = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]');

  @override
  FileLoggerState build() => const FileLoggerState();

  Future<bool> startLogging() async {
    final dir = await FilePicker.getDirectoryPath(
      dialogTitle: 'Select folder to save log',
    );
    if (dir == null) return false;

    final now = DateTime.now();
    final ts = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '_${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final file = File(p.join(dir, 'sanc_term_$ts.txt'));
    _sink = file.openWrite(mode: FileMode.append);
    _buffer = '';
    _needsTimestamp = true;
    state = FileLoggerState(
      isLogging: true,
      timestampEnabled: state.timestampEnabled,
    );
    return true;
  }

  Future<void> stopLogging() async {
    if (_sink == null) return;
    if (_buffer.isNotEmpty) {
      final sanitized = _sanitize(_buffer);
      _buffer = '';
      if (sanitized.isNotEmpty) _write(sanitized);
    }
    await _sink!.close();
    _sink = null;
    state = FileLoggerState(
      isLogging: false,
      timestampEnabled: state.timestampEnabled,
    );
  }

  void setTimestamp(bool enabled) {
    state = FileLoggerState(isLogging: state.isLogging, timestampEnabled: enabled);
  }

  void log(String data) {
    if (_sink == null) return;
    _buffer += data;

    // Strip complete ANSI sequences.
    _buffer = _buffer.replaceAll(_ansiEscape, '');

    // Hold back incomplete escape sequences at the tail.
    final escIdx = _buffer.lastIndexOf('\x1b');
    String safe = _buffer;

    if (escIdx != -1) {
      if (_buffer.length - escIdx > 32) {
        // Sequence too long — not a real escape, flush everything.
        safe = _buffer;
        _buffer = '';
      } else {
        safe = _buffer.substring(0, escIdx);
        _buffer = _buffer.substring(escIdx);
      }
    } else {
      _buffer = '';
    }

    if (safe.isNotEmpty) {
      safe = _sanitize(safe);
      if (safe.isNotEmpty) _write(safe);
    }
  }

  String _sanitize(String data) => data
      .replaceAll('\r', '')
      .replaceAll(_controlChars, '')
      .replaceAll('�', '');

  void _write(String data) {
    if (!state.timestampEnabled) {
      _sink!.write(data);
      if (data.endsWith('\n')) {
        _needsTimestamp = true;
      } else if (data.isNotEmpty) {
        _needsTimestamp = false;
      }
      return;
    }

    final prefix = '[${DateTime.now().toLocal()}] ';
    var out = data;
    if (_needsTimestamp) {
      out = '$prefix$out';
      _needsTimestamp = false;
    }
    out = out.replaceAll('\n', '\n$prefix');
    if (data.endsWith('\n')) {
      if (out.endsWith(prefix)) out = out.substring(0, out.length - prefix.length);
      _needsTimestamp = true;
    }
    _sink!.write(out);
  }
}
