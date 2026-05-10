// ══════════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=80 | scope=ble-provider | 修改前读 anti-bloat.md
//
// 职责: BLE 连接状态管理 — 扫描/连接/断开/重连 + 设备状态
// 不做什么: 不处理具体业务命令（由 ble_command_provider 负责）
// ══════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble_protocol.dart';

/// BLE 连接状态枚举。
enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
}

/// BLE 设备状态数据类。
class BleDeviceState {
  final BleConnectionState connectionState;
  final BluetoothDevice? device;
  final BluetoothCharacteristic? characteristic;
  final String? deviceName;
  final int rssi;
  final String? errorMessage;

  const BleDeviceState({
    this.connectionState = BleConnectionState.disconnected,
    this.device,
    this.characteristic,
    this.deviceName,
    this.rssi = 0,
    this.errorMessage,
  });

  BleDeviceState copyWith({
    BleConnectionState? connectionState,
    BluetoothDevice? device,
    BluetoothCharacteristic? characteristic,
    String? deviceName,
    int? rssi,
    String? errorMessage,
  }) {
    return BleDeviceState(
      connectionState: connectionState ?? this.connectionState,
      device: device ?? this.device,
      characteristic: characteristic ?? this.characteristic,
      deviceName: deviceName ?? this.deviceName,
      rssi: rssi ?? this.rssi,
      errorMessage: errorMessage,
    );
  }

  bool get isConnected => connectionState == BleConnectionState.connected;
  bool get isScanning => connectionState == BleConnectionState.scanning;
  bool get isConnecting => connectionState == BleConnectionState.connecting;
}

/// BLE 连接 Notifier。
class BleConnectionNotifier extends Notifier<BleDeviceState> {
  StreamSubscription<BluetoothAdapterState>? _adapterStateSub;
  StreamSubscription<List<ScanResult>>? _scanResultSub;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSub;
  Timer? _scanTimeout;

  @override
  BleDeviceState build() {
    _initAdapterListener();
    ref.onDispose(_cleanup);
    return const BleDeviceState();
  }

  void _initAdapterListener() {
    _adapterStateSub = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.unknown ||
          state == BluetoothAdapterState.unavailable) {
        // 适配器不可用时降级处理
      }
    });
  }

  /// 开始扫描设备。
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    if (state.isScanning) return;

    state = state.copyWith(
      connectionState: BleConnectionState.scanning,
      errorMessage: null,
    );

    try {
      await FlutterBluePlus.startScan(
        timeout: timeout,
        withNames: [kDeviceName],
      );

      _scanResultSub = FlutterBluePlus.scanResults.listen((results) {
        final target = results.firstWhere(
          (r) => r.device.advName == kDeviceName,
          orElse: () => results.isNotEmpty ? results.first : throw Exception(),
        );
        if (target.device.advName == kDeviceName) {
          _connectToDevice(target.device);
        }
      });

      _scanTimeout = Timer(timeout, () {
        if (state.isScanning) {
          stopScan();
          state = state.copyWith(
            connectionState: BleConnectionState.disconnected,
            errorMessage: '未找到设备，请靠近后重试',
          );
        }
      });
    } catch (e) {
      state = state.copyWith(
        connectionState: BleConnectionState.disconnected,
        errorMessage: '蓝牙不可用，请检查设置',
      );
    }
  }

  /// 停止扫描。
  void stopScan() {
    _scanTimeout?.cancel();
    _scanResultSub?.cancel();
    FlutterBluePlus.stopScan();
    if (state.isScanning) {
      state = state.copyWith(connectionState: BleConnectionState.disconnected);
    }
  }

  /// 连接到指定设备。
  Future<void> _connectToDevice(BluetoothDevice device) async {
    stopScan();

    state = state.copyWith(
      connectionState: BleConnectionState.connecting,
      device: device,
      deviceName: device.advName,
    );

    try {
      await device.connect(timeout: const Duration(seconds: 15));
      await device.discoverServices();

      final services = await device.services;
      final service = services.firstWhere(
        (s) => s.uuid.toString() == BleUuids.service,
      );
      final characteristic = service.characteristics.firstWhere(
        (c) => c.uuid.toString() == BleUuids.characteristic,
      );

      await device.requestMtu(kMtuSize);

      state = state.copyWith(
        connectionState: BleConnectionState.connected,
        characteristic: characteristic,
        errorMessage: null,
      );

      _listenToConnectionState(device);
    } catch (e) {
      state = state.copyWith(
        connectionState: BleConnectionState.disconnected,
        errorMessage: '连接失败，请重试',
      );
    }
  }

  /// 监听连接状态变化。
  void _listenToConnectionState(BluetoothDevice device) {
    _connectionStateSub = device.connectionState.listen((connState) {
      if (connState == BluetoothConnectionState.disconnected) {
        state = state.copyWith(
          connectionState: BleConnectionState.disconnected,
          characteristic: null,
          errorMessage: '设备已断开',
        );
        _connectionStateSub?.cancel();
        _connectionStateSub = null;
      }
    });
  }

  /// 断开连接。
  Future<void> disconnect() async {
    final device = state.device;
    if (device != null) {
      await device.disconnect();
    }
    _connectionStateSub?.cancel();
    _connectionStateSub = null;
    state = const BleDeviceState();
  }

  /// 发送命令。
  Future<bool> sendCommand(String command) async {
    final characteristic = state.characteristic;
    if (characteristic == null || !state.isConnected) return false;

    try {
      await characteristic.sendCommand(command);
      return true;
    } catch (e) {
      return false;
    }
  }

  void _cleanup() {
    _adapterStateSub?.cancel();
    _scanResultSub?.cancel();
    _connectionStateSub?.cancel();
    _scanTimeout?.cancel();
    FlutterBluePlus.stopScan();
  }
}

/// BLE 连接状态 Provider。
final bleConnectionProvider =
    NotifierProvider<BleConnectionNotifier, BleDeviceState>(
  BleConnectionNotifier.new,
);

/// 便捷选择器：是否已连接。
final bleIsConnectedProvider = Provider<bool>((ref) {
  return ref.watch(bleConnectionProvider).isConnected;
});

/// 便捷选择器：是否正在扫描。
final bleIsScanningProvider = Provider<bool>((ref) {
  return ref.watch(bleConnectionProvider).isScanning;
});

/// 便捷选择器：错误信息。
final bleErrorProvider = Provider<String?>((ref) {
  return ref.watch(bleConnectionProvider).errorMessage;
});
