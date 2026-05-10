// ══════════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=50 | scope=app-presentation | 修改前读 anti-bloat.md
//
// 职责: 首页下半部分 PageView 入口 — 4 个面板水平滑动
// 不做什么: 不包含任何面板的具体实现
// ══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'panels/pace_panel.dart';
import 'panels/running_panel.dart';
import 'panels/colorize_panel.dart';
import 'panels/rgb_panel.dart';

class HomePageView extends StatefulWidget {
  const HomePageView({super.key});

  @override
  State<HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<HomePageView> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _controller,
      physics: const BouncingScrollPhysics(),
      children: const [
        PacePanel(),
        RunningPanel(),
        ColorizePanel(),
        RgbPanel(),
      ],
    );
  }
}
