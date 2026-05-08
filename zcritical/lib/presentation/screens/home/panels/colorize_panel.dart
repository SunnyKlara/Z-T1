/// 职责：LED 颜色预设选择 — 胶囊条滚动 + 三角指示器 + 开始涂色动画
/// 不做什么：不处理 RGB 调色、不处理 BLE 通信（Phase 2 接入）
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zcritical/data/led_presets.dart';
import 'package:zcritical/presentation/widgets/triangle_indicator_painter.dart';

class ColorizePanel extends StatefulWidget {
  const ColorizePanel({super.key});

  @override
  State<ColorizePanel> createState() => _ColorizePanelState();
}

class _ColorizePanelState extends State<ColorizePanel> {
  int _selectedIndex = 0;
  bool _isSpinning = false;
  double _indicatorOffset = 0.0;
  double _bounceOffset = 0.0;
  double _bounceScale = 1.0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Color get _selectedColor => ledPresets[_selectedIndex].displayColor;

  // ═══════════════════════════════════════════════
  //  Spinning 动画
  // ═══════════════════════════════════════════════

  Future<void> _toggleSpin() async {
    if (_isSpinning) {
      _isSpinning = false;
      setState(() {});
      return;
    }

    _isSpinning = true;
    HapticFeedback.heavyImpact();
    setState(() {});

    final total = ledPresets.length;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxOffset = screenWidth * 0.5;
    int frame = 0;

    while (_isSpinning && mounted) {
      for (int i = 0; i < total; i += 3) {
        if (!_isSpinning || !mounted) return;
        final pos = i.clamp(0, total - 1);
        final progress = pos / (total - 1);
        final offset = maxOffset - progress * maxOffset * 2;
        frame++;
        final bounceY = sin(frame * 0.8) * 25;
        final bounceS = 1.0 + sin(frame * 0.6) * 0.15;

        setState(() {
          _indicatorOffset = offset;
          _bounceOffset = bounceY;
          _bounceScale = bounceS;
          _selectedIndex = pos;
        });

        if (_pageController.hasClients) {
          _pageController.jumpToPage(pos);
        }
        HapticFeedback.selectionClick();
        await Future.delayed(const Duration(milliseconds: 35));
      }

      for (int i = total - 1; i >= 0; i -= 3) {
        if (!_isSpinning || !mounted) return;
        final pos = i.clamp(0, total - 1);
        final progress = pos / (total - 1);
        final offset = maxOffset - progress * maxOffset * 2;
        frame++;
        final bounceY = sin(frame * 0.8) * 25;
        final bounceS = 1.0 + sin(frame * 0.6) * 0.15;

        setState(() {
          _indicatorOffset = offset;
          _bounceOffset = bounceY;
          _bounceScale = bounceS;
          _selectedIndex = pos;
        });

        if (_pageController.hasClients) {
          _pageController.jumpToPage(pos);
        }
        HapticFeedback.selectionClick();
        await Future.delayed(const Duration(milliseconds: 35));
      }
    }

    if (mounted) {
      setState(() {
        _isSpinning = false;
        _indicatorOffset = 0;
        _bounceOffset = 0;
        _bounceScale = 1.0;
      });
    }
  }

  // ═══════════════════════════════════════════════
  //  Build
  // ═══════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final totalW = constraints.maxWidth;

        // 响应式胶囊尺寸
        final capsuleW = totalW < 360 ? 42.0 : (totalW > 428 ? 55.0 : 47.0);
        final capsuleH = h < 700 ? 135.0 : (h > 900 ? 170.0 : 153.0);
        final containerH = h < 700 ? 185.0 : (h > 900 ? 240.0 : 220.0);

        // 三角指示器位置
        final triTopOffset = capsuleH + 35;
        final triLeftPosition = totalW / 2 - 14 + _indicatorOffset;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 三角指示器
            AnimatedPositioned(
              duration: _isSpinning
                  ? const Duration(milliseconds: 30)
                  : const Duration(milliseconds: 150),
              top: (h - containerH) / 2 + triTopOffset - 10,
              left: triLeftPosition,
              child: CustomPaint(
                size: const Size(28, 12),
                painter: TriangleIndicatorPainter(
                  isActive: true,
                  currentColor: _selectedColor,
                ),
              ),
            ),

            // 胶囊条
            Positioned(
              top: (h - containerH) / 2 - 10,
              left: 0,
              right: 0,
              height: capsuleH + 30,
              child: PageView.builder(
                controller: _pageController,
                padEnds: true,
                physics: _isSpinning
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                onPageChanged: (i) {
                  setState(() => _selectedIndex = i);
                  HapticFeedback.selectionClick();
                },
                itemCount: ledPresets.length,
                itemBuilder: (context, index) =>
                    _buildCapsule(index, capsuleW, capsuleH),
              ),
            ),

            // 开始涂色按钮
            Positioned(
              bottom: 16,
              left: 24,
              right: 24,
              child: _StartColoringButton(
                spinning: _isSpinning,
                glowColor: _selectedColor,
                onTap: _toggleSpin,
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════
  //  Capsule Item
  // ═══════════════════════════════════════════════

  Widget _buildCapsule(int index, double capsuleW, double capsuleH) {
    final preset = ledPresets[index];
    final isSolid = preset.isSolid;
    final distance = (index - _selectedIndex).abs();

    double brightness;
    if (distance == 0) {
      brightness = 1.0;
    } else if (distance == 1) {
      brightness = 0.7;
    } else if (distance == 2) {
      brightness = 0.5;
    } else {
      brightness = 0.3;
    }

    final double scale = distance == 0 ? 1.15 : 1.0;
    final radius = capsuleW / 2;
    final margin = 8.0;

    return GestureDetector(
      onTap: () {
        if (distance != 0 && !_isSpinning && _pageController.hasClients) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Center(
        child: Transform.translate(
          offset: Offset(0, _isSpinning ? _bounceOffset : 0),
          child: Transform.scale(
            scale: _isSpinning
                ? (distance == 0 ? _bounceScale * 1.15 : _bounceScale)
                : scale,
            child: Container(
              width: capsuleW,
              height: capsuleH,
              margin: EdgeInsets.symmetric(horizontal: margin),
              decoration: BoxDecoration(
                color: isSolid ? preset.solidColor : null,
                gradient: !isSolid
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: preset.gradientColors!,
                      )
                    : null,
                borderRadius: BorderRadius.circular(radius),
                boxShadow: distance == 0
                    ? [
                        BoxShadow(
                          color: Colors.black.withAlpha(102),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: preset.displayColor.withAlpha(89),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withAlpha(51),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(
                    ((1.0 - brightness) * 255).round(),
                  ),
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  开始涂色按钮 — 代码绘制发光圆角矩形
// ═══════════════════════════════════════════════════════════

class _StartColoringButton extends StatelessWidget {
  final bool spinning;
  final Color glowColor;
  final VoidCallback onTap;

  const _StartColoringButton({
    required this.spinning,
    required this.glowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          color: spinning
              ? glowColor.withAlpha(20)
              : Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: spinning
                ? glowColor.withAlpha(150)
                : Colors.white.withAlpha(30),
            width: 1.5,
          ),
          boxShadow: spinning
              ? [
                  BoxShadow(
                    color: glowColor.withAlpha(60),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: glowColor.withAlpha(30),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            spinning ? '✦ 停止 ✦' : '✦ 开始涂色 ✦',
            style: TextStyle(
              color: spinning ? glowColor : Colors.white.withAlpha(180),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
    );
  }
}
