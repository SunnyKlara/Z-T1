# ZCritical 架构地图

> **用途**: 项目的骨架蓝图。新 AI 会话读完后知道每个文件在哪、为什么在那、能改什么不能改什么。
> **设计记录**: 2026-05-07，基于 Clean Architecture 的架构审计。8 个改进提案已纳入。
> **更新**: 架构决策变更时更新。不是开发日志——是决策记录。

---

## 一、架构全景图

```
lib/
├── main.dart                          # 入口 (~50行)
├── app.dart                           # MaterialApp 配置 (~80行)
│
├── core/                              # 核心基础设施（零业务依赖）
│   ├── di/
│   │   └── injection_container.dart   # GetIt 依赖注入配置
│   ├── error/
│   │   ├── failures.dart              # 统一失败类型
│   │   ├── exceptions.dart            # 统一异常类型
│   │   └── result.dart                # Result<T> 类型（复用+增强）
│   ├── platform/
│   │   ├── platform_info.dart         # 平台检测：isAndroid/isIOS/isDesktop
│   │   ├── platform_registry.dart     # 平台能力注册：哪些平台支持 WiFi 音频/BLE
│   │   └── ble_capability.dart        # BLE 能力检测：是否支持、版本、权限状态
│   ├── router/
│   │   ├── app_router.dart            # GoRouter 定义 (~80行)
│   │   ├── route_names.dart           # 路由名称常量 (~30行)
│   │   ├── route_guards.dart          # 路由守卫：检查 BLE 连接状态等
│   │   └── navigation_ext.dart        # BuildContext 导航便捷扩展 (~30行)
│   ├── theme/
│   │   ├── app_theme.dart             # 主题配置
│   │   └── app_colors.dart            # 颜色常量
│   └── utils/
│       ├── logger.dart                # 统一日志（替代 debug_print）
│       ├── crc32.dart                 # CRC32（与固件一致，不可改算法）
│       └── extensions.dart            # Dart 扩展
│
├── domain/                            # 领域层（纯 Dart，零外部依赖）
│   ├── models/                        # 领域模型
│   │   ├── device.dart                # 设备模型
│   │   ├── speed_report.dart          # 速度报告
│   │   ├── logo_slot_status.dart      # Logo 槽位
│   │   ├── led_preset.dart            # LED 预设
│   │   ├── ble_packet.dart            # BLE 包
│   │   ├── audio_config.dart          # 音频配置
│   │   ├── running_mode.dart          # 枚举：巡航/极速/展览/自定义
│   │   ├── color_info.dart            # 值对象：RGB + HSL + 预览色
│   │   └── connection_state.dart      # 枚举：disconnected/connecting/connected/disconnecting
│   ├── repositories/                  # 仓库接口（抽象）
│   │   ├── device_repository.dart     # 设备仓库接口
│   │   ├── ble_repository.dart        # BLE 通信仓库接口
│   │   ├── logo_repository.dart       # Logo 管理仓库接口
│   │   ├── audio_repository.dart      # 音频仓库接口
│   │   └── settings_repository.dart   # 设置仓库接口
│   └── usecases/                      # 用例（每个用例一个文件）
│       ├── scan_devices.dart          # 扫描设备
│       ├── connect_device.dart        # 连接设备
│       ├── set_fan_speed.dart         # 设置风扇速度
│       ├── set_led_color.dart         # 设置 LED 颜色
│       ├── set_led_preset.dart        # 设置 LED 预设
│       ├── set_brightness.dart        # 设置亮度
│       ├── set_volume.dart            # 设置音量
│       ├── set_wuhuaqi.dart           # 控制雾化器
│       ├── set_streamlight.dart       # 控制流水灯
│       ├── upload_logo.dart           # 上传 Logo
│       ├── start_ota.dart             # 开始 OTA
│       ├── stream_audio.dart          # WiFi 音频投射
│       └── query_device_state.dart    # 查询设备状态
│
├── data/                              # 数据层
│   ├── repositories/                  # 仓库实现
│   │   ├── device_repository_impl.dart
│   │   ├── ble_repository_impl.dart
│   │   ├── logo_repository_impl.dart
│   │   ├── audio_repository_impl.dart
│   │   └── settings_repository_impl.dart
│   ├── datasources/                   # 数据源
│   │   ├── ble/
│   │   │   ├── ble_service.dart       # BLE 顶层：init/dispose/MTU 协商 (~150行)
│   │   │   ├── ble_read.dart          # 读取封装 (~80行) [如果 ble_service 膨胀则拆分]
│   │   │   ├── ble_write.dart         # 写入封装 (~100行) [如果 ble_service 膨胀则拆分]
│   │   │   ├── ble_scanner.dart       # BLE 扫描 (~80行)
│   │   │   └── ble_connection.dart    # BLE 连接管理 (~150行)
│   │   ├── protocol/
│   │   │   ├── protocol_parser.dart   # 协议解析器（纯函数）
│   │   │   ├── command_builder.dart   # 命令构造器
│   │   │   └── response_router.dart   # 响应路由器
│   │   ├── transmission/              # 传输层（拆分自 RideWind 1600 行文件）
│   │   │   ├── transmission_manager.dart      # 传输管理器 (~300行)
│   │   │   ├── transmission_state.dart        # 状态枚举
│   │   │   ├── transmission_models.dart       # PacketInfo/AckInfo/Stats
│   │   │   ├── sliding_window.dart            # 滑动窗口 (~100行)
│   │   │   ├── rtt_estimator.dart             # RTT 估算器 (~40行)
│   │   │   ├── packet_loss_monitor.dart       # 丢包监控 (~40行)
│   │   │   ├── adaptive_rate_controller.dart  # 自适应速率 (~50行)
│   │   │   ├── ack_batcher.dart               # ACK 批处理 (~60行)
│   │   │   ├── transmission_logger.dart       # 传输日志 (~40行)
│   │   │   ├── hex_uploader.dart              # Hex 模式上传 (~200行)
│   │   │   ├── binary_uploader.dart           # 二进制上传 (~200行)
│   │   │   └── image_processor.dart           # 图片裁剪/缩放/RGB565转换 (~150行)
│   │   └── local/
│   │       ├── preferences_datasource.dart    # SharedPreferences 封装
│   │       └── audio_platform_datasource.dart # MethodChannel 封装
│   └── mappers/
│       ├── device_mapper.dart          # ScanResult → Device 映射
│       ├── protocol_mapper.dart        # 协议字符串 → 模型映射（主入口，~80行）
│       ├── protocol_mapper_fan.dart    # 风扇相关映射 [如果主入口膨胀则拆分]
│       ├── protocol_mapper_led.dart    # LED 相关映射 [如果主入口膨胀则拆分]
│       └── protocol_mapper_logo.dart   # Logo 相关映射 [如果主入口膨胀则拆分]
│
├── presentation/                      # 表现层
│   ├── providers/                      # 状态管理（每个 Provider 一个文件）
│   │   ├── ble/
│   │   │   ├── ble_scan_provider.dart           # 扫描状态
│   │   │   ├── ble_connection_provider.dart     # 连接状态
│   │   │   └── ble_status_provider.dart         # BLE 适配器状态
│   │   ├── device/
│   │   │   ├── fan_speed_provider.dart          # 风扇速度
│   │   │   ├── running_mode_provider.dart       # 运行模式
│   │   │   ├── wuhuaqi_provider.dart            # 雾化器
│   │   │   └── device_state_provider.dart       # 设备综合状态
│   │   ├── led/
│   │   │   ├── led_preset_provider.dart         # LED 预设
│   │   │   ├── led_rgb_provider.dart            # RGB 调色
│   │   │   ├── streamlight_provider.dart        # 流水灯
│   │   │   └── brightness_provider.dart         # 亮度
│   │   ├── logo/
│   │   │   └── logo_upload_provider.dart        # Logo 上传
│   │   ├── audio/
│   │   │   ├── audio_volume_provider.dart       # 音量
│   │   │   ├── audio_stream_provider.dart       # WiFi 音频投射
│   │   │   └── engine_audio_provider.dart       # 引擎音效
│   │   ├── settings/
│   │   │   └── settings_provider.dart           # 设置
│   │   └── composite/
│   │       ├── dashboard_provider.dart          # 首页仪表盘：组合 device+led+audio 状态
│   │       └── scene_mode_provider.dart         # 场景模式：一键设置风扇+LED+音效联动
│   ├── screens/                        # 页面
│   │   ├── splash/
│   │   │   └── splash_screen.dart
│   │   ├── scan/
│   │   │   └── device_scan_screen.dart
│   │   ├── connect/
│   │   │   └── device_connect_screen.dart       # (~300行，仅布局编排)
│   │   ├── running/
│   │   │   └── running_mode_page.dart
│   │   ├── colorize/
│   │   │   ├── colorize_preset_page.dart
│   │   │   └── colorize_rgb_page.dart
│   │   ├── logo/
│   │   │   └── logo_management_screen.dart
│   │   ├── ota/
│   │   │   └── ota_upgrade_screen.dart
│   │   ├── audio/
│   │   │   └── audio_stream_screen.dart
│   │   ├── settings/
│   │   │   └── settings_screen.dart
│   │   └── debug/                               # Debug 页面（Release 自动排除）
│   │       └── dev_test_screen.dart
│   └── widgets/                        # 可复用组件
│       ├── common/
│       │   ├── app_button.dart
│       │   ├── app_card.dart
│       │   ├── app_dialog.dart
│       │   └── app_toast.dart
│       ├── ble/
│       │   ├── device_card.dart
│       │   ├── signal_indicator.dart
│       │   └── connection_status_bar.dart
│       ├── running/
│       │   ├── speed_gauge.dart
│       │   ├── throttle_control.dart
│       │   └── airflow_indicator.dart
│       ├── colorize/
│       │   ├── color_ring_painter.dart
│       │   ├── chinese_color_wheel.dart
│       │   ├── rgb_slider.dart
│       │   └── preset_grid.dart
│       ├── logo/
│       │   ├── logo_slot_card.dart
│       │   └── upload_progress_bar.dart
│       └── guide/
│           ├── guide_overlay.dart
│           └── guide_tooltip.dart
│
├── l10n/                               # 国际化
│   ├── app_en.arb                       # 英文
│   ├── app_zh.arb                       # 中文
│   └── app_localizations.dart           # 本地化委托
│
└── test/                               # 测试目录（镜像 lib/ 结构）
    ├── core/
    │   ├── utils/
    │   │   └── crc32_test.dart
    │   └── error/
    │       └── result_test.dart
    ├── domain/
    │   ├── models/
    │   │   └── device_test.dart
    │   └── usecases/
    │       ├── set_fan_speed_test.dart
    │       ├── set_led_color_test.dart
    │       └── ...
    ├── data/
    │   ├── datasources/
    │   │   ├── protocol/
    │   │   │   └── protocol_parser_test.dart
    │   │   └── transmission/
    │   │       ├── sliding_window_test.dart
    │   │       └── rtt_estimator_test.dart
    │   └── repositories/
    │       └── ble_repository_impl_test.dart
    └── presentation/
        └── providers/
            └── ...
```

