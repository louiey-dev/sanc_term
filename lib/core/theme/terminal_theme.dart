import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';

/// Builds an xterm [TerminalTheme] from the app palette so terminal text stays
/// readable in both themes. The key fix over xterm's default (light-grey
/// foreground) is using [AppColors.foreground], which is dark in light mode.
///
/// The ANSI 16-colour palette is also tuned per brightness: light mode uses
/// darker, higher-contrast variants so coloured output isn't washed out on the
/// white background.
TerminalTheme buildTerminalTheme(AppColors c, Brightness brightness) {
  final isLight = brightness == Brightness.light;
  return TerminalTheme(
    cursor: c.primary,
    selection: c.primary.withValues(alpha: 0.30),
    foreground: c.foreground,
    background: c.card, // not painted at backgroundOpacity 0, but required
    black: isLight ? const Color(0xFF2E2E2E) : const Color(0xFF000000),
    red: isLight ? const Color(0xFFC72E2E) : const Color(0xFFCD3131),
    green: isLight ? const Color(0xFF0B8A3E) : const Color(0xFF0DBC79),
    yellow: isLight ? const Color(0xFF8A6D0B) : const Color(0xFFE5E510),
    blue: isLight ? const Color(0xFF1C5DD8) : const Color(0xFF2472C8),
    magenta: isLight ? const Color(0xFFA021A0) : const Color(0xFFBC3FBC),
    cyan: isLight ? const Color(0xFF0A7E8C) : const Color(0xFF11A8CD),
    white: isLight ? const Color(0xFF2E2E2E) : const Color(0xFFE5E5E5),
    brightBlack: isLight ? const Color(0xFF6A6A6A) : const Color(0xFF666666),
    brightRed: const Color(0xFFF14C4C),
    brightGreen: const Color(0xFF23D18B),
    brightYellow: isLight ? const Color(0xFF9A7A0A) : const Color(0xFFF5F543),
    brightBlue: const Color(0xFF3B8EEA),
    brightMagenta: const Color(0xFFD670D6),
    brightCyan: const Color(0xFF29B8DB),
    brightWhite: isLight ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF),
    searchHitBackground: c.warning,
    searchHitBackgroundCurrent: c.primary,
    searchHitForeground: c.primaryForeground,
  );
}
