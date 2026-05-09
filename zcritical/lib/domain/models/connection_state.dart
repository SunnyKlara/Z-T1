// ══════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=60 | scope=domain | 修改前读 anti-bloat.md
// ══════════════════════════════════════════════════════════════
// 职责：设备连接状态枚举 — disconnected / connecting / connected / disconnecting
// 不做什么：不含状态管理逻辑（由 Provider 层处理）

/// 设备 BLE 连接状态（区别于 Flutter 的 [ConnectionState]）。
enum DeviceConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
}

extension DeviceConnectionStateExt on DeviceConnectionState {
  bool get isConnected => this == DeviceConnectionState.connected;
  bool get isConnecting => this == DeviceConnectionState.connecting;
  bool get isIdle => this == DeviceConnectionState.disconnected;
}
