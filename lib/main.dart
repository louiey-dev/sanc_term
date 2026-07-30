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
import 'package:package_info_plus/package_info_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initHive();
  final version = await loadVersion();
  final appTitle = version.isNotEmpty
      ? 'sanc_term v$version — $_osLabel'
      : 'sanc_term — $_osLabel';
  await _initWindow(appTitle);
  runApp(ProviderScope(child: SancTermApp(appTitle: appTitle)));
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
  try {
    await Hive.openBox<String>('app_settings');
  } catch (_) {
    if (!Hive.isBoxOpen('app_settings')) {
      try {
        await Hive.openBox<String>('app_settings', bytes: Uint8List(0));
      } catch (_) {}
    }
  }
}

Future<void> _initWindow(String title) async {
  if (kIsWeb) return;
  if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;
  try {
    await windowManager.ensureInitialized();
    await windowManager.setTitle(title);
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

Future<String> loadVersion() async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final String version = packageInfo.version; // e.g. "1.0.0"
    final String buildNumber = packageInfo.buildNumber; // e.g. "1"
    final String appName = packageInfo.appName;
    final String packageName = packageInfo.packageName;

    debugPrint('$appName $packageName, Version: $version+$buildNumber');
    return '$version+$buildNumber';
  } catch (_) {
    return '';
  }
}

class SancTermApp extends ConsumerWidget {
  final String appTitle;
  const SancTermApp({super.key, this.appTitle = 'sanc_term'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: appTitle,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

