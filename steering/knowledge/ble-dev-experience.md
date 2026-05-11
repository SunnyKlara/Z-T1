# BLE 开发实战经验 — ZCritical T1

> 2026-05-11 · 基于 3 轮实机调试总结 · ESP32-S3 + Flutter (flutter_blue_plus 1.35.2) + Android MIUI

---

## 一、连接全链路（已验证可用）

```
扫描(1.5s) → 物理连接(0.3s) → MTU=247(0.6s) → 连接优先级=high → discoverServices(3服务) → 匹配FFE0/FFE1 → setNotifyValue → 连接完成
```

**关键参数**: `autoConnect: false`, `AndroidScanMode.lowLatency`, `androidUsesFineLocation: true`

---

## 二、踩过的坑 & 解决方案

### 坑1：`substring(4,8)` RangeError — UUID 格式不统一

| | 详情 |
|---|---|
| **现象** | `RangeError (end): Invalid value: Not in inclusive range 0..4: 8` |
| **根因** | ESP32 BLE 返回 16-bit UUID 的 `Guid.toString()` 可能只返回 4 字符短格式（如 `"1800"`），而非标准 `"00001800-..."`。`substring(0,8)` 在 Dart 中虽会自动截断，但若先 `replaceAll('-','')` 再取 `substring(N,8)` 且 N>0 时仍可能越界 |
| **实际触发** | `flutter_blue_plus` 对 ESP32 的 16-bit UUID（`0x1800`, `0x1801`, `0xFFE0`）返回的是**不带破折号的短格式**（`"1800"`, `"ffe0"`），而非完整 128-bit |
| **修复** | 所有 UUID 打印/截取前加 `length >= 8` 判断 + try/catch 兜底 |
| **教训** | ⚠️ **不要假设 BLE UUID 的 toString() 格式**。不同设备/系统返回格式不同。永远做防御性处理 |

```dart
// ❌ 危险 — 假设 UUID 总是长格式
final short = uuid.toString().replaceAll('-', '').substring(0, 8);

// ✅ 安全
final raw = uuid.toString();
final short = raw.length >= 8 ? raw.replaceAll('-', '').substring(0, 8) : raw;
```

### 坑2：`device.connect()` 静默失败 — MIUI 权限

| | 详情 |
|---|---|
| **现象** | 扫描正常（T1 rssi=-26），弹窗出现，点击"进入控制界面"→ 无连接日志 → 显示"连接失败" |
| **根因** | MIUI Android 12+ 对 `BLUETOOTH_CONNECT` 权限要求运行时显式请求，且 `Permission.bluetoothConnect.request()` 可能不弹系统对话框（静默拒绝） |
| **修复** | `_connectToDevice()` 前加 `Permission.bluetoothConnect.status` 检查，未授权则 `request()`，仍不授权则引导用户去设置 |
| **教训** | ⚠️ **MIUI 是 BLE 权限的测试地狱**。`BLUETOOTH_SCAN` + `BLUETOOTH_CONNECT` + `ACCESS_FINE_LOCATION` 缺一不可。扫描和连接是两套不同的权限生命周期 |

### 坑3：MTU 二次协商 — 浪费时间

| | 详情 |
|---|---|
| **现象** | 连接时间 ~1.4s，其中 MTU 协商占了 ~1s（两次） |
| **根因** | `flutter_blue_plus` 在 `connect()` 内部自动发起 MTU=512 的协商（Android 原生行为），我们代码又调 `requestMtu(247)`，触发第二次 |
| **修复** | 读取 `device.mtuNow`，如已达标则跳过 `requestMtu()` |
| **效果** | ~350ms 节省 |
| **教训** | ⚠️ 调用 `requestMtu()` 前先检查 `mtuNow`，避免无意义的二次协商 |

### 坑4：扫描等待固定超时 — 用户等太久

| | 详情 |
|---|---|
| **现象** | 扫描 timeout=10s + 冗余 `Future.delayed(2s)` = 每次等 12s |
| **根因** | 代码用 `Future.delayed(timeout+2s)` 固定等待，不论 T1 是否已出现 |
| **修复** | 监听扫描结果流，一旦发现 T1 立即 `stopScan()` + `Completer.complete()` 早停 |
| **效果** | 从 ~12s → ~2s |
| **教训** | ⚠️ 扫描应该"找到目标即停"，不要傻等超时 |

### 坑5：`hot restart` 不生效 — 用了旧代码

| | 详情 |
|---|---|
| **现象** | 修改了 `substring(4,8)` → `substring(0,8)`，hot restart 后仍然崩溃 |
| **根因** | Flutter hot restart/hot reload 在某些情况下（尤其是 native platform channel 相关代码）不会重新编译 Dart → native 桥接层 |
| **修复** | `flutter clean && flutter run` 全新安装 |
| **教训** | ⚠️ BLE/Dart FFI/native 相关代码修改后，必须 `flutter clean` + 完整重新运行 |

---

## 三、调试方法论

1. **加日志要有唯一 tag** — 用 `[BLE]` `[SCAN]` 这样的前缀，方便 grep
2. **每步都用 try/catch + 日志** — 像 `[1/4] 物理连接...` `[2/4] MTU协商...` 这样的阶段性日志是黄金
3. **原生日志别忽略** — `D/[FBP-Android]` `D/BluetoothGatt` 的日志最有价值，比 Dart 层日志更真实
4. **不要猜，让日志说话** — 没有日志 = 代码没跑到那一步
5. **MIUI 调试必须看 logcat** — `flutter run` 的 Dart 日志看不到 Android 原生层的问题

---

## 四、代码架构要点

- `ble_service.dart` — 底层 BLE 操作（扫描/连接/收发），不含业务逻辑
- `ble_connection_provider.dart` — Riverpod 状态管理（并行实现，当前未被 scan screen 使用）
- `device_scan_screen.dart` — 扫描 UI + 连接跳转，直接实例化 `BleService`
- `ble_protocol.dart` — UUID 常量 + 命令构建器 + 响应解析器

---

## 五、ESP32 固件端注意事项

- `include_name=true` 必须设，否则设备名不在广播包中 → APP 过滤器漏掉
- SMP disabled（`sdkconfig`），否则配对弹窗干扰
- 广播不携带 Service UUID（APP 按名称过滤）

---

*2026-05-11 · BLE 连接全链路打通*
