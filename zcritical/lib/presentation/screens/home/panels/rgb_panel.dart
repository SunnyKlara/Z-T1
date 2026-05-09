// ══════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=350 | scope=app | 修改前读 anti-bloat.md
// ══════════════════════════════════════════════════════════════
/// 职责：RGB 调色面板 — L/M/R/B 四区胶囊 + 流水灯速度 + 详细调色 + 亮度
/// 不做什么：不处理 BLE 通信（Phase 2 接入），不包含预设选择（由 ColorizePanel 负责）
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zcritical/presentation/widgets/metallic_rgb_slider.dart';
import 'package:zcritical/presentation/widgets/vertical_brightness_bar.dart';

class RgbPanel extends StatefulWidget {
  const RgbPanel({super.key});

  @override
  State<RgbPanel> createState() => _RgbPanelState();
}

class _RgbPanelState extends State<RgbPanel> {
  String _activeZone = 'B';
  bool _showDetail = false;

  final Map<String, int> _red = {'L': 150, 'M': 150, 'R': 150, 'B': 200};
  final Map<String, int> _green = {'L': 20, 'M': 20, 'R': 20, 'B': 50};
  final Map<String, int> _blue = {'L': 0, 'M': 0, 'R': 0, 'B': 0};

  double _brightness = 1.0;
  double _cycleSpeed = 0.5;
  bool _isCycling = false;

  static const _zones = ['L', 'M', 'R', 'B'];

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 主内容
        Column(
          children: [
            Expanded(child: _buildCapsules()),
            _buildCycleSpeed(),
            const SizedBox(height: 16),
          ],
        ),
        // 详细调色覆盖层
        if (_showDetail) _buildDetailOverlay(),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  //  四区胶囊
  // ═══════════════════════════════════════════════

  Widget _buildCapsules() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalW = constraints.maxWidth;
        final totalH = constraints.maxHeight;
        final hPad = totalW * 0.035;
        final capsuleW = totalW < 360 ? 50.0 : (totalW > 428 ? 65.0 : 55.0);
        final capsuleH = (totalH * 0.65).clamp(120.0, 180.0);
        final letterSize = totalW < 360 ? 20.0 : (totalW > 414 ? 30.0 : 24.0);
        final letterGap = totalH < 700 ? 8.0 : 12.0;

        return Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _zones.map((zone) {
              final sel = _activeZone == zone;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _activeZone = zone);
                },
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _activeZone = zone;
                    _showDetail = true;
                  });
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: capsuleW,
                        height: capsuleH,
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFFC62828) : Colors.white,
                          borderRadius: BorderRadius.circular(capsuleW / 2),
                          boxShadow: sel
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFC62828).withAlpha(153),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(102),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                      ),
                      SizedBox(height: letterGap),
                      Text(
                        zone,
                        style: TextStyle(
                          color: sel ? Colors.white : Colors.white.withAlpha(153),
                          fontSize: letterSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════
  //  流水灯速度
  // ═══════════════════════════════════════════════

  Widget _buildCycleSpeed() {
    final totalW = MediaQuery.of(context).size.width;
    final labelSize = totalW < 360 ? 14.0 : (totalW > 414 ? 18.0 : 16.0);
    final sliderH = totalW < 360 ? 36.0 : (totalW > 414 ? 52.0 : 46.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: totalW * 0.06),
      child: Row(
        children: [
          Text('慢',
              style: TextStyle(color: Colors.white, fontSize: labelSize, fontWeight: FontWeight.w500)),
          SizedBox(width: totalW * 0.03),
          Expanded(
            child: Container(
              height: sliderH,
              decoration: BoxDecoration(
                color: const Color(0xFF121212).withAlpha(204),
                borderRadius: BorderRadius.circular(sliderH / 2),
                border: Border.all(
                  color: _isCycling
                      ? const Color(0xFFC62828).withAlpha(102)
                      : Colors.white.withAlpha(26),
                  width: 1,
                ),
              ),
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: sliderH,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  thumbColor: _isCycling ? const Color(0xFFC62828) : Colors.white,
                  thumbShape: _RoundThumb(radius: sliderH / 2),
                  overlayColor: Colors.transparent,
                ),
                child: Slider(
                  value: _cycleSpeed,
                  onChanged: (val) {
                    setState(() {
                      _cycleSpeed = val;
                      if (!_isCycling) _isCycling = true;
                    });
                  },
                ),
              ),
            ),
          ),
          SizedBox(width: totalW * 0.03),
          Text('快',
              style: TextStyle(color: Colors.white, fontSize: labelSize, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  详细调色 Overlay
  // ═══════════════════════════════════════════════

  Widget _buildDetailOverlay() {
    final zoneNames = {'L': '左侧灯带', 'M': '中间灯带', 'R': '右侧灯带', 'B': '后部灯带'};
    final zone = _activeZone;

    return Stack(
      children: [
        // 半透明背景 — 点击关闭
        GestureDetector(
          onTap: () => setState(() => _showDetail = false),
          child: Container(color: Colors.black.withAlpha(128)),
        ),
        // 右侧亮度条
        Positioned(
          top: MediaQuery.of(context).size.height * 0.15,
          right: MediaQuery.of(context).size.width * 0.025,
          child: SizedBox(
            width: 55,
            height: MediaQuery.of(context).size.height * 0.22,
            child: VerticalBrightnessBar(
              brightness: _brightness,
              onChanged: (v) => setState(() => _brightness = v),
            ),
          ),
        ),
        // 底部 RGB 滑条面板
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(30, 35, 80, 50),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF151515), Color(0xFF0A0A0A)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
              border: Border(
                top: BorderSide(color: Colors.white.withAlpha(20), width: 1.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(204),
                  blurRadius: 40,
                  offset: const Offset(0, -15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 拖拽指示条
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 25),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(31),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // 标题行：色环入口 + 灯区名称
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 色环按钮（TODO: 后续接入 ColorRingScreen）
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        // TODO: Navigator.of(context).push(ColorRingScreen(...));
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withAlpha(179), width: 1.5),
                          gradient: const SweepGradient(
                            colors: [
                              Color(0xFFFF4500),
                              Color(0xFFE2C100),
                              Color(0xFF2BAE66),
                              Color(0xFF1661AB),
                              Color(0xFF8B2671),
                              Color(0xFFFF4500),
                            ],
                          ),
                        ),
                        child: const Icon(Icons.palette_outlined, color: Colors.white, size: 18),
                      ),
                    ),
                    Text(
                      zoneNames[zone]!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // R 通道
                MetallicRgbSlider(
                  label: 'R',
                  color: const Color(0xFFFF3D00),
                  value: _red[zone]!,
                  onChanged: (v) {
                    setState(() => _red[zone] = v);
                  },
                ),
                const SizedBox(height: 15),
                // G 通道
                MetallicRgbSlider(
                  label: 'G',
                  color: const Color(0xFF00E676),
                  value: _green[zone]!,
                  onChanged: (v) {
                    setState(() => _green[zone] = v);
                  },
                ),
                const SizedBox(height: 15),
                // B 通道
                MetallicRgbSlider(
                  label: 'B',
                  color: const Color(0xFF2979FF),
                  value: _blue[zone]!,
                  onChanged: (v) {
                    setState(() => _blue[zone] = v);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 圆形滑块拇指
class _RoundThumb extends SliderComponentShape {
  final double radius;

  _RoundThumb({required this.radius});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size(radius * 2, radius * 2);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(center, radius - 2, Paint()..color = Colors.white);
    canvas.drawCircle(center, radius - 2, Paint()
      ..color = Colors.white.withAlpha(26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }
}