---

## 二、每层职责一句话

| 层 | 职责 | 不做什么 |
|----|------|---------|
| **core/** | 基础设施：DI、路由、主题、日志、CRC32、平台检测 | 不包含任何业务逻辑 |
| **domain/** | 业务规则：纯 Dart 模型、仓库抽象接口、用例 | 不依赖 Flutter、不依赖任何第三方库 |
| **data/** | 数据获取：BLE 通信、协议解析、传输管理、本地存储 | 不依赖 UI、不直接操作 Widget |
| **presentation/** | UI 展示：Screen（布局编排）、Widget（渲染）、Provider（状态管理） | 不直接访问 BLE/协议/SharedPreferences |
| **l10n/** | 多语言文本 | 不包含 UI 逻辑 |

---

## 三、Import 方向规则（防线 2 的关键部分）

```
presentation/  →  只能 import domain/, core/, presentation/自身
data/          →  只能 import domain/, core/, data/自身
domain/        →  只能 import core/, domain/自身
core/          →  不能 import 任何业务代码（domain/data/presentation）
```

```
                    ┌──────────────┐
                    │ presentation │  ← Screen / Widget / Provider
                    └──────┬───────┘
                           │ 依赖
                    ┌──────▼───────┐
                    │    domain    │  ← Model / UseCase / Repository接口
                    └──────┬───────┘
                           │ 依赖
              ┌────────────┼────────────┐
              │            │            │
     ┌────────▼───┐ ┌─────▼──────┐     │
     │    data    │ │    core    │     │
     └────────────┘ └────────────┘     │
                                        │
                              违反 import 方向 = CI 失败
```

---

## 四、阶段 0 最小集（技术验证链）

带 ★ 的 8 个文件是阶段 0 必须完成的。它们的目的是验证"整个技术栈能编译运行"。

```
步骤 1: core/error/result.dart              ★  纯 Dart，零依赖
步骤 2: core/utils/logger.dart              ★  纯 Dart，零依赖
步骤 3: core/theme/app_theme.dart           ★  主题配置
步骤 4: core/di/injection_container.dart    ★  GetIt + Injectable 配置
步骤 5: domain/models/device.dart           ★  第一个 freezed model
步骤 6: domain/models/connection_state.dart ★  枚举
步骤 7: core/router/app_router.dart         ★  GoRouter + 一个空首页
步骤 8: app.dart + main.dart                ★  入口 + MaterialApp 配置

验证: flutter analyze + flutter build apk --debug 两条都通过。
```

---

## 五、文件总数统计

| 层 | 文件数 | 说明 |
|----|--------|------|
| core/ | ~17 | 基础设施 |
| domain/models/ | ~9 | 数据模型 + 枚举 + 值对象 |
| domain/repositories/ | ~5 | 抽象接口 |
| domain/usecases/ | ~13 | 用例 |
| data/repositories/ | ~5 | 实现 |
| data/datasources/ | ~25 | 数据源（含预留拆分） |
| data/mappers/ | ~5 | 数据映射（含预留拆分） |
| presentation/providers/ | ~22 | 状态管理 |
| presentation/screens/ | ~12 | 页面 |
| presentation/widgets/ | ~17 | 可复用组件 |
| l10n/ | ~3 | 国际化 |
| **总计** | **~133** | 含 test/ 和预留拆分 |

> **文件多但小，远好于文件少但大。** RideWind ~35 个文件平均 485 行；本架构 ~130 个文件平均 ≤200 行。
> 修改一个功能只影响小范围；新 AI 理解一个功能只需看一个 150 行的文件。

---

## 六、架构审计结论（2026-05-07）

| 维度 | 评分 | 说明 |
|------|------|------|
| 分层清晰度 | 9/10 | Clean Architecture 四层，业界标准 |
| 可扩展性 | 9/10 | 加新功能域 = 在 domain/data/presentation 各加对应文件 |
| 可测试性 | 8/10 | domain 纯 Dart 可测；data 可 mock；presentation 测试友好 |
| 可维护性 | 8/10 | 每文件小，职责单一，新人/AI 快速定位 |
| 行业对标 | 8/10 | 对标中等规模企业级 Flutter 项目 |
| 防膨胀 | 8/10 | 分层行数限制 + 目录结构天然约束 |

**总评：达到专业级标准。** 可支撑从 v1.0 到 v3.0 的功能增长而不腐烂。

---

## 七、与新 AI 的协作规则

每次 AI 新增/修改文件前，必须先查这个文件：

1. **文件已经存在了吗？** → 查目录树，确认没有功能重复的文件
2. **职责匹配吗？** → 读目标文件的职责声明，确认新代码属于这个职责
3. **放在正确的层了吗？** → 查 import 方向规则，确认没有跨层
4. **超过 300 行了吗？** → 预估行数，超标则必须先拆分再动手

---

## 八、改进提案记录（2026-05-07）

| # | 提案 | 新增文件 | 理由 |
|---|------|---------|------|
| 1 | `core/router/` 扩展 route_guards + navigation_ext | +2 | 防止用户在未连接时进入控制页 |
| 2 | `image_processor.dart` 独立文件 | +1 | 图片处理是纯计算，不应耦合传输逻辑 |
| 3 | domain 增加 RunningMode / ColorInfo / ConnectionState | +3 | 避免跨层重复定义（RideWind 的教训） |
| 4 | composite Provider：Dashboard + SceneMode | +2 | 首页和场景切换逻辑不散落 |
| 5 | test/ 镜像 lib/ 结构 | ~20 | 测试文件按源码结构对应 |
| 6 | `core/platform/ble_capability.dart` | +1 | BLE 平台差异封装 |
| 7 | protocol_mapper 预留按协议类别拆分 | +3 | 防止 protocol_mapper 膨胀 |
| 8 | ble_service 预留拆分为 ble_read/ble_write | +2 | 防止 ble_service 膨胀超过 300 行 |
