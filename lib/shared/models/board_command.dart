import 'package:freezed_annotation/freezed_annotation.dart';

part 'board_command.freezed.dart';
part 'board_command.g.dart';

@freezed
abstract class BoardCommand with _$BoardCommand {
  const factory BoardCommand({
    required String id,
    required String command,
    required String label,
    @Default('') String description,
  }) = _BoardCommand;

  factory BoardCommand.fromJson(Map<String, dynamic> json) =>
      _$BoardCommandFromJson(json);
}
