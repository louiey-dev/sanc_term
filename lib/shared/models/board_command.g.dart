// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board_command.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BoardCommand _$BoardCommandFromJson(Map<String, dynamic> json) =>
    _BoardCommand(
      id: json['id'] as String,
      command: json['command'] as String,
      label: json['label'] as String,
      description: json['description'] as String? ?? '',
    );

Map<String, dynamic> _$BoardCommandToJson(_BoardCommand instance) =>
    <String, dynamic>{
      'id': instance.id,
      'command': instance.command,
      'label': instance.label,
      'description': instance.description,
    };
