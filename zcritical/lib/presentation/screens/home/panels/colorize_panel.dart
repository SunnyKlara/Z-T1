// ══════════════════════════════════════════════════════════════
// STEER: 反臃肿 | scope=app | 修改前读 anti-bloat.md
//
// 职责: Colorize 预设面板 — 多条颜色胶囊水平滚动 + 三角指示器
//       用 ListView 实现多胶囊同时可见（非 PageView 单页显示）
// ══════════════════════════════════════════════════════════════

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
  final ScrollController _scrollController = ScrollController();
  int _selectedIndex = 0;
  bool _isSpinning = false;
  double _bounceScale = 1.0;
  double _bounceOffset = 0.0;

  // ── 响应式参数 ──
  bool get _isSmallScreen =>
      MediaQuery.of(context).size.height < 700 ||
      MediaQuery.of(context).size.width < 375;

  double get _capsuleWidth => _isSmallScreen ? 42.0 : 47.0;
  double get _capsuleHeight => _isSmallScreen ? 135.0 : 153.0;
  double get _capsuleMargin => _isSmallScreen ? 6.0 : 10.0;
  double get _itemWidth => _capsuleWidth + _capsuleMargin * 2;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isSpinning || !_scrollController.hasClients) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final centerOffset = _scrollController.offset + screenWidth / 2 - _itemWidth / 2;
    final index = (centerOffset / _itemWidth).round().clamp(0, ledPresets.length - 1);
    if (index != _selectedIndex) {
      setState(() => _selectedIndex = index);
    }
  }

  Color _selectedColor() {
    final idx = _selectedIndex.clamp(0, ledPresets.length - 1);
    return ledPresets[idx].displayColor;
  }

  /// 将选中的胶囊滚动到屏幕中央
  void _scrollToCenter(int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final targetOffset = index * _itemWidth - screenWidth / 2 + _itemWidth / 2;
    final maxScroll = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, maxScroll),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

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
    int frame = 0;

    while (_isSpinning && mounted) {
      for (int i = 0; i < total; i += 3) {
        if (!_isSpinning || !mounted) return;
        final pos = i.clamp(0, total - 1);
        frame++;
        setState(() {
          _selectedIndex = pos;
          _bounceScale = 1.0 + sin(frame * 0.6) * 0.15;
          _bounceOffset = sin(frame * 0.8) * 25;
        });
        _scrollToCenter(pos);
        HapticFeedback.selectionClick();
        await Future.delayed(const Duration(milliseconds: 35));
      }
      for (int i = total - 1; i >= 0; i -= 3) {
        if (!_isSpinning || !mounted) return;
        final pos = i.clamp(0, total - 1);
        frame++;
        setState(() {
          _selectedIndex = pos;
          _bounceScale = 1.0 + sin(frame * 0.6) * 0.15;
          _bounceOffset = sin(frame * 0.8) * 25;
        });
        _scrollToCenter(pos);
        HapticFeedback.selectionClick();
        await Future.delayed(const Duration(milliseconds: 35));
      }
    }
    _isSpinning = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return LayoutBuilder(
      builder: (context, c) {
        final totalH = c.maxHeight;
        final btnH = 90.0;
        final availH = totalH - btnH;
        final capsuleAreaTop = ((availH - _capsuleHeight - 50) / 2).clamp(0.0, availH);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ── 颜色胶囊 ListView（多条同时可见）──
            Positioned(
              top: capsuleAreaTop,
              left: 0, right: 0,
              height: _capsuleHeight + 40,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: _isSpinning
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth / 2 - _itemWidth / 2,
                ),
                itemCount: ledPresets.length,
                itemBuilder: (ctx, i) => _buildCapsule(i),
              ),
            ),
            // ── 三角指示器（固定在屏幕中央下方）──
            Positioned(
              top: capsuleAreaTop + _capsuleHeight + 35,
              left: screenWidth / 2 - 14,
              child: SizedBox(
                width: 28, height: 12,
                child: CustomPaint(
                  painter: TriangleIndicatorPainter(
                    isActive: true,
                    currentColor: _selectedColor(),
                  ),
                ),
              ),
            ),
            // ── 底部按钮 ──
            Positioned(
              left: _isSmallScreen ? 15 : 20,
              right: _isSmallScreen ? 10 : 15,
              bottom: 6,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _toggleSpin,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0x14FFFFFF),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withAlpha(25)),
                        ),
                        child: Center(
                          child: Text(
                            _isSpinning ? '点击停止' : '开始涂色',
                            style: TextStyle(
                              color: Colors.white.withAlpha(200),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: _isSmallScreen ? 6 : 8),
                  GestureDetector(
                    onTap: () => HapticFeedback.mediumImpact(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0x14FFFFFF),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withAlpha(25)),
                      ),
                      child: const Icon(Icons.palette_outlined,
                          color: Color(0xCCFFFFFF), size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCapsule(int index) {
    final preset = ledPresets[index];
    final distance = (index - _selectedIndex).abs();
    final brightness = distance == 0
        ? 1.0
        : (distance == 1 ? 0.7 : (distance == 2 ? 0.5 : 0.3));
    final scale = distance == 0 ? 1.15 : 1.0;

    return GestureDetector(
      onTap: () {
        if (!_isSpinning) {
          setState(() => _selectedIndex = index);
          _scrollToCenter(index);
          HapticFeedback.selectionClick();
        }
      },
      child: Center(
        child: Transform.translate(
          offset: Offset(
            0,
            _isSpinning ? (distance == 0 ? _bounceOffset : 0) : 0,
          ),
          child: Transform.scale(
            scale: _isSpinning
                ? (distance == 0 ? _bounceScale * 1.15 : _bounceScale)
                : scale,
            child: Container(
              width: _capsuleWidth,
              height: _capsuleHeight,
              margin: EdgeInsets.symmetric(horizontal: _capsuleMargin),
              decoration: BoxDecoration(
                color: preset.isSolid ? preset.solidColor : null,
                gradient: !preset.isSolid && preset.gradientColors != null
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: preset.gradientColors!,
                      )
                    : null,
                borderRadius: BorderRadius.circular(_capsuleWidth / 2),
                boxShadow: distance == 0
                    ? [
                        BoxShadow(
                          color: Colors.black.withAlpha(102),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: _selectedColor().withAlpha(80),
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
                  color: Colors.black.withAlpha(((1.0 - brightness) * 255).round()),
                  borderRadius: BorderRadius.circular(_capsuleWidth / 2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
