import 'package:freezed_annotation/freezed_annotation.dart';

part 'log_entry.freezed.dart';
part 'log_entry.g.dart';

enum LogSource { serial, udp, pty, system }

enum LogLevel { info, warning, error }

@freezed
abstract class LogEntry with _$LogEntry {
  const factory LogEntry({
    required String text,
    required DateTime timestamp,
    @Default(LogSource.serial) LogSource source,
    @Default(LogLevel.info) LogLevel level,
  }) = _LogEntry;

  factory LogEntry.fromJson(Map<String, dynamic> json) =>
      _$LogEntryFromJson(json);
}
