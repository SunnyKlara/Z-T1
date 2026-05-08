// ZCritical 风洞模型视图
//
// 设计意图：
// - CustomPainter 绘制风洞的等距线框模型。自动旋转。
// - 手指拖动旋转，双击暂停/恢复。
// - 后续替换为序列帧；线框版作为 fallback。
//
// 模型构成：底座 + 风管（透明圆筒，可见内部车模） + 风扇 + 灯带

import 'dart:math' as math;
import 'package:flutter/material.dart';

class WindTunnelView extends StatefulWidget {
  const WindTunnelView({super.key});

  @override
  State<WindTunnelView> createState() => _WindTunnelViewState();
}

class _WindTunnelViewState extends State<WindTunnelView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _auto;
  double _angle = 0;
  double _dragStartAngle = 0;
  double _dragStartDx = 0;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _auto = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(_onAutoTick)
      ..repeat();
  }

  void _onAutoTick() {
    if (_dragging) return;
    setState(() => _angle = _auto.value * 2 * math.pi);
  }

  @override
  void dispose() {
    _auto.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails d) {
    _dragging = true;
    _auto.stop();
    _dragStartAngle = _angle;
    _dragStartDx = d.globalPosition.dx;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final delta = (d.globalPosition.dx - _dragStartDx) / 200;
    setState(() => _angle = (_dragStartAngle + delta) % (2 * math.pi));
  }

  void _onDragEnd(DragEndDetails _) {
    _dragging = false;
    _auto.value = _angle / (2 * math.pi);
    _auto.repeat();
  }

  void _onDoubleTap() {
    if (_auto.isAnimating) {
      _auto.stop();
    } else {
      _auto.value = _angle / (2 * math.pi);
      _auto.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: CustomPaint(
        painter: _WindTunnelPainter(angle: _angle),
        size: Size.infinite,
      ),
    );
  }
}

/// 风洞线框 Painter。
///
/// 参考 RideWind 的 _TreadmillDemoPainter 结构，重新绘制风洞模型。
/// 模型：矩形底座 + 圆柱风管 + 内部车模轮廓 + 前端风扇环 + 顶部灯带
class _WindTunnelPainter extends CustomPainter {
  final double angle;
  final double _fanAngle;

  _WindTunnelPainter({required this.angle}) : _fanAngle = angle * 2;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - size.height * 0.08;
    final s = math.min(size.width, size.height) / 4.5;

