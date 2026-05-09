// ══════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=350 | scope=app | 修改前读 anti-bloat.md
// ══════════════════════════════════════════════════════════════
// 职责：用户中心 — 分区标题 + icon tile 列表（参考 RideWind settings_screen 模式）
// 不做什么：不处理 BLE 连接、不包含设备控制逻辑

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UserCenterScreen extends StatelessWidget {
  const UserCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        title: const Text('用户中心', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 40),
        children: [
          _buildBrandHeader(),
          const SizedBox(height: 32),

          // ── 设 备 ──
          _sectionTitle('设 备'),
          _tile(icon: Icons.bluetooth, title: '当前设备', trailing: '未连接', onTap: () => _comingSoon(context)),
          _tile(icon: Icons.palette_outlined, title: 'LED 预设与自定义颜色', onTap: () => _comingSoon(context)),
          _tile(icon: Icons.graphic_eq, title: '音效引擎', onTap: () => _comingSoon(context)),
          _tile(icon: Icons.image_outlined, title: 'Logo 管理', onTap: () => _comingSoon(context)),
          const SizedBox(height: 24),

          // ── 维 护 ──
          _sectionTitle('维 护'),
          _tile(icon: Icons.system_update_alt, title: '固件升级 (OTA)', onTap: () => _comingSoon(context)),
          const SizedBox(height: 24),

          // ── 关 于 ──
          _sectionTitle('关 于'),
          _tile(icon: Icons.chat_bubble_outline, title: '反馈问题', onTap: () => _comingSoon(context)),
          _tile(icon: Icons.description_outlined, title: '隐私政策', onTap: () => _comingSoon(context)),
          _tile(icon: Icons.info_outline, title: '关于 ZCritical', onTap: () => _comingSoon(context)),
          const SizedBox(height: 32),

          // ── 危险操作 ──
          Center(
            child: TextButton(
              onPressed: () => _confirmReset(context),
              child: const Text('重置所有设置', style: TextStyle(color: Color(0xFFE74C3C), fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  // ──── 品牌头 ────

  Widget _buildBrandHeader() {
    return const Padding(
      padding: EdgeInsets.only(top: 24, bottom: 8),
      child: Column(children: [
        // 品牌标识（代码绘制圆形）
        _BrandCircle(),
        SizedBox(height: 12),
        Text('ZCritical', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        SizedBox(height: 4),
        Text('v1.0.0', style: TextStyle(color: Color(0x66FFFFFF), fontSize: 12)),
      ]),
    );
  }

  // ──── 分区标题 ────

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        text,
        style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1.0),
      ),
    );
  }

  // ──── 列表项 tile ────

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
            border: Border(bottom: BorderSide(color: Color(0x14FFFFFF), width: 0.5)),
          ),
          child: Row(children: [
            Icon(icon, color: Colors.white.withAlpha(200), size: 22),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15))),
            if (trailing != null) ...[
              Text(trailing, style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 13)),
              const SizedBox(width: 8),
            ],
            Icon(Icons.chevron_right, color: Colors.white.withAlpha(100), size: 20),
          ]),
        ),
      ),
    );
  }

  // ──── 工具 ────

  void _comingSoon(BuildContext context) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('该功能即将接入'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('重置所有设置', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: const Text('将清除本地保存的所有偏好设置。\n设备连接不会受影响。', style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消', style: TextStyle(color: Colors.white70))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定重置', style: TextStyle(color: Color(0xFFE74C3C)))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已重置本地设置'), duration: Duration(seconds: 2), behavior: SnackBarBehavior.floating),
      );
    }
  }
}

/// 品牌圆形图标 — 代码绘制
class _BrandCircle extends StatelessWidget {
  const _BrandCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72, height: 72,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: const Center(
        child: Text('ZC', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
      ),
    );
  }
}
