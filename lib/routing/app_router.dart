import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/free_draw_screen.dart';
import '../screens/start_screen.dart';

/// Centralized route names.
abstract final class AppRoute {
  static const root = '/';
  static const freeDraw = '/free';
  // Future: const coloring = '/coloring';
  // Future: const gallery = '/gallery';
}

/// Builds the application router.
GoRouter createRouter({required GlobalKey<NavigatorState> navigatorKey}) =>
    GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: AppRoute.root,
      routes: [
        GoRoute(
          path: AppRoute.root,
          name: 'start',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: StartScreen(),
          ),
        ),
        GoRoute(
          path: AppRoute.freeDraw,
          name: 'freeDraw',
          pageBuilder: (context, state) => const MaterialPage(
            child: FreeDrawScreen(),
          ),
        ),
      ],
    );
