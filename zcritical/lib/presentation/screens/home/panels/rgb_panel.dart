// RGB Mode 面板 — 自定义 RGB（占位）
/// 不做什么：不处理 BLE 命令，仅占位 UI
import 'package:flutter/material.dart';
import 'panel_shared.dart';

class RgbPanel extends StatelessWidget {
  const RgbPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const PanelLayout(
      children: [
        Spacer(),
        ActiveColorDot(color: Color(0xFF3A7BD5)),
        SizedBox(height: 24),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            children: [
              RgbChannel(label: 'R', value: 0.23, color: Color(0xFFE53935)),
              SizedBox(height: 8),
              RgbChannel(label: 'G', value: 0.48, color: Color(0xFF43A047)),
              SizedBox(height: 8),
              RgbChannel(label: 'B', value: 0.84, color: Color(0xFF1E88E5)),
            ],
          ),
        ),
        Spacer(),
      ],
    );
  }
}
