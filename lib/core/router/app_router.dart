import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanc_term/core/theme/sanc_term_theme.dart';
import 'package:sanc_term/features/home/home_screen.dart';
import 'package:sanc_term/features/panels/common/not_found_panel.dart';
import 'package:sanc_term/features/panels/panel_registry.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/home'),
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
              return panelRegistry[id]?.call() ?? NotFoundPanel(panelId: id);
            },
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
