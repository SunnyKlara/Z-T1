# ZCritical 技术风险清单

> **用途**: 重构时必须规避的坑和必须修复的债务。
> **来源**: 对 RideWind 项目 7000+ 行核心代码的深入审计。

---

## 🔴 P0 — 重构时必须修复（否则必定出Bug）

### 1. 发送队列竞态条件 (`ble_service.dart`)
**问题**: `_draining` 布尔标志在 `sendData()` 和 `_drainQueue()` 之间有 TOCTOU 竞态窗口。
**后果**: 队列可能被双重排空，导致并发发送错乱。
**修复**: 用 `Mutex` 或 `Completer` 链替代布尔标志。

### 2. 双重数据缓冲 (`bluetooth_provider.dart` + `response_router.dart`)
**问题**: 两个类各自维护 `_dataBuffer`，同一份 BLE 数据被复制两次。
**后果**: 内存浪费 + 两处缓冲区清空逻辑不一致。
**修复**: 移除 `bluetooth_provider.dart` 中的 `_dataBuffer`，只保留 `response_router.dart` 的。

### 3. iOS AudioCapture 完全未实现
**问题**: `AppDelegate.swift` 是空壳，MethodChannel 在 iOS 上 notImplemented。
**后果**: iOS 端 WiFi 音频投射功能完全不可用。
**修复**: 实现 iOS MethodChannel + `AVAudioSession` + `AudioQueue` 音频捕获。

### 4. StreamSubscription 内存泄漏
**问题**: `dispose()` 中未取消 `_bleService.rxDataStream` 的 subscription。
**后果**: BLEService 单例存活时 Stream 无限累积 listener。
**修复**: 保存 `StreamSubscription` 引用并在 dispose 中 cancel。

---

## 🟡 P1 — 高概率出Bug

### 5. ProtocolParser 正则不一致
**问题**: `parseVolume()` 用 `^VOL:`（行首锚点），`parseFanSpeed()` 用 `FAN:`（无锚点），混合使用可能导致误匹配。
**修复**: 统一所有正则使用行首锚点 `^`。

### 6. `_isReceivingReport` 竞态
**问题**: `Future.delayed(100ms)` 无取消机制，高频 speed report (10Hz) 会导致多个延迟任务堆积。
**修复**: 用 Timer（可取消）替代 Future.delayed。

### 7. `_userDisconnected` 竞态窗口
**问题**: Timer 回调中检查 `_userDisconnected`，但 disconnect() 和 Timer 触发之间的竞态窗口约 1-16 秒。
**修复**: 在 `disconnect()` 中先设置标志再 cancel Timer。

### 8. `_draining` 异常不安全
**问题**: `_drainQueue()` 中如果 `_writeChunked` 抛出异常，`_draining` 永久锁死。
**后果**: 队列永久阻塞，后续所有 BLE 发送失败。
**修复**: `try { ... } finally { _draining = false; }`

### 9. Screen 状态与 Provider 状态重复
**问题**: `_currentSpeed`、`_isAirflowStarted` 在 Screen 和 Provider 各有一份副本。
**后果**: 状态不一致，UI 显示与实际硬件状态不同步。
**修复**: 迁移所有设备状态到 Provider，Screen 只读。

### 10. Android WiFi扫描废弃API
**问题**: `WifiManager.startScan()` 在 Android 13+ 返回 false。
**后果**: 新版本 Android 上 WiFi 扫描静默失败，返回过时缓存数据。
**修复**: 迁移到 `WifiManager.startScan()` → `ConnectivityManager` 或用户手动输入。

---

## 🟢 P2 — 低概率但影响可维护性

### 11. debug_logger 空壳
**问题**: `DebugLogger().log()` 无任何输出，所有调用点都是死代码。
**修复**: 移除或用 `logger` 包替代。

### 12. ThrottleAccelerator 随机种子
**问题**: `Random()` 无种子，每次启动行为不同。
**修复**: 添加可选种子参数，便于测试。

### 13. IP正则不验证范围
**问题**: `WIFI_IP:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})` 接受 999.999.999.999。
**修复**: 添加 `int.parse() <= 255` 的范围检查。

### 14. TCP重连无指数退避 (Android)
**问题**: `AudioCaptureService.kt` 中重连间隔固定 3 秒。
**修复**: 添加指数退避 + jitter。

### 15. 硬编码包名
**问题**: `com.example.ridewind` 出现在 4 个地方。
**修复**: 统一改为 `com.zcritical.ridewind`。

---

## 🔵 P3 — 可扩展性风险

### 16. BluetoothProvider 过于中心化
**问题**: 700 行的单一 ChangeNotifier 承载所有 BLE 状态 + 17 个事件流。
**后果**: 任何小改动都需要修改这个巨型类。
**修复**: 拆分为 15 个细粒度 Riverpod Provider，每个 < 100 行。

### 17. 无 Repository 抽象层
**问题**: Screen 直接通过 `Provider.of<BluetoothProvider>(context)` 访问底层 BLE。
**后果**: UI 和通信层强耦合，无法 mock 测试，换协议需改所有 Screen。
**修复**: 引入 `DeviceRepository`、`BLERepository`、`LogoRepository` 等接口。

### 18. 无平台能力抽象
**问题**: `AudioStreamService.startCapture()` 用 `if (!Platform.isAndroid) return false` 硬编码平台判断。
**后果**: 每加一个新平台都要到处改 if-else。
**修复**: 用 `PlatformCapability` 注册 + Strategy 模式。

---

## 重构安全规则

1. **绝不改动 ESP32 固件**（除非同步修改）
2. **协议命令字和格式永不改变**
3. **CRC32 计算永不改变**
4. **修改 `led_presets.dart` 时必须同步修改 `preset_colors.h`**
5. **所有 StreamController 必须在 dispose 中 close**
6. **所有 StreamSubscription 必须在 dispose 中 cancel**
7. **所有 Timer 必须在 dispose 中 cancel**
8. **每文件不超过 300 行**（新规则）
