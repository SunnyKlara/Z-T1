// Running Mode 面板 — 风扇速度数字滚轮 + 紧急停止 + 油门按钮
import 'package:flutter/material.dart';

class RunningPanel extends StatefulWidget {
  const RunningPanel({super.key});

  @override
  State<RunningPanel> createState() => _RunningPanelState();
}

class _RunningPanelState extends State<RunningPanel> {
  int _speed = 42;
  late final FixedExtentScrollController _scroll;
  bool _isThrottling = false;

  @override
  void initState() {
    super.initState();
    _scroll = FixedExtentScrollController(initialItem: _speed);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _emergencyStop() {
    if (_speed == 0) return;
    final current = _speed;
    _speed = 0;
    if (_scroll.hasClients) {
      _scroll.animateToItem(
        0,
        duration: Duration(milliseconds: (current * 2).clamp(200, 800)),
        curve: Curves.easeOut,
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        const btnAreaH = 100.0;
        final wheelAvail = (h - btnAreaH).clamp(200.0, h);
        final itemExtent = (wheelAvail / 5).clamp(45.0, 85.0);
        final wheelHeight = itemExtent * 5;

        return Stack(
          children: [
            // 数字滚轮
            Positioned(
              top: (h - wheelHeight) / 2 - btnAreaH * 0.3,
              left: 0,
              right: 0,
              height: wheelHeight + itemExtent * 0.3,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  ListWheelScrollView.useDelegate(
                    controller: _scroll,
                    itemExtent: itemExtent,
                    diameterRatio: 1.4,
                    perspective: 0.006,
                    physics: const BouncingScrollPhysics(
                      parent: FixedExtentScrollPhysics(),
                    ),
                    onSelectedItemChanged: (i) {
                      setState(() => _speed = i);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        if (index < 0 || index > 340) return null;
                        return _SpeedItem(
                          speed: index,
                          currentSpeed: _speed,
                          itemExtent: itemExtent,
                        );
                      },
                      childCount: 341,
                    ),
                  ),
                  // 顶部渐变遮罩
                  Positioned(
                    top: 0, left: 0, right: 0,
                    height: itemExtent * 0.6,
                    child: IgnorePointer(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF000000), Color(0x00000000)],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 底部渐变遮罩
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    height: itemExtent * 0.6,
                    child: IgnorePointer(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0xFF000000), Color(0x00000000)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 底部按钮区
            Positioned(
              bottom: 8,
              left: 16,
              right: 16,
              height: btnAreaH,
              child: _RunningButtons(
                throttling: _isThrottling,
                onStop: _emergencyStop,
                onThrottleStart: () => setState(() => _isThrottling = true),
                onThrottleEnd: () => setState(() => _isThrottling = false),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 单个速度项：左侧刻度 + 中间数字 + km/h 单位
/// 设计参考 RideWind iOS 闹钟风格滚轮
class _SpeedItem extends StatelessWidget {
  final int speed;
  final int currentSpeed;
  final double itemExtent;

  const _SpeedItem({
    required this.speed,
    required this.currentSpeed,
    required this.itemExtent,
  });

  bool get isCurrent => speed == currentSpeed;

  // 距离当前速度的渐变透明度
  double get _opacity {
    final d = (speed - currentSpeed).abs();
    if (d == 0) return 1.0;
    if (d == 1) return 0.7;
    if (d == 2) return 0.4;
    return 0.2;
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = isCurrent
        ? (itemExtent * 1.1).clamp(65.0, 100.0)
        : (itemExtent * 0.5).clamp(32.0, 50.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 左侧刻度指示器
        SizedBox(
          width: 40,
          child: Center(child: _buildIndicator()),
        ),
        const SizedBox(width: 8),
        // 数字
        Text(
          speed.toString().padLeft(2, '0'),
          style: TextStyle(
            color: isCurrent
                ? Colors.white
                : const Color(0xFFC94A4A).withAlpha((_opacity * 0.7 * 255).round()),
            fontSize: fontSize,
            fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w800,
            letterSpacing: isCurrent ? 4 : 2,
            height: 1.0,
            shadows: isCurrent
                ? [
                    const Shadow(color: Colors.black, offset: Offset(0, 4), blurRadius: 8),
                    Shadow(color: Colors.black.withAlpha(204), offset: const Offset(2, 6), blurRadius: 12),
                  ]
                : null,
          ),
        ),
        // km/h 单位（仅当前项）
        if (isCurrent) ...[
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'km',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: '/',
                    style: TextStyle(color: Color(0xFFC94A4A), fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: 'h',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildIndicator() {
    if (isCurrent) {
      return Container(
        width: 14,
        height: 14,
        decoration: const BoxDecoration(
          color: Color(0xFFFF0000),
          shape: BoxShape.circle,
        ),
      );
    }

    // 7种横线循环系统，长短交错营造刻度节奏感
    final distance = (speed - currentSpeed).abs();
    int offset = (speed - currentSpeed) % 7;
    if (offset < 0) offset += 7;

    const lineLengths = [22.0, 12.0, 12.0, 22.0, 12.0, 22.0, 12.0];
    final lineLength = lineLengths[offset];
    final lineOpacity = distance > 2 ? 0.3 : 0.5;

    return Container(
      width: lineLength,
      height: 2.5,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((lineOpacity * 255).round()),
        borderRadius: BorderRadius.circular(1.25),
      ),
    );
  }
}

/// 底部按钮区：紧急停止（左）+ 油门加速（右）
class _RunningButtons extends StatelessWidget {
  final bool throttling;
  final VoidCallback onStop;
  final VoidCallback onThrottleStart;
  final VoidCallback onThrottleEnd;

  const _RunningButtons({
    required this.throttling,
    required this.onStop,
    required this.onThrottleStart,
    required this.onThrottleEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 紧急停止
        Expanded(
          child: GestureDetector(
            onTap: onStop,
            child: SizedBox(
              height: 56,
              child: CustomPaint(painter: _StopButtonPainter()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 油门加速
        GestureDetector(
          onLongPressStart: (_) => onThrottleStart(),
          onLongPressEnd: (_) => onThrottleEnd(),
          onLongPressCancel: () => onThrottleEnd(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: throttling ? 80 : 72,
            height: throttling ? 80 : 72,
            child: CustomPaint(painter: _ThrottleButtonPainter(active: throttling)),
          ),
        ),
      ],
    );
  }
}

/// 紧急停止按钮 — 暗红发光圆角矩形 + 白色方块图标
class _StopButtonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromLTRBR(0, 0, size.width, size.height, const Radius.circular(28));

    // 暗红背景
    canvas.drawRRect(rrect, Paint()..color = const Color(0x33FF0000)..style = PaintingStyle.fill);

    // 发光边框
    canvas.drawRRect(rrect, Paint()..color = const Color(0x66FF4444)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // 外发光
    canvas.drawRRect(
      rrect.inflate(3),
      Paint()..color = const Color(0x15FF0000)..style = PaintingStyle.stroke..strokeWidth = 6,
    );

    // STOP 图标
    final cx = size.width / 2;
    final cy = size.height / 2;
    final sq = 14.0;
    final stopPath = Path()
      ..addRRect(RRect.fromLTRBR(
        cx - sq / 2, cy - sq / 2,
        cx + sq / 2, cy + sq / 2,
        const Radius.circular(3),
      ));
    canvas.drawPath(stopPath, Paint()..color = const Color(0xBBFF4444)..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// 油门加速按钮 — 绿色发光圆环 + 半透明填充 + 向上箭头
class _ThrottleButtonPainter extends CustomPainter {
  final bool active;

  _ThrottleButtonPainter({required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 2;

    // 外发光
    canvas.drawCircle(
      Offset(cx, cy), radius + 2,
      Paint()
        ..color = active ? const Color(0x44FF0000) : const Color(0x2200FF00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    // 圆环边框
    canvas.drawCircle(
      Offset(cx, cy), radius,
      Paint()
        ..color = active ? const Color(0x88FF4444) : const Color(0x6644FF44)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 内填充
    canvas.drawCircle(
      Offset(cx, cy), radius - 1,
      Paint()
        ..color = active ? const Color(0x22FF0000) : const Color(0x0A00FF00)
        ..style = PaintingStyle.fill,
    );

    // 向上箭头
    final arrowColor = active ? const Color(0xCCFF4444) : const Color(0x8844FF44);
    final arrowSize = radius * 0.45;
    final path = Path()
      ..moveTo(cx, cy - arrowSize)
      ..lineTo(cx - arrowSize * 0.65, cy + arrowSize * 0.4)
      ..lineTo(cx + arrowSize * 0.65, cy + arrowSize * 0.4)
      ..close();
    canvas.drawPath(path, Paint()..color = arrowColor..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _ThrottleButtonPainter old) => old.active != active;
}
