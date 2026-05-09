// ══════════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=80 | scope=app-domain | 修改前读 anti-bloat.md
//
// 职责: BLE 设备模型 — 从扫描结果构造，手写模型（非 freezed）
// 不做什么: 不依赖 Flutter、不包含 BLE 通信逻辑
// ══════════════════════════════════════════════════════════════════
// - 实现 == / hashCode / toString，方便 Provider 中状态比较。
//
// 不做什么：
// - 不包含 BLE 连接对象（flutter_blue_plus 的 BluetoothDevice）——那是 data 层的事。
// - 不包含实时传感器数据——那些在各自的 Provider 里。

import 'connection_state.dart';

/// 风洞设备。
class Device {
  /// BLE 设备唯一标识（远端 ID）。
  final String deviceId;

  /// 设备名称（如 "RideWind-001"）。
  final String name;

  /// 信号强度，单位 dBm。
  final int rssi;

  /// 制造商名称（扫描时解析）。
  final String? manufacturerName;

  /// 当前连接状态。
  final ConnectionState connectionState;

  /// 上次接收到数据的时间戳。
  final DateTime? lastSeenAt;

  const Device({
    required this.deviceId,
    required this.name,
    this.rssi = -100,
    this.manufacturerName,
    this.connectionState = ConnectionState.disconnected,
    this.lastSeenAt,
  });

  /// 从 BLE 扫描结果创建（简化构造，后续 data 层扩展）。
  factory Device.fromScan({
    required String deviceId,
    required String name,
    required int rssi,
    String? manufacturerName,
  }) {
    return Device(
      deviceId: deviceId,
      name: name,
      rssi: rssi,
      manufacturerName: manufacturerName,
    );
  }

  /// 拷贝并修改部分字段。
  Device copyWith({
    String? deviceId,
    String? name,
    int? rssi,
    String? manufacturerName,
    ConnectionState? connectionState,
    DateTime? lastSeenAt,
    bool clearManufacturerName = false,
  }) {
    return Device(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      manufacturerName:
          clearManufacturerName ? null : manufacturerName ?? this.manufacturerName,
      connectionState: connectionState ?? this.connectionState,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  /// 更新连接状态（便捷方法）。
  Device withConnectionState(ConnectionState state) => copyWith(
        connectionState: state,
        lastSeenAt: state.isConnected ? DateTime.now() : lastSeenAt,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Device && other.deviceId == deviceId;
  }

  @override
  int get hashCode => deviceId.hashCode;

  @override
  String toString() =>
      'Device(deviceId: $deviceId, name: $name, rssi: $rssi, '
      'state: ${connectionState.name})';
}
