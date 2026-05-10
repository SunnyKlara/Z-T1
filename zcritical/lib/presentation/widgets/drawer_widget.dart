// ══════════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=80 | scope=app-ui | 修改前读 anti-bloat.md
//
// 职责: AppDrawer — 右侧抽屉菜单（品牌区 + 用户中心 + Logo管理）
// 不做什么: 不处理 BLE 通信、不管理用户认证
// ══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  int _versionTaps = 0;
  bool _devUnlocked = false;

  void _onVersionTap() {
    _versionTaps++;
    if (_versionTaps >= 5 && !_devUnlocked) {
      setState(() => _devUnlocked = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('开发者选项已启用'),
          backgroundColor: Color(0xFF00BCD4),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF000000),
      width: 280,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ZCritical',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _onVersionTap,
                    child: const Text(
                      'v1.0.0',
                      style: TextStyle(fontSize: 14, color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 16),
            _DrawerItem(icon: Icons.person_outline, label: '用户中心', onTap: () => _navigate('/user-center')),
            _DrawerItem(icon: Icons.image_outlined, label: 'Logo 管理', onTap: () => _navigate('/logo')),
            if (_devUnlocked) ...[
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 16),
              _DrawerItem(icon: Icons.build_outlined, label: '开发者', onTap: () {}),
            ],
          ],
        ),
      ),
    );
  }

  void _navigate(String route) {
    context.pop();
    context.go(route);
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DrawerItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white54, size: 22),
      title: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 15)),
      onTap: onTap,
      horizontalTitleGap: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      dense: true,
    );
  }
}
