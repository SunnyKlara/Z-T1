// ══════════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=180 | scope=app-ui | 修改前读 anti-bloat.md
//
// 职责: SplashScreen — 品牌Logo + 用户协议勾选 + 开始使用按钮
// 不做什么: 不处理 BLE 通信、不管理用户状态持久化（由 app.dart 处理）
// ══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _agreed = false;

  void _showAgreement(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(content, style: const TextStyle(color: Colors.white70, height: 1.6)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('关闭', style: TextStyle(color: Color(0xFF00BCD4))),
          ),
        ],
      ),
    );
  }

  void _onStart() {
    if (!_agreed) return;
    context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // 品牌 Logo
              const Text(
                'ZCritical',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              // 风洞线框图形
              SizedBox(
                width: 200,
                height: 160,
                child: CustomPaint(painter: _WindTunnelPainter()),
              ),
              const Spacer(flex: 2),
              // 用户协议勾选
              GestureDetector(
                onTap: () => setState(() => _agreed = !_agreed),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white54, width: 1.5),
                      ),
                      child: _agreed
                          ? const Center(child: Icon(Icons.circle, size: 12, color: Colors.red))
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '我已阅读并同意',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // 协议链接
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _showAgreement('用户协议', _userAgreementText),
                    child: const Text(
                      '用户协议',
                      style: TextStyle(color: Color(0xFF2196F3), fontSize: 14),
                    ),
                  ),
                  const Text(' | ', style: TextStyle(color: Colors.white38, fontSize: 14)),
                  GestureDetector(
                    onTap: () => _showAgreement('隐私政策', _privacyPolicyText),
                    child: const Text(
                      '隐私政策',
                      style: TextStyle(color: Color(0xFF2196F3), fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // 开始使用按钮
              SizedBox(
                width: 320,
                height: 58,
                child: ElevatedButton(
                  onPressed: _agreed ? _onStart : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white.withValues(alpha: 0.4),
                    disabledForegroundColor: Colors.black.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(29)),
                  ),
                  child: const Text(
                    '开始使用',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 风洞线框图形
// ──────────────────────────────────────────────

class _WindTunnelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final cx = size.width / 2;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(20, 30, size.width - 40, size.height - 60),
      const Radius.circular(12),
    );
    canvas.drawRRect(rect, p);

    canvas.drawLine(Offset(cx, 30), Offset(cx, size.height - 30), p..strokeWidth = 1);

    canvas.drawLine(
      Offset(cx - 30, size.height / 2 - 10),
      Offset(cx + 30, size.height / 2 + 10),
      p..color = Colors.white.withValues(alpha: 0.35),
    );
    canvas.drawLine(
      Offset(cx + 30, size.height / 2 - 10),
      Offset(cx - 30, size.height / 2 + 10),
      p,
    );

    _arrow(canvas, p, Offset(35, size.height / 2));
    _arrow(canvas, p, Offset(40, size.height / 2));
    _arrow(canvas, p, Offset(45, size.height / 2));
  }

  void _arrow(Canvas c, Paint p, Offset o) {
    c.drawLine(o, Offset(o.dx + 12, o.dy), p..color = Colors.white.withValues(alpha: 0.25));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ──────────────────────────────────────────────
// 协议文本
// ──────────────────────────────────────────────

const _userAgreementText = '欢迎使用 ZCritical 桌面级智能风洞应用。\n\n'
    '1. 服务说明\n本应用通过蓝牙连接您的风洞设备。\n\n'
    '2. 用户责任\n用户应确保设备在安全环境下运行。\n\n'
    '3. 免责声明\n本产品为桌面模型玩具，非工业设备。\n\n'
    '4. 隐私保护\n所有设置保存在本地设备中。\n\n如有问题请联系客服。';

const _privacyPolicyText = 'ZCritical 隐私政策\n\n'
    '1. 信息收集\n本应用不收集任何个人身份信息。\n\n'
    '2. 数据存储\n所有设置仅存储在您的手机本地。\n\n'
    '3. 第三方服务\n本应用不使用第三方分析或广告服务。\n\n'
    '4. 权限说明\n- 蓝牙权限：用于连接风洞设备\n- 通知权限：用于状态更新\n- 附近设备权限：用于发现设备\n\n'
    '您可随时在系统设置中撤销权限。\n\n如有问题请联系客服。';
