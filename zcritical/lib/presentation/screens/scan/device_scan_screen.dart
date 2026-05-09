// ══════════════════════════════════════════════════════════════
// STEER: 反臃肿 | scope=app | 修改前读 anti-bloat.md
//
// 职责: 设备扫描页（APP启动首页）
//       声波动画 → 5s弹窗（含3D风洞模型）→ 背景模糊 → 进入主页
// 不做什么: 不实现真实BLE扫描（data层未完成）
// ══════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/ble/ble_connection_provider.dart';
import '../../widgets/wind_tunnel_view.dart';

class DeviceScanScreen extends ConsumerStatefulWidget {
  const DeviceScanScreen({super.key});

  @override
  ConsumerState<DeviceScanScreen> createState() => _DeviceScanScreenState();
}

class _DeviceScanScreenState extends ConsumerState<DeviceScanScreen>
    with TickerProviderStateMixin {
  String _statusText = '扫描中...';
  bool _showDialog = false;
  Timer? _demoTimer;

  // 弹窗动画
  late final AnimationController _blurController;
  late final AnimationController _slideController;
  late final Animation<double> _blurAnimation;
  late final Animation<Offset> _slideAnimation;

  static const _mockDevices = [
    _MockDevice(id: 'T1-001', name: 'T1', rssi: -45),
  ];

  @override
  void initState() {
    super.initState();

    _blurController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _blurAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _blurController, curve: Curves.easeInOut),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _startDemoSequence();
  }

  void _startDemoSequence() {
    setState(() => _statusText = '扫描中...');

    // 1.5s 后弹窗
    _demoTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showDialog = true);
        _slideController.forward();
        _blurController.forward();
      }
    });
  }

  void _autoConnect() {
    final device = _mockDevices[0];
    ref.read(connectionStateProvider.notifier).connect(device.id, device.name);
    ref.read(connectionStateProvider.notifier).onConnected(device.id, device.name);
    ref.read(connectedDeviceProvider.notifier).state = ConnectedDevice(
      id: device.id,
      name: device.name,
    );
    context.go('/home');
  }

  void _manualConnect() {
    _demoTimer?.cancel();
    _autoConnect();
  }

  void _skipToHome() {
    _demoTimer?.cancel();
    context.go('/home');
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    _blurController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 扫描背景层（弹窗后模糊渐隐）
          AnimatedBuilder(
            animation: _blurAnimation,
            builder: (_, child) {
              final v = _blurAnimation.value;
              return ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: v * 15, sigmaY: v * 15),
                child: Opacity(opacity: 1.0 - v * 0.8, child: child),
              );
            },
            child: _buildScanningUI(),
          ),

          // 弹窗覆盖层（背景变暗）
          if (_showDialog)
            AnimatedBuilder(
              animation: _blurAnimation,
              builder: (_, __) => Container(color: Colors.black.withAlpha((_blurAnimation.value * 180).round())),
            ),

          // 发现设备弹窗（从下方滑入）
          if (_showDialog)
            SlideTransition(
              position: _slideAnimation,
              child: _buildFoundDialog(),
            ),
        ],
      ),
    );
  }

  Widget _buildScanningUI() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_statusText, style: const TextStyle(
              color: Colors.white, fontSize: 36, fontWeight: FontWeight.w400,
            )),
            const SizedBox(height: 8),
            const Text(
              '请确保您的设备处于配对模式',
              style: TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.w300),
            ),
            const Spacer(),
            const Center(child: SoundWaveScanner(width: 280, height: 200)),
            const Spacer(),
            Row(children: [
              Expanded(
                child: TextButton(
                  onPressed: _skipToHome,
                  child: const Text('跳过扫描', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: _manualConnect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('立即连接', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFoundDialog() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF0D0D0D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('发现设备', style: TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 8),
                const Text('T1', style: TextStyle(color: Colors.white70, fontSize: 18)),
                const SizedBox(height: 4),
                const Text('信号强度: -45 dBm', style: TextStyle(color: Colors.white54, fontSize: 14)),
                const SizedBox(height: 20),

                // 3D 风洞模型（代码绘制）
                const SizedBox(
                  height: 200,
                  child: WindTunnelView(),
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: 320, height: 58,
                  child: ElevatedButton(
                    onPressed: _manualConnect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D68F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(29)),
                      elevation: 0,
                    ),
                    child: const Text('进入控制界面', style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600,
                    )),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MockDevice {
  final String id;
  final String name;
  final int rssi;
  const _MockDevice({required this.id, required this.name, required this.rssi});
}

// ══════════════════════════════════════════════════════════════
// SoundWaveScanner — 直接复刻 RideWind
// ══════════════════════════════════════════════════════════════

class SoundWaveScanner extends StatefulWidget {
  final double width;
  final double height;

  const SoundWaveScanner({super.key, this.width = 280, this.height = 200});

  @override
  State<SoundWaveScanner> createState() => _SoundWaveScannerState();
}

class _SoundWaveScannerState extends State<SoundWaveScanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CustomPaint(
          painter: _SoundWavePainter(progress: _controller.value),
        ),
      ),
    );
  }
}

class _SoundWavePainter extends CustomPainter {
  final double progress;
  static const int barCount = 9;
  static const double barWidth = 6;
  static const double barSpacing = 14;

  _SoundWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final totalWidth = barCount * barWidth + (barCount - 1) * barSpacing;
    final startX = center.dx - totalWidth / 2;

    for (int i = 0; i < barCount; i++) {
      final x = startX + i * (barWidth + barSpacing);
      final barHeight = _getBarHeight(i, size.height);
      final color = _getBarColor(i, barHeight, size.height);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x + barWidth / 2, center.dy), width: barWidth, height: barHeight),
        const Radius.circular(3),
      );

      final intensity = barHeight / size.height;
      if (intensity > 0.7) {
        final redValue = (color.r * 255).round() & 0xff;
        final blueValue = (color.b * 255).round() & 0xff;
        final isReddish = redValue > blueValue && redValue > 200;
        canvas.drawRRect(rect, Paint()
          ..color = color.withAlpha(isReddish ? 102 : 51)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, isReddish ? 8 : 5)
          ..style = PaintingStyle.fill);
      }
      canvas.drawRRect(rect, Paint()..color = color..style = PaintingStyle.fill);
    }
  }

  double _getBarHeight(int index, double maxHeight) {
    final phase = index * 0.35;
    final wave = math.sin((progress + phase) * 2 * math.pi);
    final distanceFromCenter = (index - 4).abs();
    if (index == 4) return maxHeight * (0.35 + _ease(wave.abs()) * 0.50);
    final base = 0.25 + (1.0 - distanceFromCenter / 5.0) * 0.15;
    final amp = 0.40 - (distanceFromCenter * 0.05);
    return maxHeight * (base + _ease(wave.abs()) * amp);
  }

  double _ease(double t) => -(math.cos(math.pi * t) - 1) / 2;

  Color _getBarColor(int index, double barHeight, double maxHeight) {
    final intensity = barHeight / maxHeight;
    final scanPos = (progress * 2) % 2.0;
    final nPos = scanPos > 1.0 ? 2.0 - scanPos : scanPos;
    final dist = ((index / (barCount - 1)) - nPos).abs();
    final scanInf = (1.0 - (dist * 3).clamp(0.0, 1.0));
    final intInf = intensity > 0.5 ? (intensity - 0.5) / 0.5 : 0.0;
    final red = (scanInf * 0.6 + intInf * 0.4).clamp(0.0, 1.0);
    if (red > 0.1) return Color.lerp(Colors.white, const Color(0xFFFF3333), math.pow(red, 0.7).toDouble())!;
    return Colors.white;
  }

  @override
  bool shouldRepaint(covariant _SoundWavePainter old) => old.progress != progress;
}
