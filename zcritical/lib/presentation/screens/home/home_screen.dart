// ZCritical 首页
//
// 设计意图：
// - 纯黑背景。无框无界。内容浮在黑色画布上。
// - 上半区：风洞线框模型（CustomPainter），自动旋转。
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
