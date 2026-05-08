// ZCritical App 配置
// 职责: MaterialApp 配置——主题、路由、国际化、Riverpod ProviderScope。
// 设计意图: 从 main.dart 分离。集中管理所有顶层配置，main() 只做初始化。

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
