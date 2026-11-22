import 'package:material_ui/material_ui.dart';

import 'package:go_router/go_router.dart';
import 'package:melodix/core/config/routing/routes.dart';
import 'package:melodix/features/choose_mode_screen/presentation/choose_mode_screen.dart';
import 'package:melodix/features/get_start_screen/presentation/get_start_screen.dart';
import 'package:melodix/features/navigation/presentation/pages/main_nav_shell.dart';
import 'package:melodix/features/splash /presentation/splash_screen.dart';

class AppRoute {
  AppRoute._();

  static CustomTransitionPage<void> _buildPageWithTransition({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  static final GoRouter router = GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: Routes.splash,
        name: Routes.splash,
        pageBuilder: (context, state) {
          return _buildPageWithTransition(
            key: state.pageKey,
            child: const SplashScreen(),
          );
        },
      ),
      GoRoute(
        path: Routes.getStartScreen,
        name: Routes.getStartScreen,
        pageBuilder: (context, state) {
          return _buildPageWithTransition(
            key: state.pageKey,
            child: const GetStartScreen(),
          );
        },
      ),

      GoRoute(
        path: Routes.chooseModeScreen,
        name: Routes.chooseModeScreen,
        pageBuilder: (context, state) {
          return _buildPageWithTransition(
            key: state.pageKey,
            child: const ChooseModeScreen(),
          );
        },
      ),

      GoRoute(
        path: Routes.homeScreen,
        name: Routes.homeScreen,
        pageBuilder: (context, state) {
          return _buildPageWithTransition(
            key: state.pageKey,
            child: const MainNavShell(),
          );
        },
      ),
    ],
  );
}
