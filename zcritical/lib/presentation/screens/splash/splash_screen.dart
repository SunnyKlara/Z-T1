// ══════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=350 | scope=app | 修改前读 anti-bloat.md
// ══════════════════════════════════════════════════════════════
// 职责：启动页 — 品牌Logo(代码绘制) + "开始使用"按钮 + 用户协议勾选
// 不做什么：不处理 BLE 连接、不处理权限请求、不包含业务逻辑

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/router/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _agreed = false;

  static const Color _bg = Color(0xFF000000);
  static const Color _accent = Color(0xFF00BCD4);
  static const Color _textWhite = Colors.white;

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(title, style: const TextStyle(color: _textWhite, fontSize: 20, fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 16, height: 1.5)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭', style: TextStyle(color: _accent)),
          ),
        ],
      ),
    );
  }

  Future<void> _onStart() async {
    if (!_agreed) return;
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    context.go(RoutePaths.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            _BrandLogo(accent: _accent),
            const SizedBox(height: 48),
            const Spacer(flex: 1),
            _AgreementCheck(
              value: _agreed,
              onChanged: (v) => setState(() => _agreed = v),
              onTapTerms: () => _showDialog('用户协议', _termsText),
              onTapPrivacy: () => _showDialog('隐私政策', _privacyText),
            ),
            const SizedBox(height: 32),
            _StartButton(enabled: _agreed, onTap: _onStart),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// ──── 品牌 Logo — 风洞线框图 + ZCritical 文字 ────

class _BrandLogo extends StatelessWidget {
  final Color accent;
  const _BrandLogo({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 120,
          height: 80,
          child: CustomPaint(painter: _WindTunnelPainter(accent: accent)),
        ),
        const SizedBox(height: 20),
        const Text(
          'ZCritical',
          style: TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

// ──── 风洞线框 Painter — 收缩-扩张管 + 气流线条 ────

class _WindTunnelPainter extends CustomPainter {
  final Color accent;
  _WindTunnelPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final w = size.width, h = size.height, cx = w / 2, cy = h / 2;

    final path = Path()
      ..moveTo(0, cy - 15)
      ..lineTo(cx - 20, cy - 15)
      ..quadraticBezierTo(cx - 10, cy - 15, cx, cy - 30)
      ..lineTo(cx + 15, cy - 30)
      ..lineTo(cx + 15, cy + 30)
      ..lineTo(cx, cy + 30)
      ..quadraticBezierTo(cx - 10, cy + 15, cx - 20, cy + 15)
      ..lineTo(0, cy + 15)
      ..lineTo(w, cy + 5)
      ..lineTo(w, cy - 5)
      ..close();
    canvas.drawPath(path, paint);

    final flowPaint = Paint()
      ..color = accent.withAlpha(80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (int i = -1; i <= 1; i++) {
      final ly = cy + i * 12.0;
      canvas.drawLine(Offset(10, ly), Offset(cx + 15, ly), flowPaint);
    }

    canvas.drawCircle(
      Offset(cx + 8, cy), 4,
      Paint()..color = accent..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ──── 协议勾选 — 圆框 + 红色内圆点 + 蓝色链接 ────

class _AgreementCheck extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTapTerms;
  final VoidCallback onTapPrivacy;

  const _AgreementCheck({
    required this.value,
    required this.onChanged,
    required this.onTapTerms,
    required this.onTapPrivacy,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 20, height: 20, margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(100), width: 1.5),
          ),
          child: value
              ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF44336))))
              : null,
        ),
        const Text('我已阅读并同意', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 14)),
        GestureDetector(onTap: onTapTerms, child: const Text('用户协议', style: TextStyle(color: Color(0xFF2196F3), fontSize: 14))),
        const Text('和', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 14)),
        GestureDetector(onTap: onTapPrivacy, child: const Text('隐私政策', style: TextStyle(color: Color(0xFF2196F3), fontSize: 14))),
      ]),
    );
  }
}

// ──── 开始使用按钮 — 白底黑字，圆角29，宽320高58 ────

class _StartButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _StartButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 320, height: 58,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : const Color(0xFF444444),
          borderRadius: BorderRadius.circular(29),
        ),
        child: const Center(
          child: Text('开始使用', style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

// ──── 硬编码协议文本 ────

const _termsText = '''
ZCritical 用户协议

欢迎使用 ZCritical（桌面级智能风洞）！

一、服务说明
ZCritical 是一款配合桌面风洞硬件设备使用的智能控制终端应用。本应用通过蓝牙与设备连接，提供风扇速度控制、LED灯光调节、Logo管理等功能。

二、使用条款
1. 您需要拥有 ZCritical 系列硬件设备方可使用本应用的全部功能。
2. 使用本应用需要授予蓝牙权限、位置权限（Android）和通知权限。
3. 请勿在潮湿、高温或易燃环境中使用硬件设备。
4. 硬件设备运行时请勿触摸风扇叶片或其他运动部件。

三、免责声明
因不当使用硬件设备造成的人身伤害或财产损失，开发者不承担法律责任。

四、协议更新
我们可能不定期更新本协议，更新后的协议将在应用内公示。

如有疑问，请联系：support@zcritical.com
''';

const _privacyText = '''
ZCritical 隐私政策

一、信息收集
本应用仅收集以下必要信息：
- 蓝牙设备信息：用于发现和连接您的硬件设备
- 设备设置偏好：风扇速度、LED颜色等个性化设置（仅存储在本地）

二、信息使用
- 蓝牙权限仅用于连接您的硬件设备，不收集位置信息
- 所有设置数据仅存储在您的设备本地，不上传至任何服务器
- 本应用不包含任何第三方跟踪或分析服务

三、数据安全
- 我们不会收集、存储或传输您的任何个人信息
- 应用不需要注册账户，不需要联网
- 图片文件仅在本地处理，不会上传

四、儿童隐私
本应用不针对13岁以下儿童设计，不会有意收集儿童的个人信息。

五、联系我们
如有隐私相关问题，请联系：support@zcritical.com
''';
