// ══════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=150 | scope=app-presentation | 修改前读 anti-bloat.md
// ══════════════════════════════════════════════════════════════
// 职责：BLE 适配器状态 Provider — 蓝牙开关/权限/可用性
// 不做什么：不管理扫描结果（ble_scan_provider）、不管理连接（ble_connection_provider）

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// BLE 适配器状态。
enum BleAdapterState {
  unknown,
  unavailable,
  unauthorized,
  turningOn,
  on,
  turningOff,
  off,
}

/// BLE 适配器状态 Provider。
///
/// Phase 3 绑定 flutter_blue_plus 的 FlutterBlue.adapterState 流。
/// 当前为骨架阶段，提供受控的初始值供 UI 层使用。
final bleStatusProvider = StateNotifierProvider<BleStatusNotifier, BleAdapterState>((ref) {
  return BleStatusNotifier();
});

class BleStatusNotifier extends StateNotifier<BleAdapterState> {
  BleStatusNotifier() : super(BleAdapterState.unknown);

  /// 更新适配器状态（后续由 data 层回调驱动）。
  void update(BleAdapterState newState) {
    if (state != newState) state = newState;
  }
}

/// 派生 Provider：蓝牙是否可用（已开启 + 已授权）。
final isBleAvailableProvider = Provider<bool>((ref) {
  final status = ref.watch(bleStatusProvider);
  return status == BleAdapterState.on;
});
