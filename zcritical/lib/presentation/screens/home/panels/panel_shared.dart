/// 职责：面板共享组件 — 布局容器、环形进度条、模式切换按钮
/// 不做什么：不包含任何面板的具体业务逻辑
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 统一的面板内边距布局容器
class PanelLayout extends StatelessWidget {
  final List<Widget> children;

  const PanelLayout({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );
  }
}

/// 环形进度条（用于 Pace 面板的速度指示）
class SpeedRing extends StatelessWidget {
  final int value;

  const SpeedRing({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: CustomPaint(
        size: const Size(120, 120),
        painter: _RingPainter(
          progress: value / 100.0,
          color: const Color(0xFF00BCD4),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 4;
    const start = -math.pi * 0.75;
    const sweep = math.pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      start, sweep, false,
      Paint()
        ..color = Colors.white.withAlpha(10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      start, sweep * progress, false,
      Paint()
        ..color = color.withAlpha(180)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

/// 模式切换按钮组（用于 Pace 面板）
class ModeButtons extends StatelessWidget {
  final List<String> modes;
  final int active;

  const ModeButtons({super.key, required this.modes, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(modes.length, (i) {
        final isActive = i == active;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: i == modes.length - 1 ? 0 : 12),
          child: _PillChip(
            active: isActive,
            child: _ModeIcon(mode: modes[i]),
          ),
        );
      }),
    );
  }
}

class _PillChip extends StatelessWidget {
  final bool active;
  final Widget child;

  const _PillChip({required this.active, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active
              ? const Color(0xFF00BCD4).withAlpha(100)
              : Colors.white.withAlpha(15),
          width: 1,
        ),
        color: active
            ? const Color(0xFF00BCD4).withAlpha(15)
            : Colors.transparent,
      ),
      child: child,
    );
  }
}

class _ModeIcon extends StatelessWidget {
  final String mode;

  const _ModeIcon({required this.mode});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (mode) {
      case 'walk':
        icon = Icons.directions_walk;
        break;
      case 'jog':
        icon = Icons.directions_run;
        break;
      case 'run':
        icon = Icons.speed;
        break;
      case 'eco':
        icon = Icons.eco;
        break;
      case 'std':
        icon = Icons.tune;
        break;
      case 'sprt':
        icon = Icons.bolt;
        break;
      default:
        icon = Icons.circle;
    }
    return Icon(icon, size: 16, color: Colors.white.withAlpha(120));
  }
}
