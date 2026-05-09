// ══════════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=150 | scope=app-core | 修改前读 anti-bloat.md
//
// 职责: GoRouter 路由配置 — 集中定义所有路径、页面、转场
// 不做什么: 不包含业务逻辑、不处理 BLE 状态判断
// ══════════════════════════════════════════════════════════════════
//
// 不做什么：
// - 不定义路由守卫（route_guards.dart 后续拆分）。

import 'package:go_router/go_router.dart';

import '../../presentation/screens/home/home_screen.dart';

/// 路由路径常量。
abstract final class RoutePaths {
  static const home = '/';
}

/// 全局 GoRouter 实例。
final appRouter = GoRouter(
  initialLocation: RoutePaths.home,
  routes: [
    GoRoute(
      path: RoutePaths.home,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: HomeScreen(),
      ),
    ),
  ],
);
