import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.card,
    required this.sidebar,
    required this.surface,
    required this.border,
    required this.primary,
    required this.primaryForeground,
    required this.foreground,
    required this.muted,
    required this.warning,
    required this.destructive,
    required this.success,
    required this.chartBlue,
  });

  final Color background;
  final Color card;
  final Color sidebar;
  final Color surface;
  final Color border;
  final Color primary;
  final Color primaryForeground;
  final Color foreground;
  final Color muted;
  final Color warning;
  final Color destructive;
  final Color success;
  final Color chartBlue;

  static const dark = AppColors(
    background: Color(0xFF1A1A2E),
    card: Color(0xFF222240),
    sidebar: Color(0xFF16162A),
    surface: Color(0xFF2A2A48),
    border: Color(0xFF35355A),
    primary: Color(0xFF2DD4A8),
    primaryForeground: Color(0xFF1A1A2E),
    foreground: Color(0xFFE8E8F0),
    muted: Color(0xFF8888AA),
    warning: Color(0xFFE8B84A),
    destructive: Color(0xFFE85454),
    success: Color(0xFF2DD4A8),
    chartBlue: Color(0xFF4A8AE8),
  );

  static const light = AppColors(
    background: Color(0xFFF0F0F8),
    card: Color(0xFFE8E8F4),
    sidebar: Color(0xFFE2E2EE),
    surface: Color(0xFFDADAEA),
    border: Color(0xFFCCCCDE),
    primary: Color(0xFF0D8F6F),
    primaryForeground: Color(0xFFFFFFFF),
    foreground: Color(0xFF1A1A2E),
    muted: Color(0xFF5A5A7A),
    warning: Color(0xFFAA6010),
    destructive: Color(0xFFCC2233),
    success: Color(0xFF0D8F6F),
    chartBlue: Color(0xFF2A5AB0),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? card,
    Color? sidebar,
    Color? surface,
    Color? border,
    Color? primary,
    Color? primaryForeground,
    Color? foreground,
    Color? muted,
    Color? warning,
    Color? destructive,
    Color? success,
    Color? chartBlue,
  }) {
    return AppColors(
      background: background ?? this.background,
      card: card ?? this.card,
      sidebar: sidebar ?? this.sidebar,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      foreground: foreground ?? this.foreground,
      muted: muted ?? this.muted,
      warning: warning ?? this.warning,
      destructive: destructive ?? this.destructive,
      success: success ?? this.success,
      chartBlue: chartBlue ?? this.chartBlue,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      border: Color.lerp(border, other.border, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryForeground: Color.lerp(primaryForeground, other.primaryForeground, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      success: Color.lerp(success, other.success, t)!,
      chartBlue: Color.lerp(chartBlue, other.chartBlue, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

class AppTheme {
  static ThemeData get darkTheme => _build(AppColors.dark, Brightness.dark);
  static ThemeData get lightTheme => _build(AppColors.light, Brightness.light);

  static ThemeData _build(AppColors c, Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: c.background,
      fontFamily: 'Segoe UI',
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.primary,
        brightness: brightness,
        primary: c.primary,
        surface: c.card,
        error: c.destructive,
      ),
      extensions: [c],
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: c.border),
        ),
      ),
      dividerColor: c.border,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: c.foreground),
        bodyMedium: TextStyle(color: c.foreground),
        bodySmall: TextStyle(color: c.muted),
        labelSmall: TextStyle(
          color: c.muted,
          fontSize: 10,
          fontFamily: 'Consolas',
          letterSpacing: 1.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.primaryForeground,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.foreground,
          side: BorderSide(color: c.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
