/// 职责：倒三角指示器 CustomPainter — SVG 圆角梯形 + 多层发光
/// 不做什么：不管理状态，不处理交互
import 'package:flutter/material.dart';

class TriangleIndicatorPainter extends CustomPainter {
  final bool isActive;
  final Color currentColor;

  TriangleIndicatorPainter({
    this.isActive = false,
    this.currentColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isActive ? currentColor : Colors.white.withAlpha(77)
      ..style = PaintingStyle.fill;

    final scaleX = size.width / 26.5732421875;
    final scaleY = size.height / 9.5234375;

    final path = Path();
    path.moveTo(14.1659 * scaleX, 0.203846 * scaleY);
    path.lineTo(25.4495 * scaleX, 5.7271 * scaleY);
    path.cubicTo(
      27.3533 * scaleX, 6.65898 * scaleY,
      26.6899 * scaleX, 9.52344 * scaleY,
      24.5702 * scaleX, 9.52344 * scaleY,
    );
    path.lineTo(2.003 * scaleX, 9.52344 * scaleY);
    path.cubicTo(
      -0.116619 * scaleX, 9.52344 * scaleY,
      -0.780075 * scaleX, 6.65898 * scaleY,
      1.1237 * scaleX, 5.7271 * scaleY,
    );
    path.lineTo(12.4073 * scaleX, 0.203846 * scaleY);
    path.cubicTo(
      12.9621 * scaleX, -0.0676997 * scaleY,
      13.6112 * scaleX, -0.0676997 * scaleY,
      14.1659 * scaleX, 0.203846 * scaleY,
    );
    path.close();

    if (isActive) {
      canvas.drawShadow(path, Colors.black.withAlpha(102), 4.0, true);

      final glow1 = Paint()
        ..color = currentColor.withAlpha(102)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, glow1);

      final glow2 = Paint()
        ..color = currentColor.withAlpha(153)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, glow2);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(TriangleIndicatorPainter oldDelegate) {
    return oldDelegate.currentColor != currentColor ||
           oldDelegate.isActive != isActive;
  }
}
