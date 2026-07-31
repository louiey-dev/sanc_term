import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/features/home/home_screen.dart';
import 'package:sanc_term/features/home/widgets/menu_sidebar.dart';
import 'package:sanc_term/features/panels/common/not_found_panel.dart';
import 'package:sanc_term/features/panels/panel_registry.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final box = Hive.box<String>('app_settings');
  var lastRoute = box.get('last_route', defaultValue: '/home') ?? '/home';
  final isUnlocked = ref.watch(secretPanelsUnlockedProvider);

  // If lastRoute points to a hidden panel and secret panels are locked, reset initial location to /home
  if (lastRoute.startsWith('/home/panel/')) {
    final panelId = lastRoute.substring('/home/panel/'.length);
    if (isPanelHidden(panelId) && !isUnlocked) {
      lastRoute = '/home';
    }
  }

  final router = GoRouter(
    initialLocation: lastRoute,
    routes: [
      GoRoute(path: '/', redirect: (_, __) => lastRoute),
      ShellRoute(
        builder: (ctx, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (ctx, state) => Center(
              child: Text(
                'Select a panel',
                style: TextStyle(color: ctx.colors.muted),
              ),
            ),
          ),
          GoRoute(
            path: '/home/panel/:panelId',
            builder: (ctx, state) {
              final id = state.pathParameters['panelId']!;
              final isUnlocked = ref.watch(secretPanelsUnlockedProvider);
              if (isPanelHidden(id) && !isUnlocked) {
                return Center(
                  child: Text(
                    'Select a panel',
                    style: TextStyle(color: ctx.colors.muted),
                  ),
                );
              }
              return panelRegistry[id]?.call() ?? NotFoundPanel(panelId: id);
            },
          ),
        ],
      ),
    ],
  );

  // Persist the route when it actually changes. The delegate notifies on every
  // rebuild, so skip the write when the location is unchanged.
  var lastPersisted = lastRoute;
  router.routerDelegate.addListener(() {
    final uriStr = router.routerDelegate.currentConfiguration.uri.toString();
    if (uriStr.startsWith('/home') && uriStr != lastPersisted) {
      lastPersisted = uriStr;
      box.put('last_route', uriStr);
    }
  });

  ref.onDispose(router.dispose);
  return router;
}
