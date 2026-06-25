import 'package:freezed_annotation/freezed_annotation.dart';

part 'serial_config.freezed.dart';
part 'serial_config.g.dart';

enum SerialEncoding { utf8, latin1, raw, hex }

extension SerialEncodingLabel on SerialEncoding {
  String get label => switch (this) {
        SerialEncoding.utf8 => 'UTF-8',
        SerialEncoding.latin1 => 'Latin1',
        SerialEncoding.raw => 'Raw',
        SerialEncoding.hex => 'Hex',
      };
}

enum NewLine { lf, crlf, cr, none }

extension NewLineExt on NewLine {
  String get label => switch (this) {
        NewLine.lf => 'LF',
        NewLine.crlf => 'CR+LF',
        NewLine.cr => 'CR',
        NewLine.none => 'None',
      };

  String get suffix => switch (this) {
        NewLine.lf => '\n',
        NewLine.crlf => '\r\n',
        NewLine.cr => '\r',
        NewLine.none => '',
      };
}

@freezed
abstract class SerialConfig with _$SerialConfig {
  const factory SerialConfig({
    @Default('') String port,
    @Default(115200) int baudRate,
    @Default(SerialEncoding.utf8) SerialEncoding encoding,
    @Default(NewLine.none) NewLine newLine,
  }) = _SerialConfig;

  factory SerialConfig.fromJson(Map<String, dynamic> json) =>
      _$SerialConfigFromJson(json);
}
