// ══════════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=80 | scope=ble-status-gate | 修改前读 anti-bloat.md
//
// 职责: BLE 状态门控 — 决定路由去向（Splash 页使用）
// 不做什么: 不处理连接细节、不管理 UI
// ══════════════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/providers.dart';

/// 路由目标枚举。
enum RouteTarget {
  /// 首次使用，需要引导
  onboarding,
  /// 设备未连接，需要连接
  home,
  /// 设备已连接，进入主页
  homeConnected,
}

/// BLE 状态门控 Provider — 供 Splash 页决定路由去向。
final bleStatusGateProvider = Provider<RouteTarget>((ref) {
  final bleState = ref.watch(bleConnectionProvider);

  // 已连接 → 直接进入主页
  if (bleState.isConnected) {
    return RouteTarget.homeConnected;
  }

  // 未连接 → 进入主页（主页内处理连接引导）
  return RouteTarget.home;
});
