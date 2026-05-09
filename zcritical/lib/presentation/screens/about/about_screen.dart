// ══════════════════════════════════════════════════════════════
// STEER: 反臃肿 | scope=app | 修改前读 anti-bloat.md
//
// 职责：关于页 — 版本信息展示 + 开发者模式入口（版本号点5次）
// 不做什么：不实现调试功能（由debug_screen负责）
// ══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  int _versionTapCount = 0;

  void _onVersionTap() {
    _versionTapCount++;
    if (_versionTapCount >= 5) {
      _versionTapCount = 0;
      HapticFeedback.heavyImpact();
      Navigator.pushNamed(context, '/debug');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        title: const Text(
          '关于 ZCritical',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 40),
        children: [
          // ── 品牌图 ──
          _buildBrandHero(),
          const SizedBox(height: 48),

          // ── 基本信息 ──
          _sectionTitle('基本信息'),
          _infoTile('产品名称', 'ZCritical T1'),
          _infoTile('产品类型', '桌面级智能风洞'),
          _infoTile('连接方式', 'Bluetooth Low Energy'),
          const SizedBox(height: 24),

          // ── 版本信息 ──
          _sectionTitle('版本信息'),
          GestureDetector(
            onTap: _onVersionTap,
            child: _infoTile('App 版本', 'v1.0.0'),
          ),
          _infoTile('固件版本', '—'),
          _infoTile('协议版本', '1.0'),
          const SizedBox(height: 24),

          // ── 技术规格 ──
          _sectionTitle('技术规格'),
          _infoTile('主控', 'ESP32-S3'),
          _infoTile('LED', 'WS2812B × 9颗'),
          _infoTile('LCD', 'GC9A01 240×240'),
          _infoTile('编码器', 'EC11'),
          _infoTile('音频', 'MAX98357 I2S'),
          const SizedBox(height: 24),

          // ── 法律信息 ──
          _sectionTitle('法律信息'),
          _tile(
            icon: Icons.description_outlined,
            title: '隐私政策',
            onTap: () => _comingSoon(context),
          ),
          _tile(
            icon: Icons.gavel_outlined,
            title: '用户协议',
            onTap: () => _comingSoon(context),
          ),
          _tile(
            icon: Icons.source_outlined,
            title: '开源许可',
            onTap: () => _comingSoon(context),
          ),
          const SizedBox(height: 48),

          // ── 版权 ──
          Center(
            child: Text(
              '© 2026 ZCritical. All rights reserved.',
              style: TextStyle(
                color: Colors.white.withAlpha(40),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBrandHero() {
    return const Column(
      children: [
        // 品牌圆形图标
        _BrandCircle(),
        SizedBox(height: 16),
        Text(
          'ZCritical',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '驾驭风的力量',
          style: TextStyle(
            color: Color(0x99FFFFFF),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
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

  Widget _infoTile(String label, String value) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0x14FFFFFF), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 15,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF00BCD4),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0x14FFFFFF), width: 0.5),
            ),
          ),
          child: Row(children: [
            Icon(icon, color: Colors.white.withAlpha(200), size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withAlpha(80), size: 20),
          ]),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('即将推出'),
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
      width: 80,
      height: 80,
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
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
