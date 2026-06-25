// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BoardProfile _$BoardProfileFromJson(Map<String, dynamic> json) =>
    _BoardProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      port: json['port'] as String? ?? '',
      baudRate: (json['baudRate'] as num?)?.toInt() ?? 115200,
      targetType:
          $enumDecodeNullable(_$TargetTypeEnumMap, json['targetType']) ??
          TargetType.nvidia,
      ipAddress: json['ipAddress'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      lastUsed: json['lastUsed'] == null
          ? null
          : DateTime.parse(json['lastUsed'] as String),
    );

Map<String, dynamic> _$BoardProfileToJson(_BoardProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'port': instance.port,
      'baudRate': instance.baudRate,
      'targetType': _$TargetTypeEnumMap[instance.targetType]!,
      'ipAddress': instance.ipAddress,
      'isDefault': instance.isDefault,
      'lastUsed': instance.lastUsed?.toIso8601String(),
    };

const _$TargetTypeEnumMap = {
  TargetType.nvidia: 'nvidia',
  TargetType.rockchip: 'rockchip',
  TargetType.esp: 'esp',
  TargetType.common: 'common',
  TargetType.lte: 'lte',
};
