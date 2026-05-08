// 面板共享组件
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

    // 背景弧
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      start, sweep, false,
      Paint()
        ..color = Colors.white.withAlpha(10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // 进度弧
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

/// 通用滑条（用于 Pace 和 Colorize 面板）
class FakeSlider extends StatelessWidget {
  final double value;

  const FakeSlider({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 8),
      painter: _SliderPainter(value: value),
    );
  }
}

class _SliderPainter extends CustomPainter {
  final double value;

  _SliderPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;

    // 轨道背景
    canvas.drawRRect(
      RRect.fromLTRBR(0, y - 2, size.width, y + 2, const Radius.circular(2)),
      Paint()..color = Colors.white.withAlpha(12),
    );

    // 填充
    canvas.drawRRect(
      RRect.fromLTRBR(0, y - 2, size.width * value, y + 2, const Radius.circular(2)),
      Paint()..color = Colors.white.withAlpha(25),
    );

    // 滑块
    canvas.drawCircle(
      Offset(size.width * value, y), 3,
      Paint()..color = Colors.white.withAlpha(100),
    );
  }

  @override
  bool shouldRepaint(covariant _SliderPainter old) => old.value != value;
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

/// 当前选中的颜色圆点（用于 Colorize 和 RGB 面板）
class ActiveColorDot extends StatelessWidget {
  final Color color;

  const ActiveColorDot({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withAlpha(180),
        boxShadow: [
          BoxShadow(color: color.withAlpha(60), blurRadius: 24, spreadRadius: 4),
        ],
        border: Border.all(color: Colors.white.withAlpha(30), width: 1),
      ),
    );
  }
}

/// 颜色点行（用于 Colorize 面板）
class ColorDotsRow extends StatelessWidget {
  const ColorDotsRow({super.key});

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFFFF0000), Color(0xFFFF8000), Color(0xFFFFFF00),
      Color(0xFF00FF00), Color(0xFF00FFFF), Color(0xFF0000FF),
      Color(0xFFFF00FF), Color(0xFFFFFFFF), Color(0xFF00BCD4),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: colors.map((c) {
        final sel = c == colors[8];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.withAlpha(100),
              border: sel
                  ? Border.all(color: Colors.white.withAlpha(80), width: 1.5)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// RGB 通道滑条（用于 RGB 面板）
class RgbChannel extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const RgbChannel({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: CustomPaint(
            size: const Size(20, 20),
            painter: _LetterPainter(letter: label),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomPaint(
            size: const Size(double.infinity, 4),
            painter: _SliderPainter(value: value),
          ),
        ),
      ],
    );
  }
}

class _LetterPainter extends CustomPainter {
  final String letter;

  _LetterPainter({required this.letter});

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: Colors.white.withAlpha(50),
          fontSize: 12,
          fontWeight: FontWeight.w300,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _LetterPainter old) => old.letter != letter;
}
