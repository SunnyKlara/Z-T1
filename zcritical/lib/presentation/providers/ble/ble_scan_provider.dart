// ══════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=150 | scope=app-presentation | 修改前读 anti-bloat.md
// ══════════════════════════════════════════════════════════════
// 职责：BLE 扫描 Provider — 扫描状态 + 设备列表
// 不做什么：不管理连接（ble_connection_provider）

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 扫描状态。
enum BleScanState {
  idle,
  scanning,
  stopped,
}

/// 扫描到的设备信息（骨架用）。
class DiscoveredDevice {
  final String id;
  final String name;
  final int rssi;

  const DiscoveredDevice({required this.id, required this.name, this.rssi = -100});

  @override
  String toString() => 'DiscoveredDevice($name, rssi=$rssi)';
}

/// 扫描状态 Provider。
final bleScanStateProvider = StateNotifierProvider<BleScanNotifier, BleScanState>((ref) {
  return BleScanNotifier();
});

class BleScanNotifier extends StateNotifier<BleScanState> {
  BleScanNotifier() : super(BleScanState.idle);

  void startScan() => state = BleScanState.scanning;
  void stopScan() => state = BleScanState.stopped;
  void reset() => state = BleScanState.idle;
}

/// 已扫描设备列表 Provider。
final discoveredDevicesProvider = StateNotifierProvider<DiscoveredDevicesNotifier, List<DiscoveredDevice>>((ref) {
  return DiscoveredDevicesNotifier();
});

class DiscoveredDevicesNotifier extends StateNotifier<List<DiscoveredDevice>> {
  DiscoveredDevicesNotifier() : super([]);

  void addOrUpdate(DiscoveredDevice device) {
    final idx = state.indexWhere((d) => d.id == device.id);
    if (idx == -1) {
      state = [...state, device];
    } else {
      state = [...state]..[idx] = device;
    }
  }

  void clear() => state = [];
}

/// 派生 Provider：扫描到的 T1 设备（按名称过滤 + 按信号强度排序）。
final t1DevicesProvider = Provider<List<DiscoveredDevice>>((ref) {
  final devices = ref.watch(discoveredDevicesProvider);
  final t1List = devices.where((d) => d.name.contains('T1')).toList();
  t1List.sort((a, b) => b.rssi.compareTo(a.rssi));
  return t1List;
});
