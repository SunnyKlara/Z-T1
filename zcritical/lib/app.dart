// ══════════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=80 | scope=app | 修改前读 anti-bloat.md
//
// 职责: MaterialApp 配置 — 主题、路由、入口流分流 (Splash vs Home)
// 不做什么: 不包含业务逻辑、不注册依赖（由 injection_container 处理）
// ══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class ZCriticalApp extends StatelessWidget {
  const ZCriticalApp({super.key});

  /// 决定初始路由：首次启动 → /splash，否则 → /
  static Future<String> _resolveInitialLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboardingCompleted') ?? false;
    return onboardingCompleted ? RoutePaths.home : RoutePaths.splash;
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: FutureBuilder<String>(
        future: _resolveInitialLocation(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                backgroundColor: Color(0xFF000000),
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          final initialLocation = snapshot.data!;
          final router = GoRouter(
            initialLocation: initialLocation,
            routes: appRouterRoutes,
          );

          return MaterialApp.router(
            title: 'ZCritical',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.system,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
