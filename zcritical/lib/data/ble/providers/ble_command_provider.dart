// ══════════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=80 | scope=ble-command | 修改前读 anti-bloat.md
//
// 职责: BLE 命令发送 + 响应监听 — 业务命令统一入口
// 不做什么: 不管理连接状态（由 ble_connection_provider 负责）
// ══════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble_protocol.dart';
import 'ble_connection_provider.dart';

/// 设备状态数据类。
class DeviceState {
  final int fanPercent;
  final int speedDisplay;
  final String speedUnit;
  final bool wuhuaOn;
  final int brightness;
  final bool streamlightOn;
  final int lcdOn;
  final int uiMode;
  final int volume;
  final bool throttleOn;
  final List<int> logoSlots;
  final int ledPreset;

  const DeviceState({
    this.fanPercent = 0,
    this.speedDisplay = 0,
    this.speedUnit = 'kmh',
    this.wuhuaOn = false,
    this.brightness = 80,
    this.streamlightOn = false,
    this.lcdOn = 1,
    this.uiMode = 1,
    this.volume = 50,
    this.throttleOn = false,
    this.logoSlots = const [0, 0, 0, 0],
    this.ledPreset = 1,
  });

  DeviceState copyWith({
    int? fanPercent,
    int? speedDisplay,
    String? speedUnit,
    bool? wuhuaOn,
    int? brightness,
    bool? streamlightOn,
    int? lcdOn,
    int? uiMode,
    int? volume,
    bool? throttleOn,
    List<int>? logoSlots,
    int? ledPreset,
  }) {
    return DeviceState(
      fanPercent: fanPercent ?? this.fanPercent,
      speedDisplay: speedDisplay ?? this.speedDisplay,
      speedUnit: speedUnit ?? this.speedUnit,
      wuhuaOn: wuhuaOn ?? this.wuhuaOn,
      brightness: brightness ?? this.brightness,
      streamlightOn: streamlightOn ?? this.streamlightOn,
      lcdOn: lcdOn ?? this.lcdOn,
      uiMode: uiMode ?? this.uiMode,
      volume: volume ?? this.volume,
      throttleOn: throttleOn ?? this.throttleOn,
      logoSlots: logoSlots ?? this.logoSlots,
      ledPreset: ledPreset ?? this.ledPreset,
    );
  }
}

/// BLE 命令 Notifier。
class BleCommandNotifier extends Notifier<DeviceState> {
  StreamSubscription<List<int>>? _responseSub;

  @override
  DeviceState build() {
    ref.onDispose(_cleanup);
    _startListening();
    return const DeviceState();
  }

  void _startListening() {
    final connState = ref.watch(bleConnectionProvider);
    final characteristic = connState.characteristic;
    if (characteristic == null) return;

    _responseSub = characteristic.onValueReceived.listen((bytes) {
      final response = String.fromCharCodes(bytes).trim();
      _handleResponse(response);
    });
  }

  void _handleResponse(String response) {
    if (BleResponses.isOk(response)) return;
    if (BleResponses.isErr(response)) return;

    if (response.startsWith('STATUS:')) {
      final map = BleResponses.parseStatus(response);
      state = state.copyWith(
        fanPercent: int.tryParse(map['FAN'] ?? '0') ?? 0,
        wuhuaOn: map['WUHUA'] == '1',
        brightness: int.tryParse(map['BRIGHT'] ?? '80') ?? 80,
        streamlightOn: map['STREAMLIGHT'] == '1',
        lcdOn: int.tryParse(map['LCD'] ?? '1') ?? 1,
        uiMode: int.tryParse(map['UI'] ?? '1') ?? 1,
        volume: int.tryParse(map['VOL'] ?? '50') ?? 50,
        throttleOn: map['THROTTLE'] == '1',
      );
    } else if (response.startsWith('SPEED_REPORT:')) {
      final report = BleResponses.parseSpeedReport(response);
      if (report != null) {
        state = state.copyWith(
          speedDisplay: report.$1,
          speedUnit: report.$2,
        );
      }
    } else if (response.startsWith('PRESET_REPORT:')) {
      final preset = BleResponses.parsePresetReport(response);
      if (preset != null) {
        state = state.copyWith(ledPreset: preset);
      }
    } else if (response.startsWith('LOGO_SLOTS:')) {
      state = state.copyWith(logoSlots: BleResponses.parseLogoSlots(response));
    }
  }

  /// 发送命令。
  Future<bool> send(String command) async {
    return ref.read(bleConnectionProvider.notifier).sendCommand(command);
  }

  /// 查询全部状态。
  Future<void> refreshAll() async {
    await send(BleCommands.getAll);
  }

  /// 设置风扇。
  Future<void> setFan(int percent) async {
    await send(BleCommands.fan(percent.clamp(0, 100)));
  }

  /// 设置速度显示。
  Future<void> setSpeed(int display) async {
    await send(BleCommands.speed(display));
  }

  /// 设置加湿器。
  Future<void> setWuhua(bool on) async {
    await send(BleCommands.wuhua(on ? 1 : 0));
  }

  /// 设置 LED。
  Future<void> setLed(int strip, int r, int g, int b) async {
    await send(BleCommands.led(strip, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255)));
  }

  /// 设置 LED 预设。
  Future<void> setPreset(int n) async {
    await send(BleCommands.preset(n.clamp(1, 14)));
  }

  /// 设置亮度。
  Future<void> setBrightness(int percent) async {
    await send(BleCommands.bright(percent.clamp(0, 100)));
  }

  /// 设置流水灯。
  Future<void> setStreamlight(bool on) async {
    await send(BleCommands.streamlight(on ? 1 : 0));
  }

  /// 设置 LCD。
  Future<void> setLcd(bool on) async {
    await send(BleCommands.lcd(on ? 1 : 0));
  }

  /// 设置 UI 模式。
  Future<void> setUiMode(int mode) async {
    await send(BleCommands.ui(mode.clamp(1, 8)));
  }

  /// 设置音量。
  Future<void> setVolume(int percent) async {
    await send(BleCommands.vol(percent.clamp(0, 100)));
  }

  /// 设置油门模式。
  Future<void> setThrottle(bool on) async {
    await send(BleCommands.throttle(on ? 1 : 0));
  }

  /// 查询 Logo 槽位。
  Future<void> refreshLogoSlots() async {
    await send(BleCommands.getLogo);
  }

  void _cleanup() {
    _responseSub?.cancel();
  }
}

/// BLE 命令 Provider。
final bleCommandProvider =
    NotifierProvider<BleCommandNotifier, DeviceState>(
  BleCommandNotifier.new,
);
