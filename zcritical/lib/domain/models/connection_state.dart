// ZCritical 连接状态枚举
//
// 设计意图：
// - BLE 连接的生命周期状态。所有 Provider 和 UI 统一使用此枚举判断连接状态。
// - 纯 Dart 枚举，零依赖。domain 层可直接使用。
// - 提供 isConnected / isBusy 便捷 getter，避免 UI 层写复杂的 switch 判断。
//
// 不做什么：
// - 不包含连接参数（设备地址、MTU 等）——那些在 Device 模型里。
// - 不包含错误详情——错误用 Result.failure() 传递。

/// BLE 设备连接状态。
enum ConnectionState {
  /// 未连接，空闲状态。
  disconnected,

  /// 正在扫描或连接中。
  connecting,

  /// 已连接，可正常通信。
  connected,

  /// 正在断开连接。
  disconnecting;

  /// 当前是否处于稳定连接状态。
  bool get isConnected => this == ConnectionState.connected;

  /// 当前是否正在执行连接/断开操作（UI 应显示 loading）。
  bool get isBusy =>
      this == ConnectionState.connecting ||
      this == ConnectionState.disconnecting;
}
