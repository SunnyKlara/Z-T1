// ══════════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=80 | scope=app | 修改前读 anti-bloat.md
//
// 职责: MaterialApp 配置 — 主题、路由、国际化、Riverpod ProviderScope
// 不做什么: 不包含业务逻辑、不注册依赖（由 injection_container 处理）
// ══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class ZCriticalApp extends StatelessWidget {
  const ZCriticalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'ZCritical',
        debugShowCheckedModeBanner: false,

        // 主题
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,

        // 路由
        routerConfig: appRouter,
      ),
    );
  }
}
