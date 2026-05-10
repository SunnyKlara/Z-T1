// ══════════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=150 | scope=app-ui | 修改前读 anti-bloat.md
//
// 职责: OnboardingScreen — 3页引导流程（权限说明 + 完成页）
// 不做什么: 不处理 BLE 通信、不请求真实系统权限
// ══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    (title: '允许通知权限', desc: '接收设备连接状态、固件更新等重要通知', btn: '下一步'),
    (title: '允许附近设备权限', desc: '搜索并连接您的风洞设备，需要蓝牙权限', btn: '下一步'),
    (title: '全部就绪！', desc: '一切准备就绪，开始探索您的桌面级智能风洞吧', btn: '开始探索'),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  void _onNext() async {
    if (_isLastPage) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboardingCompleted', true);
      if (mounted) {
        context.go('/');
      }
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              SizedBox(
                height: 200,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) {
                    final p = _pages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            p.title,
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            p.desc,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: Colors.white70, height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Spacer(flex: 2),
              // 页面指示器
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 16 : 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),
              // 按钮
              SizedBox(
                width: 320,
                height: 58,
                child: ElevatedButton(
                  onPressed: _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(29)),
                  ),
                  child: Text(
                    page.btn,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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
