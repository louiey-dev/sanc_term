import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

/// App theme mode, persisted in the `app_settings` Hive box (opened in
/// main.dart before the app starts, so reads here are synchronous).
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() => _parse(Hive.box<String>('app_settings').get(_key));

  void set(ThemeMode mode) {
    state = mode;
    Hive.box<String>('app_settings').put(_key, mode.name);
  }

  void toggle() =>
      set(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  ThemeMode _parse(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      };
}
