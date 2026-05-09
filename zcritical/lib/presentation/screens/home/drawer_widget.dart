// ══════════════════════════════════════════════════════════════
// STEER: 反臃肿 | scope=app | 修改前读 anti-bloat.md
//
// 职责：App Drawer — 导航菜单，包含设备连接、Logo管理、关于、调试入口
// 不做什么：不处理BLE逻辑、不包含页面内容
// ══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DrawerWidget extends StatefulWidget {
  const DrawerWidget({super.key});

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  int _versionTapCount = 0;

  void _onVersionTap() {
    _versionTapCount++;
    if (_versionTapCount >= 5) {
      _versionTapCount = 0;
      HapticFeedback.heavyImpact();
      Navigator.pop(context);
      Navigator.pushNamed(context, '/debug');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 40),
      children: [
        // ── 头部 ──
        _buildHeader(),
        const SizedBox(height: 32),

        // ── 设 备 ──
        _sectionTitle('设 备'),
        _tile(
          icon: Icons.bluetooth_searching,
          title: '连接设备',
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/scan');
          },
        ),
        _tile(
          icon: Icons.palette_outlined,
          title: 'LED 预设与颜色',
          onTap: () => _comingSoon(context),
        ),
        _tile(
          icon: Icons.graphic_eq,
          title: '音效引擎',
          onTap: () => _comingSoon(context),
        ),
        _tile(
          icon: Icons.image_outlined,
          title: 'Logo 管理',
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/logo');
          },
        ),
        const SizedBox(height: 24),

        // ── 维 护 ──
        _sectionTitle('维 护'),
        _tile(
          icon: Icons.system_update_alt,
          title: '固件升级',
          onTap: () => _comingSoon(context),
        ),
        const SizedBox(height: 24),

        // ── 关 于 ──
        _sectionTitle('关 于'),
        _tile(
          icon: Icons.chat_bubble_outline,
          title: '反馈问题',
          onTap: () => _comingSoon(context),
        ),
        _tile(
          icon: Icons.info_outline,
          title: '关于 ZCritical',
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/about');
          },
        ),
        const SizedBox(height: 32),

        // ── 版本号（开发者模式入口）──
        Center(
          child: GestureDetector(
            onTap: _onVersionTap,
            child: Text(
              'v1.0.0',
              style: TextStyle(
                color: Colors.white.withAlpha(40),
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.only(top: 24, bottom: 8),
      child: Column(children: [
        _BrandCircle(),
        SizedBox(height: 12),
        Text(
          'ZCritical',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '桌面级智能风洞',
          style: TextStyle(color: Color(0x66FFFFFF), fontSize: 12),
        ),
      ]),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withAlpha(100),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0x14FFFFFF), width: 0.5),
            ),
          ),
          child: Row(children: [
            Icon(icon, color: Colors.white.withAlpha(200), size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
            if (trailing != null) ...[
              Text(
                trailing,
                style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 13),
              ),
              const SizedBox(width: 8),
            ],
            Icon(Icons.chevron_right, color: Colors.white.withAlpha(100), size: 20),
          ]),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('该功能即将接入'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// 品牌圆形图标 — 代码绘制
class _BrandCircle extends StatelessWidget {
  const _BrandCircle();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: const Center(
        child: Text(
          'ZC',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
