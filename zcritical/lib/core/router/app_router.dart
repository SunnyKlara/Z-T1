// ZCritical 路由配置
//
// 设计意图：
// - 使用 GoRouter 管理所有路由。集中定义路径、页面、转场动画。
// - 每个 Screen 对应一条路由。路径使用常量。
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
