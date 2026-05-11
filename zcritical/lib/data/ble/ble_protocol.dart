// ══════════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=80 | scope=ble-protocol | 修改前读 anti-bloat.md
//
// 职责: BLE 协议常量 + 命令构建器 — 软硬件通信唯一真值源
// 不做什么: 不处理连接逻辑、不管理状态
// 契约: steering/specs/protocol-contract.md
// ══════════════════════════════════════════════════════════════════

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// BLE 服务/特征 UUID（固件硬编码）。
abstract final class BleUuids {
  static const service = '0000ffe0-0000-1000-8000-00805f9b34fb';
  static const characteristic = '0000ffe1-0000-1000-8000-00805f9b34fb';
}

/// 设备广播名称。
const String kDeviceName = 'T1';

/// MTU 协商目标值。
const int kMtuSize = 247;

/// 命令构建器 — 所有发往固件的命令统一在此构建。
abstract final class BleCommands {
  /// 风扇控制 0-100。
  static String fan(int percent) => 'FAN:$percent';

  /// 运行速度 0-340(kmh) 或 0-211(mph)。
  static String speed(int display) => 'SPEED:$display';

  /// 加湿器 0=关, 1=开。
  static String wuhua(int on) => 'WUHUA:$on';

  /// LED 单灯带 RGB 设置 s:1-2, r,g,b:0-255。
  static String led(int strip, int r, int g, int b) => 'LED:$strip:$r:$g:$b';

  /// LED 预设 1-14。
  static String preset(int n) => 'PRESET:$n';

  /// 全局亮度 0-100。
  static String bright(int percent) => 'BRIGHT:$percent';

  /// 流水灯开关 0=关, 1=开。
  static String streamlight(int on) => 'STREAMLIGHT:$on';

  /// LED 渐变过渡 spd:0-2。
  static String ledGradient(int strip, int r, int g, int b, int spd) =>
      'LED_GRADIENT:$strip:$r:$g:$b:$spd';

  /// LCD 0=熄屏, 1=开屏。
  static String lcd(int on) => 'LCD:$on';

  /// UI 界面切换 1-8。
  static String ui(int mode) => 'UI:$mode';

  /// 音量 0-100。
  static String vol(int percent) => 'VOL:$percent';

  /// 油门模式 0=关, 1=开。
  static String throttle(int on) => 'THROTTLE:$on';

  /// 查询全部状态。
  static const String getAll = 'GET:ALL';

  /// 查询风扇状态。
  static const String getFan = 'GET:FAN';

  /// 查询 Logo 槽位。
  static const String getLogo = 'GET:LOGO';

  /// WiFi 配置。
  static String wifi(String ssid, String password) => 'WIFI:$ssid:$password';

  /// Logo 上传开始。
  static String logoStart(int slot, int size, int crc32) =>
      'LOGO_START:$slot:$size:$crc32';

  /// Logo 数据包。
  static String logoData(int seq, String hexData) => 'LOGO_DATA:$seq:$hexData';

  /// Logo 上传结束。
  static const String logoEnd = 'LOGO_END';

  /// 重启设备。
  static const String reboot = 'REBOOT';

  /// 恢复出厂设置。
  static const String factoryReset = 'FACTORY_RESET';
}

/// 响应解析器。
abstract final class BleResponses {
  /// 解析 OK 响应。
  static bool isOk(String response) => response.startsWith('OK:');

  /// 解析 ERR 响应。
  static bool isErr(String response) => response.startsWith('ERR');

  /// 解析状态报告 STATUS:FAN:50:WUHUA:1:BRIGHT:80。
  static Map<String, String> parseStatus(String response) {
    final result = <String, String>{};
    if (!response.startsWith('STATUS:')) return result;
    final parts = response.substring(7).split(':');
    for (var i = 0; i + 1 < parts.length; i += 2) {
      result[parts[i]] = parts[i + 1];
    }
    return result;
  }

  /// 解析速度上报 SPEED_REPORT:display:unit。
  static (int, String)? parseSpeedReport(String response) {
    if (!response.startsWith('SPEED_REPORT:')) return null;
    final parts = response.substring(13).split(':');
    if (parts.length < 2) return null;
    return (int.tryParse(parts[0]) ?? 0, parts[1]);
  }

  /// 解析预设上报 PRESET_REPORT:n。
  static int? parsePresetReport(String response) {
    if (!response.startsWith('PRESET_REPORT:')) return null;
    return int.tryParse(response.substring(14));
  }

  /// 解析 Logo 槽位 LOGO_SLOTS:1:0:1:0。
  static List<int> parseLogoSlots(String response) {
    if (!response.startsWith('LOGO_SLOTS:')) return [];
    return response.substring(11).split(':').map((e) => int.tryParse(e) ?? 0).toList();
  }

  /// 解析 Logo ACK LOGO_ACK:15。
  static int? parseLogoAck(String response) {
    if (!response.startsWith('LOGO_ACK:')) return null;
    return int.tryParse(response.substring(9));
  }

  /// 解析 Logo 完成 LOGO_OK:slot。
  static int? parseLogoOk(String response) {
    if (!response.startsWith('LOGO_OK:')) return null;
    return int.tryParse(response.substring(8));
  }

  /// 解析 Logo 失败 LOGO_FAIL:CRC:expected:actual。
  static (int, int)? parseLogoFail(String response) {
    if (!response.startsWith('LOGO_FAIL:CRC:')) return null;
    final parts = response.substring(14).split(':');
    if (parts.length < 2) return null;
    return (int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0);
  }

  /// 解析 Logo 就绪 LOGO_READY:slot。
  static int? parseLogoReady(String response) {
    if (!response.startsWith('LOGO_READY:')) return null;
    return int.tryParse(response.substring(11));
  }
}

/// 扩展 BluetoothCharacteristic 便捷写入。
extension BleCharacteristicExt on BluetoothCharacteristic {
  /// 发送文本命令（自动加 \n）。
  Future<void> sendCommand(String command) async {
    final bytes = '$command\n'.codeUnits;
    await write(bytes, withoutResponse: true);
  }
}
