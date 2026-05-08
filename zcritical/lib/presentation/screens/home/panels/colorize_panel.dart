// Colorize Mode 面板 — LED 预设颜色（占位）
/// 不做什么：不处理 BLE 命令，仅占位 UI
import 'package:flutter/material.dart';
import 'panel_shared.dart';

class ColorizePanel extends StatelessWidget {
  const ColorizePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const PanelLayout(
      children: [
        Spacer(),
        ActiveColorDot(color: Color(0xFF00BCD4)),
        SizedBox(height: 24),
        ColorDotsRow(),
        Spacer(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 80, vertical: 8),
          child: FakeSlider(value: 0.75),
        ),
        SizedBox(height: 8),
      ],
    );
  }
}
