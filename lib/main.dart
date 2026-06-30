import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanc_term/core/router/app_router.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/core/theme/theme_provider.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initHive();
  await _initWindow();
  runApp(const ProviderScope(child: SancTermApp()));
}

Future<void> _initHive() async {
  final String hivePath;
  if (Platform.isWindows) {
    final appData =
        Platform.environment['APPDATA'] ?? Directory.systemTemp.path;
    hivePath = '$appData\\sanc_term';
  } else {
    hivePath = (await getApplicationDocumentsDirectory()).path;
  }
  await Directory(hivePath).create(recursive: true);
  Hive.init(hivePath);
  await Hive.openBox<String>('app_settings');
}

Future<void> _initWindow() async {
  if (kIsWeb) return;
  if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;
  try {
    await windowManager.ensureInitialized();
    // WindowOptions windowOptions = WindowOptions(
    //   size: const Size(900, 900),
    //   center: false,
    //   backgroundColor: Colors.transparent,
    //   skipTaskbar: false,
    //   titleBarStyle: TitleBarStyle.normal,
    //   title: 'sanc_term — $_osLabel',
    // );

    // windowManager.waitUntilReadyToShow(windowOptions, () async {
    //   await windowManager.show();
    //   await windowManager.focus();
    // });
    await windowManager.setTitle('sanc_term — $_osLabel');
  } catch (_) {
    // Native plugin not yet compiled — run `flutter build windows` once.
  }
}

String get _osLabel {
  if (kIsWeb) return 'Web';
  return switch (Platform.operatingSystem) {
    'windows' => 'Windows',
    'macos' => 'macOS',
    'linux' => 'Linux',
    'android' => 'Android',
    'ios' => 'iOS',
    _ => Platform.operatingSystem,
  };
}

class SancTermApp extends ConsumerWidget {
  const SancTermApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'sanc_term — $_osLabel',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
