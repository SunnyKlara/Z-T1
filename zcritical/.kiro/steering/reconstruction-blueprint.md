# ZCritical 重构蓝图

> **用途**: 新 AI 会话快速知悉项目全貌，无需重复分析。
> **更新**: 每次重构完成后更新进度。
> **原项目**: `softwaer/RideWind/` (Flutter, 臃肿~17,000行Dart, **仅作参考，不复用代码**)
> **目标项目**: `softwaer/zcritical/` (Flutter, 白板重写)
> **硬件**: `hardware/ridewind-esp/` (ESP32-S3, C/ESP-IDF, 不动)
> **关键约束**: App 未上架，无存量用户，可激进重构，包名/签名无历史包袱

---

## 一、产品定位

| 维度 | 说明 |
|------|------|
| 产品 | **桌面风洞模型**（汽车风洞的 1:64 微缩版） |
| 目标用户 | 车模收藏爱好者、桌面摆件/潮玩玩家、STEM 科教产品消费者 |
| 核心体验 | 把玩、展示、个性化——不是"工具"，是"玩具" |
| 使用场景 | 坐在桌前悠闲操作，不是开车时匆忙调节 |
| 核心情感 | 仪式感、工艺感、归属感（"这是我的专属装备"） |
| App 角色 | 让用户驾驭风洞模型的精致控制终端 |

### 这决定了 App 的设计哲学

- ❌ 不是: 工具型 App（快速、简单、用完离开）
- ✅ 是: 体验型 App（精致、有仪式感、愿意花时间把玩）
- ❌ 不是: 罗列参数和控制选项
- ✅ 是: 场景化操作 + 可选深入自定义
- ❌ 不是: 冷冰冰的工业界面
- ✅ 是: 有质感、有温度、值得拍照分享的界面

## ⚠️ 核心定位：这不是迁移，是重建

RideWind 的角色从"代码来源"降级为"**参考项目**"：
- **协议格式、CRC32、BLE UUID** → 必须一致（固件不变）
- **功能逻辑** → 可参考 RideWind 的实现思路，但全部重写
- **代码** → **不复制，不复用，一行都不直接搬**
- **UI** → 完全重新设计，RideWind 的 UI 存在大量问题（伪代码、测试不通过、响应式布局失败、Logo上传功能形同虚设）
- **架构** → 完全重新设计（Clean Architecture + Riverpod）
- **设计理念** → 不限于 RideWind 的已有功能，鼓励新的设计想法

RideWind 唯一不可替代的价值是它与固件通信时的**协议行为**（发什么命令、收什么响应、时序是什么样的），这些已经提取到 `protocol-contract.md`。

## 二、不可变核心（与ESP32固件耦合，严禁改动）

| 项 | 值 | 位置 |
|----|-----|------|
| BLE Service UUID | `0000ffe0-0000-1000-8000-00805f9b34fb` | 固件 hardcode |
| BLE Char UUID | `0000ffe1-0000-1000-8000-00805f9b34fb` | write-without-response + notify |
| MTU | 协商247，有效载荷244 | `ble_service.dart` |
| 协议格式 | 文本协议，`\n` 结尾 | `PROTOCOL_SPECIFICATION.md` |
| CRC32 | 多项式 `0xEDB88320`，初始 `0xFFFFFFFF`，异或 `0xFFFFFFFF` | `crc32.dart` |
| 音频TCP | `192.168.4.1:8080`，44100Hz 16-bit stereo PCM | Android `AudioCaptureService.kt` |
| LED预设 | 14种，与ESP32 `preset_colors.h` 对齐 | `led_presets.dart` |
| Logo格式 | 240×240 RGB565，115200字节 | 协议约定 |
| 滑动窗口 | ACK每16包一次，与ESP32 `LOGO_BATCH_SIZE=16` 对齐 | 传输管理器 |

## 三、目标架构 (Clean Architecture)

```
lib/
├── core/           # Result<T>, DI, Theme, Logger
├── domain/         # Models(freezed), Repository接口, UseCases
├── data/           # Repository实现, 数据源(BLE/协议/传输/本地)
├── presentation/   # Providers(Riverpod), Screens(每页<300行), Widgets
└── l10n/           # ARB国际化
```

**每文件 ≤ 300行** 硬性规则。

## 四、旧代码臃肿点 → 新架构拆分

| 旧文件(行数) | → 新架构 |
|-------------|---------|
| `logo_transmission_manager.dart` (1600) | → `data/datasources/transmission/` 12个文件 |
| `device_connect_screen.dart` (1500) | → 3个Page + 7个Riverpod Provider |
| `bluetooth_provider.dart` (700) | → 15个细粒度Provider |
| `colorize_controller.dart` (600) | → 4个Provider + 2个Page |

## 五、已知技术债务（必须修复）

