// ══════════════════════════════════════════════════════════════════
// STEER: 反臃肿 | scope=ble-provider | 修改前读 anti-bloat.md
//
// 职责: BLE 连接状态管理 — 扫描/连接/断开/重连 + 收发
//       基于 RideWind ble_service.dart 设计重构
// 不做什么: 不处理业务命令格式（由 ble_command_provider 负责）
// ══════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble_protocol.dart';

/// BLE 连接状态枚举。与 RideWind 一致。
enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  discoveringServices,
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
  final List<ScanResult> scanResults;
  final int mtu;

  const BleDeviceState({
    this.connectionState = BleConnectionState.disconnected,
    this.device,
    this.characteristic,
    this.deviceName,
    this.rssi = 0,
    this.errorMessage,
    this.scanResults = const [],
    this.mtu = 20,
  });

  BleDeviceState copyWith({
    BleConnectionState? connectionState,
    BluetoothDevice? device,
    BluetoothCharacteristic? characteristic,
    String? deviceName,
    int? rssi,
    String? errorMessage,
    List<ScanResult>? scanResults,
    int? mtu,
  }) {
    return BleDeviceState(
      connectionState: connectionState ?? this.connectionState,
      device: device ?? this.device,
      characteristic: characteristic ?? this.characteristic,
      deviceName: deviceName ?? this.deviceName,
      rssi: rssi ?? this.rssi,
      errorMessage: errorMessage,
      scanResults: scanResults ?? this.scanResults,
      mtu: mtu ?? this.mtu,
    );
  }

  bool get isConnected => connectionState == BleConnectionState.connected;
  bool get isScanning => connectionState == BleConnectionState.scanning;
  bool get isConnecting => connectionState == BleConnectionState.connecting;
}

/// BLE 连接 Notifier — 基于 RideWind BLEService 完整设计。
class BleConnectionNotifier extends Notifier<BleDeviceState> {
  StreamSubscription<BluetoothAdapterState>? _adapterStateSub;
  StreamSubscription<List<ScanResult>>? _scanResultSub;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSub;
  StreamSubscription<List<int>>? _notifySub;
  Timer? _scanTimeout;
  int _effectiveMtu = 20;

  // RX stream
  final _rxController = StreamController<List<int>>.broadcast();
  Stream<List<int>> get rxStream => _rxController.stream;

  @override
  BleDeviceState build() {
    _initAdapterListener();
    ref.onDispose(_cleanup);
    return const BleDeviceState();
  }

