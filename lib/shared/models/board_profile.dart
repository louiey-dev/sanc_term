import 'package:freezed_annotation/freezed_annotation.dart';

part 'board_profile.freezed.dart';
part 'board_profile.g.dart';

enum TargetType {
  nvidia,
  rockchip,
  esp,
  common,
  lte;

  String get label => switch (this) {
        TargetType.nvidia => 'NVIDIA',
        TargetType.rockchip => 'Rockchip',
        TargetType.esp => 'ESP',
        TargetType.common => 'Common',
        TargetType.lte => 'LTE',
      };
}

@freezed
abstract class BoardProfile with _$BoardProfile {
  const factory BoardProfile({
    required String id,
    required String name,
    @Default('') String port,
    @Default(115200) int baudRate,
    @Default(TargetType.nvidia) TargetType targetType,
    String? ipAddress,
    @Default(false) bool isDefault,
    DateTime? lastUsed,
  }) = _BoardProfile;

  factory BoardProfile.fromJson(Map<String, dynamic> json) =>
      _$BoardProfileFromJson(json);
}