    _drawBase(canvas, cx, cy, s);
    _drawTunnel(canvas, cx, cy, s);
    _drawCar(canvas, cx, cy, s);
    _drawFanRing(canvas, cx, cy, s);
    _drawLightStrip(canvas, cx, cy, s);
    _drawShadow(canvas, cx, cy, s, size);
  }

  // ---- 底座 ----

  void _drawBase(Canvas c, double cx, double cy, double s) {
    const double w = 1.6, d = 0.7, h = 0.25;
    final List<List<double>> baseVerts = [
      [-w, 0.0, -d], [w, 0.0, -d], [w, 0.0, d], [-w, 0.0, d],
      [-w, h, -d], [w, h, -d], [w, h, d], [-w, h, d],
    ];
    final body = baseVerts
        .map((p) => _proj(cx, cy, s, p[0], p[1], p[2]))
        .toList();

    final edge = Paint()
      ..color = Colors.white.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final edgeAccent = Paint()
      ..color = Colors.white.withAlpha(80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 顶面
    final top = _path([body[4], body[5], body[6], body[7]]);
    c.drawPath(top, Paint()..color = Colors.white.withAlpha(6));
    c.drawPath(top, edgeAccent);

    // 边
    _line(c, body[0], body[1], edge);
    _line(c, body[1], body[2], edge);
    _line(c, body[2], body[3], edge);
    _line(c, body[3], body[0], edge);
    _line(c, body[0], body[4], edge);
    _line(c, body[1], body[5], edge);
    _line(c, body[2], body[6], edge);
    _line(c, body[3], body[7], edge);
  }

  // ---- 风管（圆筒） ----

  void _drawTunnel(Canvas c, double cx, double cy, double s) {
    final tube = Paint()
      ..color = Colors.white.withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final radius = s * 0.48;
    final y = cy - s * 0.3;
    const segments = 48;

    // 正面圆环
    final front = <Offset>[];
    for (int i = 0; i <= segments; i++) {
      final a = i / segments * 2 * math.pi;
      front.add(_proj(cx, y, radius, math.cos(a), 0, math.sin(a), false));
    }
    for (int i = 0; i < front.length - 1; i++) {
      _line(c, front[i], front[i + 1], tube);
    }

    // 背面圆环（在底座上方）
    final back = <Offset>[];
    for (int i = 0; i <= segments; i++) {
      final a = i / segments * 2 * math.pi;
      back.add(_proj(cx, y + s * 0.05, radius * 0.92,
          math.cos(a), 0, math.sin(a), false));
    }
    final tubeBack = Paint()
      ..color = Colors.white.withAlpha(15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 0; i < back.length - 1; i++) {
      _line(c, back[i], back[i + 1], tubeBack);
    }
  }

  // ---- 内部车模 ----

  void _drawCar(Canvas c, double cx, double cy, double s) {
    const carW = 0.5, carH = 0.15;
    const double carD = 0.2;
    final y = cy - s * 0.28;
    final car = [
      [-carW, carH + 0.02, -carD], [carW, carH + 0.02, -carD],
      [carW, carH + 0.02, carD],  [-carW, carH + 0.02, carD],
      [-carW, carH + 0.18, -carD / 2], [carW, carH + 0.18, -carD / 2],
      [carW, carH + 0.18, carD / 2],  [-carW, carH + 0.1, carD / 2],
    ]
        .map((p) => _proj(cx, y, s, p[0], p[1], p[2]))
        .toList();

    final carPaint = Paint()
      ..color = const Color(0xFF00BCD4).withAlpha(40)
      ..style = PaintingStyle.fill;
    final carLine = Paint()
      ..color = const Color(0xFF00BCD4).withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 车顶
    final top = _path([car[4], car[5], car[6], car[7]]);
    c.drawPath(top, carPaint);
    c.drawPath(top, carLine);

    // 车身底部
    final body = _path([car[0], car[1], car[2], car[3]]);
    c.drawPath(body, carPaint);
    c.drawPath(body, carLine);

    // 侧边
    _line(c, car[0], car[4], carLine);
    _line(c, car[1], car[5], carLine);
    _line(c, car[2], car[6], carLine);
    _line(c, car[3], car[7], carLine);

    // 轮子（4个极小的圆）
    final wheelP = Paint()
      ..color = Colors.white.withAlpha(60)
      ..style = PaintingStyle.fill;
    for (final pos in [
      [-0.35, 0.04, -0.17],
      [0.35, 0.04, -0.17],
      [-0.35, 0.04, 0.17],
      [0.35, 0.04, 0.17],
    ]) {
      c.drawCircle(
        _proj(cx, y, s, pos[0], pos[1], pos[2]),
        s * 0.06,
        wheelP,
      );
    }
  }

  // ---- 风扇环（前端） ----

  void _drawFanRing(Canvas c, double cx, double cy, double s) {
    final fanPaint = Paint()
      ..color = const Color(0xFF00BCD4).withAlpha(50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final fanFill = Paint()
      ..color = const Color(0xFF00BCD4).withAlpha(8)
      ..style = PaintingStyle.fill;

    final center = _proj(cx, cy - s * 0.05, s, 0, -0.08, 0);
    final r = s * 0.44;

    c.drawCircle(center, r, fanFill);
    c.drawCircle(center, r, fanPaint);

    // 十字扇叶
    final bladeP = Paint()
      ..color = const Color(0xFF00BCD4).withAlpha(60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      final a = _fanAngle + i * math.pi / 2;
      c.drawLine(
        center,
        Offset(center.dx + math.cos(a) * r * 0.8,
            center.dy + math.sin(a) * r * 0.8),
        bladeP,
      );
    }

    // 中心点
    c.drawCircle(
        center, 3, Paint()..color = const Color(0xFF00BCD4).withAlpha(120));
  }

  // ---- 顶部灯带 ----

  void _drawLightStrip(Canvas c, double cx, double cy, double s) {
    final y = cy - s * 0.68;
    final w = s * 1.1;
    final h = s * 0.04;
    final strip = RRect.fromLTRBR(
      cx - w, y, cx + w, y + h,
      const Radius.circular(2),
    );
    final stripPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x00FFFFFF),
          Color(0x20FFFFFF),
          Color(0x30FFFFFF),
          Color(0x20FFFFFF),
          Color(0x00FFFFFF),
        ],
      ).createShader(Rect.fromLTWH(cx - w, y, w * 2, h));
    c.drawRRect(strip, stripPaint);
  }

  // ---- 阴影 ----

  void _drawShadow(Canvas c, double cx, double cy, double s, Size size) {
    final shadowP = Paint()
      ..color = Colors.white.withAlpha(8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + s * 0.55),
        width: s * 2.8,
        height: s * 0.35,
      ),
      shadowP,
    );
  }

  // ---- 投影 ----

  Offset _proj(double cx, double cy, double s, double x, double y, double z,
      [bool rotate = true]) {
    double rx = x, rz = z;
    if (rotate) {
      final ca = math.cos(angle);
      final sa = math.sin(angle);
      rx = x * ca + z * sa;
      rz = -x * sa + z * ca;
    }
    final persp = 1 / (1 + rz * 0.05);
    return Offset(cx + rx * s * persp, cy - y * s * persp);
  }

  Path _path(List<Offset> pts) {
    final p = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      p.lineTo(pts[i].dx, pts[i].dy);
    }
    p.close();
    return p;
  }

  void _line(Canvas c, Offset a, Offset b, Paint p) {
    c.drawLine(a, b, p);
  }

  @override
  bool shouldRepaint(covariant _WindTunnelPainter old) => old.angle != angle;
}
