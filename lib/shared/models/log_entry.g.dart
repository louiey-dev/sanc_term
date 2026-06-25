// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LogEntry _$LogEntryFromJson(Map<String, dynamic> json) => _LogEntry(
  text: json['text'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  source:
      $enumDecodeNullable(_$LogSourceEnumMap, json['source']) ??
      LogSource.serial,
  level: $enumDecodeNullable(_$LogLevelEnumMap, json['level']) ?? LogLevel.info,
);

Map<String, dynamic> _$LogEntryToJson(_LogEntry instance) => <String, dynamic>{
  'text': instance.text,
  'timestamp': instance.timestamp.toIso8601String(),
  'source': _$LogSourceEnumMap[instance.source]!,
  'level': _$LogLevelEnumMap[instance.level]!,
};

const _$LogSourceEnumMap = {
  LogSource.serial: 'serial',
  LogSource.udp: 'udp',
  LogSource.pty: 'pty',
  LogSource.system: 'system',
};

const _$LogLevelEnumMap = {
  LogLevel.info: 'info',
  LogLevel.warning: 'warning',
  LogLevel.error: 'error',
};
