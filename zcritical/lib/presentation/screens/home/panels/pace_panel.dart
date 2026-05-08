/// 职责：Pace（跑步机）模式面板 — 中心大数字 + 风洞喷烟绕流 + 手势调速
/// 不做什么：不发送 BLE 命令、不同步外部速度、不管理连接状态
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'panel_shared.dart';
import '../../../widgets/streamline_painter.dart';

class PacePanel extends StatefulWidget {
  const PacePanel({super.key});

  @override
  State<PacePanel> createState() => _PacePanelState();
}

class _PacePanelState extends State<PacePanel> with TickerProviderStateMixin {
  static const int _step = 10;
  static const double _pxPerStep = 8.0;
  static const int _maxSpeed = 999;

  late int _currentSpeed;
  double _dragAccum = 0.0;

  late final AnimationController _flowController;
  final GlobalKey _numberKey = GlobalKey(debugLabel: 'paceNumber');
  Size _numberSize = Size.zero;

  // ── 速度色 ──
  static const Color _windLo = Color(0xFF00A0FF);
  static const Color _windMid = Color(0xFFB4DCFF);
  static const Color _windHi = Color(0xFFFF6428);

  @override
  void initState() {
    super.initState();
    _currentSpeed = 0;
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureNumber());
  }

  @override
  void dispose() {
    _flowController.dispose();
    super.dispose();
  }

  void _measureNumber() {
    final ctx = _numberKey.currentContext;
    if (ctx == null || !mounted) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    if (box.size != _numberSize) setState(() => _numberSize = box.size);
  }

  void _onVerticalDrag(DragUpdateDetails d) {
    _dragAccum -= d.delta.dy;
    while (_dragAccum.abs() >= _pxPerStep) {
      final dir = _dragAccum > 0 ? 1 : -1;
      _dragAccum -= dir * _pxPerStep;
      final next = (_currentSpeed + dir * _step).clamp(0, _maxSpeed);
      if (next == _currentSpeed) continue;
      setState(() => _currentSpeed = next);
      HapticFeedback.selectionClick();
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureNumber());
    }
  }

  void _jumpTo(int speed) {
    setState(() {
      _currentSpeed = speed.clamp(0, _maxSpeed);
      _dragAccum = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureNumber());
  }

  // ── 速度色：lo(蓝) → mid(淡蓝) → hi(橙) ──
  static Color _windColor(double t) {
    t = t.clamp(0.0, 1.0);
    if (t < 0.5) return Color.lerp(_windLo, _windMid, t * 2)!;
    return Color.lerp(_windMid, _windHi, (t - 0.5) * 2)!;
  }

  @override
  Widget build(BuildContext context) {
    final t = _currentSpeed / _maxSpeed;
    final accent = _windColor(t);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: _onVerticalDrag,
      onVerticalDragEnd: (_) => _dragAccum = 0,
      onDoubleTap: () {
        HapticFeedback.heavyImpact();
        setState(() {
          _currentSpeed = 0;
          _dragAccum = 0;
        });
      },
      child: PanelLayout(
        children: [
          // ── 流线 + 数字区域 ──
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, c) {
                final w = c.maxWidth;
                final h = c.maxHeight;
                if (w <= 0 || h <= 0) return const SizedBox.shrink();
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // 烟雾绕流层
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _flowController,
                        builder: (_, __) => CustomPaint(
                          painter: StreamlinePainter(
                            progress: _flowController.value,
                            intensity: t,
                            color: accent,
                            obstacleSize: _numberSize,
                            obstacleCenter: Offset(w / 2, h / 2),
                          ),
                        ),
                      ),
                    ),
                    // 中央大数字
                    _buildNumber(accent, h),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // ── 模式胶囊按钮 ──
          _buildModeButtons(accent),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildNumber(Color accent, double containerHeight) {
    final fontSize = (containerHeight * 0.16).clamp(48.0, 120.0);
    return Text(
      _currentSpeed.toString().padLeft(3, '0'),
      key: _numberKey,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: accent,
        fontSize: fontSize,
        fontFamily: 'Consolas',
        fontWeight: FontWeight.w900,
        height: 1.0,
        letterSpacing: -2,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  Widget _buildModeButtons(Color accent) {
    const modes = [
      _Mode('walk', Icons.directions_walk, 20),
      _Mode('jog', Icons.directions_run, 60),
      _Mode('run', Icons.speed, 90),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: modes.map((m) {
        // 速度最近的算 active
        final active = (_currentSpeed - m.speed).abs() <=
            (modes.map((x) => (_currentSpeed - x.speed).abs()).reduce(math.min));
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _PaceCapsule(
            active: active,
            accent: accent,
            icon: m.icon,
            onTap: () => _jumpTo(m.speed),
          ),
        );
      }).toList(),
    );
  }
}

class _Mode {
  final String label;
  final IconData icon;
  final int speed;
  const _Mode(this.label, this.icon, this.speed);
}

class _PaceCapsule extends StatelessWidget {
  final bool active;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;

  const _PaceCapsule({
    required this.active,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active
                ? accent.withAlpha(160)
                : Colors.white.withAlpha(20),
            width: 1,
          ),
          color: active
              ? accent.withAlpha(25)
              : Colors.transparent,
        ),
        child: Icon(icon, size: 18, color: Colors.white.withAlpha(active ? 200 : 80)),
      ),
    );
  }
}
