// ══════════════════════════════════════════════════════════════════
// STEER: 反臃肿 | scope=ble-service
//
// 职责: BLE 底层服务 — 扫描/连接/收发。基于RideWind BLEService + 调试日志
// ══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_protocol.dart';

class BleService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;

  StreamSubscription? _connectionSub;
  StreamSubscription? _notifySub;

  final _rxController = StreamController<List<int>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  int _effectiveMtu = 20;

  static const String serviceUuid = '0000ffe0-0000-1000-8000-00805f9b34fb';
  static const String charUuid = '0000ffe1-0000-1000-8000-00805f9b34fb';

  Stream<List<int>> get rxDataStream => _rxController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  int get effectiveMtu => _effectiveMtu;
  bool get isConnected =>
      _device != null && _characteristic != null && _connectionSub != null;

  static void log(String msg) {
    debugPrint('\u{1F539} [BLE] $msg');
  }

  // ═══════════════════════════════════════════════════════════════
  //  扫描 — 含调试日志
  // ═══════════════════════════════════════════════════════════════

  Future<List<ScanResult>> scanDevices({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    log('scanDevices 开始');

    final isSupported = await FlutterBluePlus.isSupported;
    log('isSupported=$isSupported');
    if (!isSupported) return [];

    final adapterState = await FlutterBluePlus.adapterState.first;
    log('adapterState=$adapterState');
    if (adapterState != BluetoothAdapterState.on) {
      log('蓝牙适配器未开启，返回空');
      return [];
    }

    await FlutterBluePlus.stopScan();
    log('开始扫描，超时=${timeout.inSeconds}s');

    // 提前订阅扫描结果流，一旦发现 T1 立即停止扫描
    final completer = Completer<void>();
    StreamSubscription<List<ScanResult>>? sub;
    sub = FlutterBluePlus.scanResults.listen((r) {
      final t1found = r.any((sr) => sr.device.platformName == kDeviceName);
      if (t1found && !completer.isCompleted) {
        log('发现 T1，立即停止扫描');
        completer.complete();
      }
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: true,
        androidScanMode: AndroidScanMode.lowLatency,
      );
    } catch (e) {
      log('startScan异常: $e');
      await sub.cancel();
      return [];
    }

    // 等待 T1 出现或扫描超时
    try {
      await completer.future.timeout(timeout + const Duration(seconds: 2));
    } catch (_) {
      // 超时未找到 T1，正常继续
    }
    log('扫描结束');

    await sub.cancel();
    await FlutterBluePlus.stopScan();

    // 重新获取最新扫描结果
    final results = FlutterBluePlus.lastScanResults;
    log('扫描结果: ${results.length} 个设备');
    for (var r in results) {
      final svcIds = r.advertisementData.serviceUuids
          .map((u) {
            final s = u.toString();
            return s.length >= 8 ? s.replaceAll('-', '').substring(0, 8) : s;
          })
          .toList();
      log('  设备: name=${r.device.platformName}, rssi=${r.rssi}, services=$svcIds');
    }

    final filtered = results.where((r) {
      final hasFFE0 = r.advertisementData.serviceUuids.any(
        (uuid) => uuid.toString().toLowerCase().contains('ffe0'),
      );
      final name = r.device.platformName.toUpperCase();
      final match = hasFFE0 || name == kDeviceName;
      if (!match) {
        log('  过滤掉: name=$name, hasFFE0=$hasFFE0');
      }
      return match;
    }).toList();

    log('过滤后: ${filtered.length} 个匹配设备');
    return filtered;
  }

  // ═══════════════════════════════════════════════════════════════
  //  连接
  // ═══════════════════════════════════════════════════════════════

  Future<bool> connect(BluetoothDevice device) async {
    log('connect 开始: ${device.platformName}');
    try {
      _cleanupConnection();
      _device = device;

      log('[1/4] 物理连接...');
      await device.connect(
        timeout: const Duration(seconds: 10),
        autoConnect: false,
      );
      log('[1/4] 物理连接成功');

      _connectionSub = device.connectionState.listen((s) {
        if (s == BluetoothConnectionState.disconnected) {
          log('连接断开');
          _cleanupConnection();
          _connectionController.add(false);
        }
      });

      // 读取当前 MTU，如已达标则跳过二次协商
      final currentMtu = device.mtuNow;
      if (currentMtu >= kMtuSize) {
        _effectiveMtu = currentMtu - 3;
        log('[2/4] MTU 已达标 ($currentMtu)，跳过协商');
      } else {
        log('[2/4] MTU协商 (当前=$currentMtu)...');
        try {
          final mtu = await device.requestMtu(kMtuSize);
          _effectiveMtu = mtu - 3;
          if (_effectiveMtu < 20) _effectiveMtu = 20;
          log('[2/4] MTU=$mtu, 有效载荷=$_effectiveMtu');
        } catch (e) {
          _effectiveMtu = 20;
          log('[2/4] MTU协商失败: $e');
        }
      }

      try {
        await device.requestConnectionPriority(
          connectionPriorityRequest: ConnectionPriority.high,
        );
        log('连接优先级=high');
      } catch (_) {}

      log('[3/4] 发现服务...');
      final services = await device.discoverServices();
      log('[3/4] ${services.length} 个服务');

      for (var svc in services) {
        try {
          final svcStr = svc.uuid.toString();
          final svcShort = svcStr.length >= 8 ? svcStr.replaceAll('-', '').substring(0, 8) : svcStr;
          log('  服务: $svcShort (raw=$svcStr)');
          if (!svcStr.toLowerCase().contains('ffe0')) continue;
          for (var ch in svc.characteristics) {
            try {
              final chStr = ch.uuid.toString();
              final chShort = chStr.length >= 8 ? chStr.replaceAll('-', '').substring(0, 8) : chStr;
              log('    特征: $chShort (raw=$chStr)');
              if (!chStr.toLowerCase().contains('ffe1')) continue;
              _characteristic = ch;

              if (ch.properties.notify) {
                await ch.setNotifyValue(true);
                _notifySub = ch.lastValueStream.listen((data) {
                  if (data.isNotEmpty) _rxController.add(data);
                });
                log('[4/4] FFE1就绪 (write+notify)');
              }
              break;
            } catch (e2) {
              log('    特征解析异常: $e2');
            }
          }
          if (_characteristic != null) break;
        } catch (e) {
          log('  服务解析异常: $e');
        }
      }

      if (_characteristic == null) {
        log('未找到FFE1');
        _cleanupConnection();
        return false;
      }

      _connectionController.add(true);
      log('连接完成');
      return true;
    } catch (e) {
      log('连接异常: $e');
      _cleanupConnection();
      return false;
    }
  }

  Future<void> sendData(List<int> data) async {
    if (_characteristic == null) return;
    final chunkSize = _effectiveMtu;

    if (data.length <= chunkSize) {
      await _characteristic!.write(data, withoutResponse: true);
    } else {
      for (int i = 0; i < data.length; i += chunkSize) {
        final end =
            (i + chunkSize < data.length) ? i + chunkSize : data.length;
        await _characteristic!.write(data.sublist(i, end),
            withoutResponse: true);
        if (end < data.length) {
          await Future.delayed(const Duration(milliseconds: 2));
        }
      }
    }
  }

  Future<void> sendString(String text) async {
    await sendData(text.codeUnits);
  }

  Future<void> disconnect() async {
    try {
      await _device?.disconnect();
    } catch (_) {}
    _cleanupConnection();
    _device = null;
    _connectionController.add(false);
  }

  void _cleanupConnection() {
    _connectionSub?.cancel();
    _connectionSub = null;
    _notifySub?.cancel();
    _notifySub = null;
    _characteristic = null;
  }

  void dispose() {
    _cleanupConnection();
    _device = null;
    _rxController.close();
    _connectionController.close();
  }
}
