// ══════════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=150 | scope=app-core | 修改前读 anti-bloat.md
//
// 职责: GoRouter 路由配置
// 不做什么: 不包含业务逻辑
// ══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/scan/device_scan_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/about/about_screen.dart';
import '../../presentation/screens/debug/debug_screen.dart';
import '../../presentation/screens/user_center/user_center_screen.dart';

abstract final class RoutePaths {
  static const splash = '/splash';
  static const home = '/home';
  static const about = '/about';
  static const debug = '/debug';
  static const userCenter = '/user-center';
  static const logo = '/logo';
}

final appRouter = GoRouter(
  initialLocation: RoutePaths.splash,
  routes: [
    GoRoute(
      path: RoutePaths.splash,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: DeviceScanScreen(),
      ),
    ),
    GoRoute(
      path: RoutePaths.home,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: HomeScreen(),
      ),
    ),
    GoRoute(
      path: RoutePaths.about,
      pageBuilder: (context, state) => _slideIn(const AboutScreen()),
    ),
    GoRoute(
      path: RoutePaths.debug,
      pageBuilder: (context, state) => _slideIn(const DebugScreen()),
    ),
    GoRoute(
      path: RoutePaths.userCenter,
      pageBuilder: (context, state) => _slideIn(const UserCenterScreen()),
    ),
  ],
);

CustomTransitionPage<void> _slideIn(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}
