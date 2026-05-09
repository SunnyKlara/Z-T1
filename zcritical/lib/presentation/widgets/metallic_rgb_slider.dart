// ══════════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=200 | scope=app-presentation | 修改前读 anti-bloat.md
//
// 职责: 金属分段式 RGB 滑条 — 25 段 LED 灯带风格 + 数值手动输入
// 不做什么: 不管理颜色状态，由调用方传入 value 和 onChanged
// ══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MetallicRgbSlider extends StatefulWidget {
  final String label;
  final Color color;
  final int value;
  final ValueChanged<int> onChanged;

  const MetallicRgbSlider({
    super.key,
    required this.label,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  State<MetallicRgbSlider> createState() => _MetallicRgbSliderState();
}

class _MetallicRgbSliderState extends State<MetallicRgbSlider> {
  bool _editing = false;
  late final TextEditingController _editCtrl;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _editCtrl = TextEditingController(text: widget.value.toString().padLeft(3, '0'));
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _editing) _commitEdit();
    });
  }

  @override
  void didUpdateWidget(MetallicRgbSlider old) {
    super.didUpdateWidget(old);
    if (!_editing && old.value != widget.value) {
      _editCtrl.text = widget.value.toString().padLeft(3, '0');
    }
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _commitEdit() {
    final parsed = int.tryParse(_editCtrl.text) ?? 0;
    widget.onChanged(parsed.clamp(0, 255));
    setState(() {
      _editing = false;
      _editCtrl.text = parsed.clamp(0, 255).toString().padLeft(3, '0');
    });
  }

  void _startEdit() {
    setState(() => _editing = true);
    _editCtrl.text = widget.value.toString();
    _editCtrl.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _editCtrl.text.length,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    const segments = 25;
    final litSegments = (widget.value / 255 * segments).round();
    final sliderH = 46.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                color: widget.color.withAlpha(230),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: widget.color.withAlpha(128),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            // 数值显示/编辑
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _editing
                      ? Colors.white.withAlpha(77)
                      : Colors.white.withAlpha(26),
                ),
              ),
              child: _editing
                  ? SizedBox(
                      width: 48,
                      height: 22,
                      child: TextField(
                        controller: _editCtrl,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.color.withAlpha(204),
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _commitEdit(),
                      ),
                    )
                  : GestureDetector(
                      onTap: _startEdit,
                      child: Text(
                        widget.value.toString().padLeft(3, '0'),
                        style: TextStyle(
                          color: widget.color.withAlpha(204),
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 分段灯带滑条
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: sliderH,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withAlpha(13),
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(segments, (i) {
                  final lit = i < litSegments;
                  return Container(
                    width: 6,
                    height: sliderH / 2,
                    decoration: BoxDecoration(
                      color: lit ? widget.color : Colors.white.withAlpha(8),
                      borderRadius: BorderRadius.circular(1),
                      boxShadow: lit
                          ? [BoxShadow(
                              color: widget.color.withAlpha(153),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )]
                          : null,
                    ),
                  );
                }),
              ),
            ),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: sliderH,
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
                thumbColor: Colors.white,
                thumbShape: _MechanicalThumb(color: widget.color),
                overlayColor: Colors.transparent,
              ),
              child: Slider(
                value: widget.value.toDouble(),
                min: 0,
                max: 255,
                onChanged: (v) => widget.onChanged(v.toInt()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 机械风格滑块拇指 — 白色圆形 + 颜色外圈
class _MechanicalThumb extends SliderComponentShape {
  final Color color;

  _MechanicalThumb({required this.color});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(28, 28);

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
    final r = 14.0;

    // 外圈颜色发光
    canvas.drawCircle(center, r + 3, Paint()
      ..color = color.withAlpha(102)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    // 主体白色圆
    canvas.drawCircle(center, r, Paint()..color = Colors.white);

    // 内圈颜色环
    canvas.drawCircle(center, r - 3, Paint()
      ..color = color.withAlpha(153)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }
}
