// ══════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=100 | scope=app | 修改前读 anti-bloat.md
// ══════════════════════════════════════════════════════════════
// 职责：GoRouter ShellRoute body — Stack 叠加主内容 + ☰ 按钮 + Drawer
// 不做什么：不实现 Drawer 内部内容、不处理 BLE 状态

import 'package:flutter/material.dart';
import 'drawer_widget.dart';

class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(children: [
        child,
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 16,
          child: _MenuButton(onTap: () => Scaffold.of(context).openEndDrawer()),
        ),
      ]),
      endDrawer: const Drawer(
        backgroundColor: Color(0xFF000000),
        width: 280,
        child: SafeArea(child: DrawerWidget()),
      ),
    );
  }
}

/// ☰ 按钮：56×56 白色半透明圆形
class _MenuButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MenuButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56, height: 56,
        decoration: const BoxDecoration(color: Color(0x33FFFFFF), shape: BoxShape.circle),
        child: const Icon(Icons.menu, color: Colors.white),
      ),
    );
  }
}
