// ══════════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=40 | scope=app-domain | 修改前读 anti-bloat.md
//
// 职责: BLE 连接状态枚举 — disconnected/connecting/connected/disconnecting
// 不做什么: 不包含连接逻辑，不依赖 Flutter
// ══════════════════════════════════════════════════════════════════
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
