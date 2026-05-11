// ══════════════════════════════════════════════════════════════
// STEER: 反臃肿 | scope=app
//
// 职责: 设备扫描页 — 声波动画 → BLE扫描 → 发现设备弹窗 → 进入主页
//       基于RideWind BLEService重写
// ══════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../data/ble/ble_service.dart';
import '../../widgets/wind_tunnel_view.dart';

class DeviceScanScreen extends StatefulWidget {
  const DeviceScanScreen({super.key});

  @override
  State<DeviceScanScreen> createState() => _DeviceScanScreenState();
}

class _DeviceScanScreenState extends State<DeviceScanScreen>
    with TickerProviderStateMixin {
  final BleService _bleService = BleService();
  bool _showDialog = false;
  bool _isScanning = false;
  bool _isConnecting = false;
  List<ScanResult> _devices = [];
  ScanResult? _selectedDevice;
  String? _errorMessage;

  // 弹窗动画
  late final AnimationController _blurController;
  late final AnimationController _slideController;
  late final Animation<double> _blurAnimation;
  late final Animation<Offset> _slideAnimation;

  StreamSubscription? _scanSub;
  StreamSubscription? _connSub;

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

    _startScan();
  }

  Future<void> _startScan() async {
    // Android: 请求位置权限（MIUI 即使 Android 12+ 也需要）
    if (Platform.isAndroid) {
      final status = await Permission.location.request();
      if (!status.isGranted) {
        setState(() => _errorMessage = '需要位置权限才能扫描');
        return;
      }
    }

    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    try {
      final results = await _bleService.scanDevices(
        timeout: const Duration(seconds: 10),
      );

      if (!mounted) return;

      setState(() {
        _devices = results;
        _isScanning = false;
      });

      if (results.isNotEmpty) {
        _showDeviceDialog(results.first);
      } else {
        setState(() => _errorMessage = '未找到设备');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _errorMessage = '扫描失败，重试';
      });
    }
  }

  void _showDeviceDialog(ScanResult result) {
    setState(() {
      _selectedDevice = result;
      _showDialog = true;
    });
    _slideController.forward();
    _blurController.forward();
  }

  Future<void> _connectToDevice() async {
    final device = _selectedDevice;
    debugPrint('🔹 [SCAN] _connectToDevice 调用: device=$device');
    if (device == null) {
      debugPrint('🔹 [SCAN] _selectedDevice 为 null，退出');
      return;
    }

    // Android 12+: 先检查权限状态，再请求
    if (Platform.isAndroid) {
      final status = await Permission.bluetoothConnect.status;
      debugPrint('🔹 [SCAN] bluetoothConnect status=$status');
      if (!status.isGranted) {
        final result = await Permission.bluetoothConnect.request();
        debugPrint('🔹 [SCAN] bluetoothConnect request result=$result');
        if (!result.isGranted) {
          setState(() => _errorMessage = '请在设置中开启蓝牙连接权限');
          return;
        }
      }
    }

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    debugPrint('🔹 [SCAN] 调用 _bleService.connect()...');
    final success = await _bleService.connect(device.device);
    debugPrint('🔹 [SCAN] _bleService.connect() 返回: $success');

    if (!mounted) return;

    if (success) {
      context.go('/home');
    } else {
      setState(() {
        _isConnecting = false;
        _errorMessage = '连接失败，请重试';
      });
    }
  }

  void _skipToHome() {
    context.go('/home');
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
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
          // 扫描背景层
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

          // 弹窗覆盖层
          if (_showDialog)
            AnimatedBuilder(
              animation: _blurAnimation,
              builder: (_, __) => Container(color: Colors.black.withAlpha((_blurAnimation.value * 180).round())),
            ),

          // 发现设备弹窗
          if (_showDialog)
            SlideTransition(
              position: _slideAnimation,
              child: _buildFoundDialog(),
            ),
        ],
      ),
    );
  }

  String _getStatusText() {
    if (_isConnecting) return '连接中...';
    if (_isScanning) return '扫描中...';
    if (_errorMessage != null) return _errorMessage!;
    return '扫描中...';
  }

  Widget _buildScanningUI() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getStatusText(), style: const TextStyle(
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
                  onPressed: () => _startScan(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D68F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(29)),
                    elevation: 0,
                  ),
                  child: const Text('重新扫描', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    final device = _selectedDevice;
    final name = device?.device.platformName ?? 'T1';
    final rssi = device?.rssi ?? 0;

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
                Text(name, style: const TextStyle(color: Colors.white70, fontSize: 18)),
                const SizedBox(height: 4),
                Text('信号强度: $rssi dBm', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                const SizedBox(height: 20),
                const SizedBox(height: 200, child: WindTunnelView()),
                const SizedBox(height: 20),
                SizedBox(
                  width: 320, height: 58,
                  child: ElevatedButton(
                    onPressed: _isConnecting ? null : _connectToDevice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D68F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(29)),
                      elevation: 0,
                    ),
                    child: Text(_isConnecting ? '连接中...' : '进入控制界面',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
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

// ══════════════════════════════════════════════════════════════
// 声波动画（不变）
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
