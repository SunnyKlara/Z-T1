// ══════════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=150 | scope=app-core | 修改前读 anti-bloat.md
//
// 职责: GoRouter 路由配置 — 集中定义所有路径、页面、转场
// 不做什么: 不包含业务逻辑、不处理 BLE 状态判断
// ══════════════════════════════════════════════════════════════════
// 路由守卫（route_guards.dart）后续拆分。

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/home/home_shell.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/splash/onboarding_screen.dart';
import '../../presentation/screens/user_center/user_center_screen.dart';
import '../../presentation/screens/logo/logo_management_screen.dart';

/// 路由路径常量。
abstract final class RoutePaths {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const home = '/';
  static const userCenter = '/user-center';
  static const logo = '/logo';
}

/// 路由列表 — 供 app.dart 构建 GoRouter 使用。
final List<RouteBase> appRouterRoutes = [
  // ── Splash ──
  GoRoute(
    path: RoutePaths.splash,
    pageBuilder: (context, state) => const NoTransitionPage(
      child: SplashScreen(),
    ),
  ),
  // ── Onboarding ──
  GoRoute(
    path: RoutePaths.onboarding,
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child: const OnboardingScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ),
  // ── ShellRoute (HomeShell) ──
  ShellRoute(
    pageBuilder: (context, state, child) => NoTransitionPage(
      child: HomeShell(child: child),
    ),
    routes: [
      GoRoute(
        path: RoutePaths.home,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: HomeScreen(),
        ),
      ),
    ],
  ),
  // ── 用户中心 ──
  GoRoute(
    path: RoutePaths.userCenter,
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child: const UserCenterScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ),
  // ── Logo 管理 ──
  GoRoute(
    path: RoutePaths.logo,
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child: const LogoManagementScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ),
];

/// 全局 GoRouter 实例（备用，如果不需要动态初始位置）。
final appRouter = GoRouter(
  initialLocation: RoutePaths.splash,
  routes: appRouterRoutes,
);
