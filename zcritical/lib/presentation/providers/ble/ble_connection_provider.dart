// ══════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=150 | scope=app-presentation | 修改前读 anti-bloat.md
// ══════════════════════════════════════════════════════════════
// 职责：BLE 连接状态 Provider — 目标设备 + 连接/断开/状态流转
// 不做什么：不管理扫描（ble_scan_provider）、不管理适配器状态（ble_status_provider）

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/connection_state.dart';

/// 已连接设备信息。
class ConnectedDevice {
  final String id;
  final String name;

  const ConnectedDevice({required this.id, required this.name});
}

/// 连接状态 Provider（骨架阶段，Phase 3 绑定 ble_connection.dart 回调）。
final connectionStateProvider = StateNotifierProvider<ConnectionNotifier, DeviceConnectionState>((ref) {
  return ConnectionNotifier();
});

class ConnectionNotifier extends StateNotifier<DeviceConnectionState> {
  ConnectionNotifier() : super(DeviceConnectionState.disconnected);

  void connect(String deviceId, String deviceName) {
    state = DeviceConnectionState.connecting;
  }

  void onConnected(String deviceId, String deviceName) {
    state = DeviceConnectionState.connected;
  }

  void onDisconnected() {
    state = DeviceConnectionState.disconnected;
  }

  void disconnect() {
    state = DeviceConnectionState.disconnecting;
  }
}

/// 已连接设备 Provider。
final connectedDeviceProvider = StateProvider<ConnectedDevice?>((ref) => null);

/// 便捷 Provider：是否已连接设备。
final isDeviceConnectedProvider = Provider<bool>((ref) {
  return ref.watch(connectionStateProvider).isConnected;
});
