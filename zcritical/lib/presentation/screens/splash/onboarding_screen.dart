// ══════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=200 | scope=app | 修改前读 anti-bloat.md
// ══════════════════════════════════════════════════════════════
// 职责：引导页 — 3 页 PageView 引导 + 底部指示器 + 下一步按钮
// 不做什么：不处理 BLE 连接、不请求权限（仅展示引导内容）

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/router/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _PageData(
      icon: Icons.notifications_active_outlined,
      title: '允许通知权限',
      description: '开启通知权限，及时获取设备状态更新、\n固件升级提醒等重要信息。',
    ),
    _PageData(
      icon: Icons.bluetooth_searching,
      title: '允许附近设备权限',
      description: '开启蓝牙和位置权限，搜索并连接\n您的 ZCritical 风洞设备。',
    ),
    _PageData(
      icon: Icons.check_circle_outline,
      title: '全部就绪！',
      description: '一切准备就绪。\n开始探索您的风洞世界吧！',
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  Future<void> _onFinish() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    context.go(RoutePaths.home);
  }

  void _onNext() {
    if (_isLastPage) {
      _onFinish();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, i) => _buildPage(_pages[i]),
            ),
          ),
          _buildBottom(),
          const SizedBox(height: 48),
        ]),
      ),
    );
  }

  Widget _buildPage(_PageData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(data.icon, size: 80, color: const Color(0xFF00BCD4)),
        const SizedBox(height: 40),
        Text(
          data.title,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.2),
        ),
        const SizedBox(height: 20),
        Text(
          data.description,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 20, fontWeight: FontWeight.w400, height: 1.5),
        ),
      ]),
    );
  }

  Widget _buildBottom() {
    return Column(children: [
      // 指示器：选中短条（青色24×4）+ 未选中长条（灰8×4）
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_pages.length, (i) {
        final active = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: active ? const Color(0xFF00BCD4) : Colors.white.withAlpha(50),
          ),
        );
      })),
      const SizedBox(height: 32),
      // 按钮：白底黑字，圆角29，宽320高58
      GestureDetector(
        onTap: _onNext,
        child: Container(
          width: 320, height: 58,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(29)),
          child: Center(
            child: Text(_isLastPage ? '开始探索' : '下一步', style: const TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    ]);
  }
}

class _PageData {
  final IconData icon;
  final String title;
  final String description;
  const _PageData({required this.icon, required this.title, required this.description});
}
