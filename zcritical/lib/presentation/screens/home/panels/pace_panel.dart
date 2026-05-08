// Pace Mode 面板 — 跑步机控制（占位）
/// 不做什么：不处理 BLE 命令，仅占位 UI
import 'package:flutter/material.dart';
import 'panel_shared.dart';

class PacePanel extends StatelessWidget {
  const PacePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const PanelLayout(
      children: [
        SpeedRing(value: 65),
        SizedBox(height: 16),
        FakeSlider(value: 0.65),
        SizedBox(height: 12),
        ModeButtons(modes: ['walk', 'jog', 'run'], active: 1),
      ],
    );
  }
}
