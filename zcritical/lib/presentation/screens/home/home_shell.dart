// ══════════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=80 | scope=app-ui | 修改前读 anti-bloat.md
//
// 职责: HomeShell — GoRouter ShellRoute 容器，Stack(子页面 + ☰按钮) + Drawer
// 不做什么: 不处理 BLE 连接逻辑（A3 接入）、不管理面板内容
// ══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../widgets/drawer_widget.dart';

class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      endDrawer: const AppDrawer(),
      body: Stack(
        children: [
          child,
          Positioned(
            top: 16,
            right: 16,
            child: Material(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(28),
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () => Scaffold.of(context).openEndDrawer(),
                child: const SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(Icons.menu, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 40,
              color: const Color(0x33FF0000),
              alignment: Alignment.center,
              child: const Text(
                '未连接设备 — 点击连接',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
