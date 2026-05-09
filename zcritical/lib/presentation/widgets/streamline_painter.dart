// ══════════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=150 | scope=app-presentation | 修改前读 anti-bloat.md
//
// 职责: 风洞烟雾流线 CustomPainter — cos 半波弧形绕行
// 不做什么: 不处理手势或状态，纯绘制
// ══════════════════════════════════════════════════════════════════
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class StreamlinePainter extends CustomPainter {
  final double progress;    // 0..1 循环（飘动相位，由 AnimationController 驱动）
  final double intensity;   // 速度归一化 0..1（控制弯曲深度/尾流强度/亮度）
  final Color color;        // 基础冷色（由 _windColor 传入）
  final Size obstacleSize;  // 数字外接矩形
  final Offset obstacleCenter;

  static const int _streams = 6;
  static const int _segments = 140;
  static const List<double> _phase = [0.0, 1.7, 3.4, 0.9, 2.6, 4.3];
  static const List<double> _freq = [1.0, 0.85, 1.15, 0.95, 1.1, 0.9];

  StreamlinePainter({
    required this.progress,
    required this.intensity,
    required this.color,
    required this.obstacleSize,
    required this.obstacleCenter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (obstacleSize.width <= 0 || obstacleSize.height <= 0) return;

    final obsHw = obstacleSize.width / 2 + 10;
    final obsHh = obstacleSize.height / 2 + 6;
    final obsCx = obstacleCenter.dx;
    final obsCy = obstacleCenter.dy;

    final bandH = h * 0.60;
    final bandTop = obsCy - bandH / 2;
    final bandBot = obsCy + bandH / 2;

    final tick = progress * 240.0;
    final brightness = 0.6 + 0.4 * intensity;
    final flutterAmp = 0.8 + 1.4 * intensity;
    final wakeFactor = _smoothstep(0.35, 1.0, intensity);
    final wrapFactor = _smoothstep(0.03, 0.60, intensity);
    final spread = obsHw * 2.8;

    const innerGap = 8.0;
    const layerStep = 7.0;

    for (int i = 0; i < _streams; i++) {
      final isTop = i < 3;
      final rank = isTop ? (3 - i) : (i - 2);

      final double baseY;
      if (isTop) {
        final frac = (i + 0.5) / 3.0;
        baseY = bandTop + frac * (obsCy - bandTop);
      } else {
        final frac = (i - 3 + 0.5) / 3.0;
        baseY = obsCy + frac * (bandBot - obsCy);
      }

      final targetOffset = innerGap + (rank - 1) * layerStep;
      final targetY = isTop
          ? obsCy - obsHh - targetOffset
          : obsCy + obsHh + targetOffset;

      double peak = targetY - baseY;
      if (isTop && peak > 0) peak = 0;
      if (!isTop && peak < 0) peak = 0;
      peak *= wrapFactor;

      final phase = _phase[i];
      final freq = _freq[i];

      final centerDist = (i - 2.5).abs() / 2.5;
      final lineBright = brightness * (0.6 + 0.4 * (1 - centerDist));
      final warmth = rank == 1 ? _smoothstep(0.55, 1.0, intensity) : 0.0;

      double rC = color.r * 255, gC = color.g * 255, bC = color.b * 255;
      rC = rC + warmth * (255 - rC);
      gC = gC + warmth * (184 - gC);
      bC = bC * (1 - warmth * 0.7);

      final streamColor = Color.fromARGB(
        255,
        (rC * lineBright).clamp(0, 255).toInt(),
        (gC * lineBright).clamp(0, 255).toInt(),
        (bC * lineBright).clamp(0, 255).toInt(),
      );

      final path = Path();
      bool started = false;
      for (int s = 0; s <= _segments; s++) {
        final xNorm = s / _segments;
        final x = xNorm * w;

        double deflect = 0;
        if (peak != 0) {
          final dx = x - obsCx;
          if (dx.abs() < spread) {
            final nx = dx / spread;
            deflect = peak * (1 + math.cos(nx * math.pi)) / 2;
          }
        }

        final fp = xNorm * 5.5 - tick * 0.05 * freq + phase;
        double dy = math.sin(fp * 0.5) * flutterAmp * 0.7 +
            math.sin(fp * 1.2 + phase * 2) * flutterAmp * 0.3;

        if (wakeFactor > 0) {
          final wakeStart = obsCx + obsHw;
          final wakeEnd = wakeStart + obsHw * 3.0;
          if (x > wakeStart && x < wakeEnd) {
            final wp = (x - wakeStart) / (wakeEnd - wakeStart);
            final wEnv = math.sin(wp * math.pi) * wakeFactor * intensity;
            final wAmp = 5.5 * wEnv;
            dy += math.sin(fp * 3.0 + phase * 1.5) * wAmp * 0.45;
            dy += math.sin(fp * 5.5 + phase * 3.0) * wAmp * 0.30;
          }
        }

        final y = baseY + deflect + dy;
        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
      }

      final gradient = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(w, 0),
        [
          streamColor.withValues(alpha: 0.9),
          streamColor,
          streamColor.withValues(alpha: 0.06),
        ],
        const [0.0, 0.28, 1.0],
      );

      // 层 1：柔光外圈
      canvas.drawPath(
        path,
        Paint()
          ..shader = gradient
          ..strokeWidth = 7.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
          ..isAntiAlias = true,
      );

      // 层 2：核心亮线
      canvas.drawPath(
        path,
        Paint()
          ..shader = gradient
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true,
      );
    }
  }

  static double _smoothstep(double edge0, double edge1, double x) {
    if (edge1 <= edge0) return x >= edge1 ? 1.0 : 0.0;
    final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
  }

  @override
  bool shouldRepaint(covariant StreamlinePainter old) =>
      old.progress != progress ||
      old.intensity != intensity ||
      old.color != color ||
      old.obstacleSize != obstacleSize ||
      old.obstacleCenter != obstacleCenter;
}
