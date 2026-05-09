// ══════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=100 | scope=app | 修改前读 anti-bloat.md
// ══════════════════════════════════════════════════════════════
// 职责：抽屉菜单 — 品牌区(logo+版本) + 👤用户中心 + 🖼️Logo管理
// 不做什么：不处理导航逻辑细节（由调用方通过 GoRouter 处理）

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';

class DrawerWidget extends StatefulWidget {
  const DrawerWidget({super.key});

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  int _tapCount = 0;

  void _onVersionTap() {
    _tapCount++;
    if (_tapCount >= 5) {
      _tapCount = 0;
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('开发者选项已解锁'), backgroundColor: Color(0xFF00BCD4)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 32),
      // 品牌区
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text('ZCritical', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      ),
      const SizedBox(height: 4),
      GestureDetector(
        onTap: _onVersionTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text('v1.0.0', style: TextStyle(color: Color(0x80FFFFFF), fontSize: 14)),
        ),
      ),
      const SizedBox(height: 40),
      const _Divider(),
      const SizedBox(height: 16),
      // 👤 用户中心
      _Tile(icon: Icons.person_outline, label: '用户中心', onTap: () => _navigate(RoutePaths.userCenter)),
      // 🖼️ Logo 管理
      _Tile(icon: Icons.image_outlined, label: 'Logo管理', onTap: () => _navigate(RoutePaths.logo)),
      const SizedBox(height: 16),
      const _Divider(),
      const Spacer(),
    ]);
  }

  void _navigate(String path) {
    context.pop();
    context.push(path);
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Tile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF00BCD4), size: 24),
        title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        trailing: const Icon(Icons.chevron_right, color: Color(0x80FFFFFF)),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return const Divider(color: Color(0x33FFFFFF), height: 1, indent: 24, endIndent: 24);
  }
}
