/// 职责：垂直亮度滑条 — 圆形底 + 太阳图标 + 拖动调亮度
/// 不做什么：不管理亮度状态，由调用方传入和回调
import 'package:flutter/material.dart';

class VerticalBrightnessBar extends StatelessWidget {
  final double brightness;
  final ValueChanged<double> onChanged;

  const VerticalBrightnessBar({
    super.key,
    required this.brightness,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final fillH = h * brightness;

        return GestureDetector(
          onVerticalDragUpdate: (details) {
            final newVal = (brightness - details.delta.dy / 200).clamp(0.0, 1.0);
            onChanged(newVal);
          },
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A).withAlpha(230),
              borderRadius: BorderRadius.circular(w / 2),
              border: Border.all(
                color: Colors.white.withAlpha(20),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(153),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
                if (brightness > 0.5)
                  BoxShadow(
                    color: Colors.white.withAlpha(
                      ((brightness - 0.5) * 0.4 * 255).round(),
                    ),
                    blurRadius: 20 * brightness,
                    spreadRadius: 2 * brightness,
                  ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // 亮度填充
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: fillH,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.white,
                          Colors.white.withAlpha(217),
                        ],
                      ),
                    ),
                  ),
                ),
                // 太阳图标
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (brightness > 0.5)
                          Container(
                            width: 28 + (brightness * 12),
                            height: 28 + (brightness * 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.amber.withAlpha(
                                    ((brightness - 0.5) * 0.5 * 255).round(),
                                  ),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        Transform.scale(
                          scale: 0.85 + (brightness * 0.35),
                          child: Icon(
                            brightness > 0.5
                                ? Icons.wb_sunny
                                : Icons.wb_sunny_outlined,
                            color: brightness > 0.6
                                ? Colors.amber
                                : brightness > 0.3
                                    ? Colors.white
                                    : Colors.white.withAlpha(128),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
