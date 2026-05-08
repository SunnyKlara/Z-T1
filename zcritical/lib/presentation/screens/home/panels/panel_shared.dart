/// 职责：面板共享组件 — 布局容器
/// 不做什么：不包含任何面板的具体业务逻辑
import 'package:flutter/material.dart';

/// 统一的面板内边距布局容器
class PanelLayout extends StatelessWidget {
  final List<Widget> children;

  const PanelLayout({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );
  }
}