  void _initAdapterListener() {
    _adapterStateSub = FlutterBluePlus.adapterState.listen((adapterState) {
      if (adapterState == BluetoothAdapterState.off ||
          adapterState == BluetoothAdapterState.unknown) {
        this.state = const BleDeviceState(); // reset on BT off
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════
  //  扫描 — 借鉴 RideWind: 不过滤，APP 侧按名称/服务筛选
  // ═══════════════════════════════════════════════════════════════

  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    if (state.isScanning) return;

    await FlutterBluePlus.stopScan();

    state = state.copyWith(
      connectionState: BleConnectionState.scanning,
      errorMessage: null,
      scanResults: [],
    );

    _scanResultSub = FlutterBluePlus.scanResults.listen((results) {
      // 按设备名 "T1" 和服务 UUID 含 0xFFE0 两种方式筛选（RideWind 方式）
      final filtered = results.where((r) {
        final name = r.device.platformName.isNotEmpty
            ? r.device.platformName
            : r.advertisementData.advName;
        if (name == kDeviceName) return true;

        final hasFFE0 = r.advertisementData.serviceUuids.any(
          (uuid) => uuid.toString().toLowerCase().contains('ffe0'),
        );
        if (hasFFE0) return true;

        return false;
      }).toList();
      state = state.copyWith(scanResults: filtered);
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: true,
      );
    } catch (e) {
      state = state.copyWith(
        connectionState: BleConnectionState.disconnected,
        errorMessage: '蓝牙不可用，请检查设置',
      );
      return;
    }

    // 等待扫描完毕（isScanning 变为 false） — 必须 await
    await FlutterBluePlus.isScanning
        .where((v) => v == false)
        .first
        .timeout(timeout + const Duration(seconds: 3), onTimeout: () => false);

    await FlutterBluePlus.stopScan();
    _scanResultSub?.cancel();
    _scanResultSub = null;

    if (state.isScanning) {
      state = state.copyWith(connectionState: BleConnectionState.disconnected);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  连接 — 借鉴 RideWind: 连接 + MTU + ConnectionPriority.high
  // ═══════════════════════════════════════════════════════════════

  Future<void> connectToDevice(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();

    state = state.copyWith(
      connectionState: BleConnectionState.connecting,
      device: device,
      deviceName: device.platformName,
    );

    try {
      // 1. 物理连接
      await device.connect(
        timeout: const Duration(seconds: 10),
        autoConnect: false,
      );

      // 2. 请求高优先级连接参数 (RideWind 关键设计)
      try {
        await device.requestConnectionPriority(
          connectionPriorityRequest: ConnectionPriority.high,
        );
      } catch (_) {
        // 非关键，继续
      }

      // 3. MTU 协商
      try {
        final mtu = await device.requestMtu(kMtuSize);
        _effectiveMtu = mtu - 3;
        if (_effectiveMtu < 20) _effectiveMtu = 20;
        state = state.copyWith(mtu: mtu);
      } catch (_) {
        _effectiveMtu = 20;
      }

      // 4. 监听连接状态
      _connectionStateSub = device.connectionState.listen((s) {
        if (s == BluetoothConnectionState.disconnected) {
          state = state.copyWith(
            connectionState: BleConnectionState.disconnected,
            characteristic: null,
            errorMessage: '设备已断开',
          );
          _connectionStateSub?.cancel();
          _connectionStateSub = null;
          _notifySub?.cancel();
          _notifySub = null;
        }
      });

      // 5. 发现服务
      state = state.copyWith(connectionState: BleConnectionState.discoveringServices);

      final services = await device.discoverServices();
      BluetoothCharacteristic? target;

      for (var svc in services) {
        if (!svc.uuid.toString().toLowerCase().contains('ffe0')) continue;
        for (var ch in svc.characteristics) {
          if (!ch.uuid.toString().toLowerCase().contains('ffe1')) continue;
          target = ch;
          break;
        }
        if (target != null) break;
      }

      if (target == null) {
        throw Exception('未找到 FFE1 特征');
      }

      // 6. 订阅 notify (RideWind 关键设计)
      if (target.properties.notify) {
        await target.setNotifyValue(true);
        _notifySub = target.lastValueStream.listen((data) {
          if (data.isNotEmpty) {
            _rxController.add(data);
          }
        });
      }

      state = state.copyWith(
        connectionState: BleConnectionState.connected,
        characteristic: target,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        connectionState: BleConnectionState.disconnected,
        errorMessage: '连接失败，请重试',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  发送 — 借鉴 RideWind 分包逻辑
  // ═══════════════════════════════════════════════════════════════

  Future<bool> sendCommand(String command) async {
    final characteristic = state.characteristic;
    if (characteristic == null || !state.isConnected) return false;

    try {
      final bytes = '$command\n'.codeUnits;
      final chunkSize = _effectiveMtu;

      if (bytes.length <= chunkSize) {
        await characteristic.write(bytes, withoutResponse: true);
      } else {
        for (int i = 0; i < bytes.length; i += chunkSize) {
          final end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
          await characteristic.write(bytes.sublist(i, end), withoutResponse: true);
          if (end < bytes.length) {
            await Future.delayed(const Duration(milliseconds: 2));
          }
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  断开
  // ═══════════════════════════════════════════════════════════════

  Future<void> disconnect() async {
    final device = state.device;
    if (device != null) {
      await device.disconnect();
    }
    _cleanConnection();
    state = const BleDeviceState();
  }

  void _cleanConnection() {
    _connectionStateSub?.cancel();
    _connectionStateSub = null;
    _notifySub?.cancel();
    _notifySub = null;
  }

  void _cleanup() {
    _adapterStateSub?.cancel();
    _scanResultSub?.cancel();
    _scanTimeout?.cancel();
    _cleanConnection();
    FlutterBluePlus.stopScan();
    _rxController.close();
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
