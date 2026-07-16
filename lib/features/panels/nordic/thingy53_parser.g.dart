// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thingy53_parser.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Thingy53Telemetry _$Thingy53TelemetryFromJson(Map<String, dynamic> json) =>
    _Thingy53Telemetry(
      temperature: (json['temperature'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      pressure: (json['pressure'] as num?)?.toDouble(),
      gasResistance: (json['gasResistance'] as num?)?.toDouble(),
      accelX: (json['accelX'] as num?)?.toDouble(),
      accelY: (json['accelY'] as num?)?.toDouble(),
      accelZ: (json['accelZ'] as num?)?.toDouble(),
      gyroX: (json['gyroX'] as num?)?.toDouble(),
      gyroY: (json['gyroY'] as num?)?.toDouble(),
      gyroZ: (json['gyroZ'] as num?)?.toDouble(),
      magX: (json['magX'] as num?)?.toDouble(),
      magY: (json['magY'] as num?)?.toDouble(),
      magZ: (json['magZ'] as num?)?.toDouble(),
      lightRed: (json['lightRed'] as num?)?.toInt(),
      lightGreen: (json['lightGreen'] as num?)?.toInt(),
      lightBlue: (json['lightBlue'] as num?)?.toInt(),
      lightIr: (json['lightIr'] as num?)?.toInt(),
      batteryMillivolts: (json['batteryMillivolts'] as num?)?.toInt(),
      rawOutput: json['rawOutput'] as String?,
    );

Map<String, dynamic> _$Thingy53TelemetryToJson(_Thingy53Telemetry instance) =>
    <String, dynamic>{
      'temperature': instance.temperature,
      'humidity': instance.humidity,
      'pressure': instance.pressure,
      'gasResistance': instance.gasResistance,
      'accelX': instance.accelX,
      'accelY': instance.accelY,
      'accelZ': instance.accelZ,
      'gyroX': instance.gyroX,
      'gyroY': instance.gyroY,
      'gyroZ': instance.gyroZ,
      'magX': instance.magX,
      'magY': instance.magY,
      'magZ': instance.magZ,
      'lightRed': instance.lightRed,
      'lightGreen': instance.lightGreen,
      'lightBlue': instance.lightBlue,
      'lightIr': instance.lightIr,
      'batteryMillivolts': instance.batteryMillivolts,
      'rawOutput': instance.rawOutput,
    };
