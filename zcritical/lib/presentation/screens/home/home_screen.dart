// ══════════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=200 | scope=app-presentation | 修改前读 anti-bloat.md
//
// 职责: 首页 — 纯黑背景 + 风洞线框模型(CustomPainter) + PageView 面板
// 不做什么: 不包含面板实现（每个面板独立文件）
// ══════════════════════════════════════════════════════════════════
// - 下半区：4 个控制面板，PageView 左右滑动。
// - 所有 UI 为代码绘制，无极简之外的装饰。

import 'package:flutter/material.dart';

import 'home_page_view.dart';
import '../../widgets/wind_tunnel_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: WindTunnelView(),
            ),
            Expanded(
              flex: 1,
              child: HomePageView(),
            ),
          ],
        ),
      ),
    );
  }
}