### P0 严重
1. **iOS AudioCapture 完全缺失** — `AppDelegate.swift` 空壳，MethodChannel `com.example.ridewind/audio_capture` 在iOS上 notImplemented
2. **双重数据缓冲** — `bluetooth_provider.dart` 和 `response_router.dart` 各自维护 `_dataBuffer`，数据被复制两次
3. **发送队列竞态** — `_draining` 布尔标志在 `sendData()` 和 `_drainQueue()` 之间有竞态窗口
4. **StreamSubscription 未取消** — `dispose()` 中未取消 BLE rxDataStream 的 subscription，内存泄漏

### P1 中等
5. **正则不一致** — ProtocolParser 中部分正则用 `^` 锚点，部分不用，可能误解析
6. **Android WiFi扫描废弃API** — `WifiManager.startScan()` 在 Android 13+ 对普通应用返回 false
7. **`_isReceivingReport` 竞态** — `Future.delayed(100ms)` 无取消机制
8. **Screen状态重复** — `_currentSpeed` 在 Screen 和 Provider 各有一份

### P2 低
9. **debug_logger 空壳** — 所有调用无输出，死代码
10. **硬编码包名** — `com.example.ridewind` → 改为 `com.zcritical.ridewind`

## 六、关键技术选型

| 层面 | 旧 | 新 |
|------|----|----|
| 状态管理 | Provider | **Riverpod 2.x** |
| DI | GetIt | GetIt + Injectable (代码生成) |
| 路由 | Navigator 1.0 | **GoRouter** |
| 序列化 | 手动 | **freezed + json_serializable** |
| 国际化 | 硬编码中文 | **flutter_localizations + ARB** |
| BLE | flutter_blue_plus (保留) | flutter_blue_plus |
| 测试 | flutter_test | mocktail |

## 七、平台分级策略

| 等级 | 平台 | 功能范围 | 投入 |
|------|------|---------|------|
| **一级** | Android、iOS | 全功能：BLE连接 + 设备控制 + LED + Logo上传 + WiFi音频 | 主力开发 |
| **二级** | Windows、macOS | 核心功能：BLE连接 + 设备控制 + LED + Logo上传 | 适配保障 |
| **三级** | Linux、Web | 基础展示：可编译运行，功能按需补充 | 最低维护 |

## 八、命名统一规则

- `ridewind` → `zcritical`（所有出现位置）
- `RideWind` → `ZCritical`（类名/文件名）
- `Critical`/`CriticalApp` → `ZCritical`/`ZCriticalApp`
- MethodChannel: `com.example.ridewind/audio_capture` → `com.zcritical.ridewind/audio_capture`
- Android包名: `com.example.ridewind` → `com.zcritical.ridewind`
- iOS Bundle ID: `com.example.ridewind` → `com.zcritical.ridewind`
- ⚠️ 包名变更无历史负担（未上架，无存量用户）

## 九、实施阶段

- [ ] **阶段0**: 技术验证链 — Riverpod+GoRouter+Injectable 跑通，BLE扫描+基础连接验证
- [ ] **阶段1**: 基础骨架 — core/, domain/models/, DI配置
- [ ] **阶段2**: 数据层 — BLE Service重构, 协议层迁移, 传输层拆分
- [ ] **阶段3**: 状态管理 — Riverpod Providers, UseCases
- [ ] **阶段4**: UI — Screens(每页<300行), Widgets拆分
- [ ] **阶段5**: 平台补齐 — iOS AudioCapture 实现, 包名统一
- [ ] **阶段6**: 国际化 — ARB文件, 提取硬编码字符串

### 阶段弹性策略（如果精力不够）

| 可延后 | 不可延后 |
|--------|---------|
| iOS AudioCapture（先做 Android） | 核心架构（core + domain + 分层规则） |
| OTA 升级（旧 App 可升） | BLE 基础通信（扫描+连接+发命令） |
| WiFi 音频（先做 BLE 控制） | 协议层（codec 必须一次性写对） |
| 国际化（先硬编码英文） | 防臃肿机制（CI检查、import规则） |
| 二级/三级平台 | 一级平台（Android + iOS） |

## 九、源文件速查

| 用途 | 原路径 |
|------|--------|
| 协议规范 | `RideWind/PROTOCOL_SPECIFICATION.md` |
| ESP32固件入口 | `hardware/ridewind-esp/main/main.c` |
| ESP32预设颜色 | `hardware/ridewind-esp/main/config/preset_colors.h` |
| Android音频捕获 | `RideWind/android/app/src/main/kotlin/com/example/ridewind/AudioCaptureService.kt` |
| Android MainActivity | `RideWind/android/app/src/main/kotlin/com/example/ridewind/MainActivity.kt` |
| iOS AppDelegate | `RideWind/ios/Runner/AppDelegate.swift` |
