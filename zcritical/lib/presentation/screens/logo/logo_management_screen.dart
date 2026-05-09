// ══════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=250 | scope=app | 修改前读 anti-bloat.md
// ══════════════════════════════════════════════════════════════
// 职责：Logo 管理 — Logo 槽位状态展示 + 上传引导
// 不做什么：不处理 BLE 传输、不处理图片处理（待 A3+ 阶段绑定）

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LogoManagementScreen extends StatelessWidget {
  const LogoManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        title: const Text('Logo 管理', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 16),
          // ── 当前 Logo 预览区 ──
          _buildLogoPreview(),
          const SizedBox(height: 32),
          // ── 信息区 ──
          _buildInfoSection(),
          const SizedBox(height: 32),
          // ── 操作按钮 ──
          _buildActionButton(context),
          const SizedBox(height: 24),
          // ── 说明 ──
          _buildInstructions(),
        ],
      ),
    );
  }

  Widget _buildLogoPreview() {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(30), width: 1),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.image_outlined, size: 48, color: Colors.white.withAlpha(80)),
          const SizedBox(height: 12),
          Text('暂无自定义 Logo', style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 14)),
          const SizedBox(height: 4),
          Text('240 × 240', style: TextStyle(color: Colors.white.withAlpha(60), fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _InfoRow(label: '格式要求', value: 'RGB565 位图'),
        SizedBox(height: 8),
        _InfoRow(label: '分辨率', value: '240 × 240 像素'),
        SizedBox(height: 8),
        _InfoRow(label: '文件大小', value: '115,200 字节'),
        SizedBox(height: 8),
        _InfoRow(label: '当前槽位', value: '空'),
      ]),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo 上传功能即将接入'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating),
        );
      },
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF00BCD4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('选择并上传 Logo', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Text(
      '上传前请确保设备已连接。\n\n上传过程中请勿关闭应用或断开设备连接。\n上传完成后 Logo 将自动显示在设备屏幕上。',
      style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 13, height: 1.5),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 14)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
    ]);
  }
}
