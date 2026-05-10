// ══════════════════════════════════════════════════════════════════
// STEER: 反臃肿 | scope=app-presentation | 修改前读 anti-bloat.md
//
// 职责: 主控制页 — 紧凑布局：顶部导航栏 + 风洞模型(缩小下沉) + 控制面板
//       ☰汉堡菜单在右上角 → 下拉（用户中心 / Logo管理）
// 不做什么: 不处理BLE逻辑、不包含面板实现
// ══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'home_page_view.dart';
import '../../widgets/wind_tunnel_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(children: [
          // 顶部导航栏：返回 + 汉堡菜单
          _TopBar(
            onMenuTap: (menuPosition) => _showDropdown(context, menuPosition),
          ),
          // 风洞模型（紧凑，下沉）
          SizedBox(
            height: screenHeight * 0.28,
            child: const WindTunnelView(),
          ),
          // 控制面板（撑满剩余）
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: HomePageView(),
            ),
          ),
        ]),
      ),
    );
  }

  static void _showDropdown(BuildContext context, Offset menuPosition) {
    final overlay = Overlay.of(context);
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (_) => _DropdownMenu(
        position: menuPosition,
        onSelect: (route) {
          entry?.remove();
          context.push(route);
        },
        onDismiss: () => entry?.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

/// 顶部导航栏
class _TopBar extends StatelessWidget {
  final void Function(Offset menuPosition) onMenuTap;
  const _TopBar({required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xCCFFFFFF), size: 22),
              onPressed: () {
                if (context.canPop()) context.pop();
              },
            ),
            const Spacer(),
            Builder(
              builder: (ctx) => _MenuButton(
                onTap: () {
                  final renderBox = ctx.findRenderObject() as RenderBox;
                  final pos = renderBox.localToGlobal(Offset.zero);
                  final size = renderBox.size;
                  onMenuTap(Offset(pos.dx + size.width - 180, pos.dy + size.height + 6));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ☰ 汉堡按钮 — 三条横线
class _MenuButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MenuButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (_) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Container(
              width: 18, height: 2,
              decoration: BoxDecoration(
                color: const Color(0xCCFFFFFF),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          )),
        ),
      ),
    );
  }
}

/// 汉堡下拉菜单
class _DropdownMenu extends StatelessWidget {
  final Offset position;
  final Function(String route) onSelect;
  final VoidCallback onDismiss;

  const _DropdownMenu({
    required this.position,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onDismiss,
      child: Stack(
        children: [
          Positioned(
            left: position.dx,
            top: position.dy,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withAlpha(12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(150),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dropItem(Icons.person_outline, '用户中心', '/user-center'),
                    Divider(height: 1, thickness: 0.5, color: Colors.white.withAlpha(15)),
                    _dropItem(Icons.image_outlined, 'Logo 管理', '/logo'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropItem(IconData icon, String title, String route) {
    return InkWell(
      onTap: () => onSelect(route),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Icon(icon, color: Colors.white.withAlpha(200), size: 20),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
        ]),
      ),
    );
  }
}
