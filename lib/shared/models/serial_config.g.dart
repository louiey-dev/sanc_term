// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serial_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SerialConfig _$SerialConfigFromJson(Map<String, dynamic> json) =>
    _SerialConfig(
      port: json['port'] as String? ?? '',
      baudRate: (json['baudRate'] as num?)?.toInt() ?? 115200,
      encoding:
          $enumDecodeNullable(_$SerialEncodingEnumMap, json['encoding']) ??
          SerialEncoding.utf8,
      newLine:
          $enumDecodeNullable(_$NewLineEnumMap, json['newLine']) ??
          NewLine.none,
    );

Map<String, dynamic> _$SerialConfigToJson(_SerialConfig instance) =>
    <String, dynamic>{
      'port': instance.port,
      'baudRate': instance.baudRate,
      'encoding': _$SerialEncodingEnumMap[instance.encoding]!,
      'newLine': _$NewLineEnumMap[instance.newLine]!,
    };

const _$SerialEncodingEnumMap = {
  SerialEncoding.utf8: 'utf8',
  SerialEncoding.latin1: 'latin1',
  SerialEncoding.raw: 'raw',
  SerialEncoding.hex: 'hex',
};

const _$NewLineEnumMap = {
  NewLine.lf: 'lf',
  NewLine.crlf: 'crlf',
  NewLine.cr: 'cr',
  NewLine.none: 'none',
};
