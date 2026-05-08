# ZCritical 迁移映射表

> **用途**: 快速定位「旧代码在哪 → 新代码该写在哪」。
> **旧项目**: `softwaer/RideWind/lib/`
> **新项目**: `softwaer/zcritical/lib/`
> **状态**: 📋 待迁移 / 🔄 迁移中 / ✅ 已完成 / ❌ 废弃不迁移

---

## 一、按旧文件映射

| 旧文件 (RideWind/lib/) | 行数 | 状态 | → 新文件 (zcritical/lib/) | 备注 |
|--------|------|------|---------|------|
| `main.dart` | ~80 | 📋 | `main.dart` | 入口，完全重写 |
| **Services 层** | | | **→ data/datasources/** | |
| `services/ble_service.dart` | ~900 | 📋 | `data/datasources/ble/ble_client.dart` | BLE连接/重连/MTU协商 |
| | | | `data/datasources/ble/ble_scanner.dart` | 设备扫描+过滤 |
| | | | `data/datasources/ble/ble_sender.dart` | 发送队列（修复竞态） |
| `services/logo_transmission_manager.dart` | ~1600 | 📋 | `data/datasources/transmission/logo_session.dart` | 传输会话状态机 |
| | | | `data/datasources/transmission/logo_sender.dart` | 数据分包+滑动窗口 |
| | | | `data/datasources/transmission/logo_progress.dart` | 进度追踪+断点续传 |
| | | | `data/datasources/transmission/logo_ack_handler.dart` | ACK/SACK 处理 |
| | | | `data/datasources/transmission/logo_rtt_estimator.dart` | RTT 估算+超时自适应 |
| | | | `data/datasources/transmission/logo_persistence.dart` | 进度持久化 |
| | | | `data/datasources/transmission/ota_sender.dart` | OTA 固件传输 |
| | | | `data/datasources/transmission/transmission.dart` | barrel 导出 |
| `services/engine_audio_controller.dart` | ~350 | 📋 | `data/services/audio/engine_audio_controller.dart` | 引擎音效状态机 |
| | | | `data/services/audio/audio_player_factory.dart` | AudioPlayer 工厂 |
| `services/audio_engine.dart` | ~200 | 📋 | `data/services/audio/audio_engine.dart` | 引擎音频合成 |
| `services/audio_player.dart` | ~150 | 📋 | `data/services/audio/audio_player_adapter.dart` | 播放器适配器 |
| `services/wifi_audio_service.dart` | ~400 | 📋 | `data/services/audio/wifi_audio_client.dart` | TCP音频客户端 |
| | | | `data/services/audio/wifi_audio_stream.dart` | PCM流处理 |
| `services/storage.dart` | ~200 | 📋 | `data/services/local/local_storage.dart` | 本地偏好存储 |
| **Protocol 层** | | | **→ data/datasources/protocol/** | |
| `protocol/protocol_parser.dart` | ~800 | 📋 | `data/datasources/protocol/protocol_codec.dart` | **唯一**协议编解码 |
| `protocol/response_router.dart` | ~500 | ❌ | 删除，功能并入 `protocol_codec.dart` | 消除双重缓冲 |
| `protocol/crc32.dart` | ~50 | 📋 | `core/crypto/crc32.dart` | 不允许改动 |
| **Providers 层** | | | **→ presentation/providers/** | |
| `providers/bluetooth_provider.dart` | ~700 | 📋 | `presentation/providers/ble/ble_connection_provider.dart` | 连接状态 |
| | | | `presentation/providers/ble/ble_scan_provider.dart` | 扫描结果 |
| | | | `presentation/providers/device/fan_provider.dart` | 风扇速度 |
| | | | `presentation/providers/device/brightness_provider.dart` | 亮度 |
| | | | `presentation/providers/device/preset_provider.dart` | LED预设 |
| | | | `presentation/providers/device/speed_display_provider.dart` | 速度显示 |
| | | | `presentation/providers/device/volume_provider.dart` | 音量 |
| | | | `presentation/providers/device/airflow_provider.dart` | 雾化器 |
| | | | `presentation/providers/device/lcd_provider.dart` | LCD |
| | | | `presentation/providers/device/device_status_provider.dart` | 综合状态 |
| `providers/app_state_provider.dart` | ~50 | 📋 | `presentation/providers/app/app_state_provider.dart` | 应用全局状态 |
| **Controllers 层** | | | **→ presentation/providers/ + domain/usecases/** | |
| `controllers/colorize_controller.dart` | ~600 | 📋 | `presentation/providers/color/color_picker_provider.dart` | LED颜色编辑状态 |
| | | | `presentation/providers/color/color_preset_provider.dart` | 预设管理 |
| | | | `presentation/providers/color/gradient_provider.dart` | 渐变动画 |
| | | | `domain/usecases/sync_led_color.dart` | LED同步节流 |
| `controllers/engine_audio_controller.dart` | ~350 | 📋 | 已在 Services 层映射 | |
| **Screens 层** | | | **→ presentation/screens/ + presentation/widgets/** | |
| `screens/device_connect_screen.dart` | ~1500 | 📋 | `presentation/screens/device_scan_screen.dart` | BLE扫描页 |
| | | | `presentation/screens/device_dashboard_screen.dart` | 主控制面板 |
| | | | `presentation/screens/device_wifi_screen.dart` | WiFi配置页 |
| | | | `presentation/widgets/device_card.dart` | 设备卡片组件 |
| | | | `presentation/widgets/connection_guide.dart` | 连接引导组件 |
| | | | `presentation/widgets/disconnect_dialog.dart` | 断开确认弹窗 |
| | | | `presentation/widgets/speed_display.dart` | 速度显示组件 |
| `screens/colorize_screen.dart` | ~300 | 📋 | `presentation/screens/color_picker_screen.dart` | 颜色选择页 |
| | | | `presentation/widgets/color_wheel.dart` | 色轮组件 |
| | | | `presentation/widgets/rgb_sliders.dart` | RGB滑块 |
| `screens/logo_screen.dart` | ~400 | 📋 | `presentation/screens/logo_upload_screen.dart` | Logo上传页 |
| | | | `presentation/widgets/logo_preview.dart` | Logo预览 |
| | | | `presentation/widgets/upload_progress.dart` | 上传进度条 |
| `screens/setting_screen.dart` | ~200 | 📋 | `presentation/screens/settings_screen.dart` | 设置页 |
| **Models 层** | | | **→ domain/models/** | |
| `models/device.dart` | ~80 | 📋 | `domain/models/device.dart` | freezed 重写 |
| `models/led_color.dart` | ~50 | 📋 | `domain/models/led_color.dart` | freezed 重写 |
| `models/logo_info.dart` | ~80 | 📋 | `domain/models/logo_info.dart` | freezed 重写 |
| `models/device_status.dart` | ~100 | 📋 | `domain/models/device_status.dart` | freezed 重写 |
| **Utils 层** | | | **→ core/** | |
| `utils/speed_math.dart` | ~80 | 📋 | `domain/models/speed_unit.dart` | 速度单位转换，freezed |
| `utils/debug_logger.dart` | ~30 | ❌ | 删除，用 `logger` 包替代 | 死代码 |
| `utils/constants.dart` | ~50 | 📋 | `core/constants.dart` | 集中管理所有常量 |

## 二、按新文件反向索引

### core/ (基础设施)
| 新文件 | 来源 | 说明 |
|--------|------|------|
| `core/result.dart` | 🆕 新建 | Result<T> 类型 |
| `core/di/injection.dart` | 🆕 新建 | GetIt + Injectable 配置 |
| `core/theme/app_theme.dart` | 🆕 新建 | 统一主题 |
| `core/logger/app_logger.dart` | 🆕 新建 | 替代 debug_logger |
| `core/constants.dart` | `utils/constants.dart` | 迁移 |
| `core/crypto/crc32.dart` | `protocol/crc32.dart` | ⚠️ 禁止改动 |
| `core/platform/platform_capability.dart` | 🆕 新建 | 平台能力抽象 |

### domain/ (业务逻辑)
| 新文件 | 来源 | 说明 |
|--------|------|------|
| `domain/models/device.dart` | `models/device.dart` | freezed |
| `domain/models/device_status.dart` | `models/device_status.dart` | freezed |
| `domain/models/led_color.dart` | `models/led_color.dart` | freezed |
| `domain/models/logo_info.dart` | `models/logo_info.dart` | freezed |
| `domain/models/ble_packet.dart` | 🆕 新建 | 协议数据包模型 |
| `domain/models/speed_unit.dart` | `utils/speed_math.dart` | freezed |
| `domain/usecases/connect_device.dart` | `ble_service.dart` 逻辑 | 提取 |
| `domain/usecases/disconnect_device.dart` | `ble_service.dart` 逻辑 | 提取 |
| `domain/usecases/set_fan_speed.dart` | `bluetooth_provider.dart` 逻辑 | 提取 |
| `domain/usecases/set_brightness.dart` | `bluetooth_provider.dart` 逻辑 | 提取 |
| `domain/usecases/set_led_color.dart` | `colorize_controller.dart` 逻辑 | 提取 |
| `domain/usecases/upload_logo.dart` | `logo_transmission_manager.dart` 逻辑 | 提取 |
| `domain/usecases/play_engine_sound.dart` | `engine_audio_controller.dart` 逻辑 | 提取 |

## 三、删除清单

以下文件/功能在新架构中彻底消失：

| 删除项 | 原因 |
|--------|------|
| `protocol/response_router.dart` (500行) | 功能并入 protocol_codec，消除双重缓冲 |
| `providers/bluetooth_provider.dart` 中的 `_dataBuffer` | 统一由 protocol_codec 管理缓冲 |
| `utils/debug_logger.dart` | 死代码，用 logger 包替代 |
| Screen 中的 `_currentSpeed`, `_isAirflowStarted` | 状态迁入 Provider，Screen 不持状态 |
| 所有 `if (Platform.isAndroid)` 判断 | 用 PlatformCapability 抽象替代 |
| `Future.delayed` 用作 debounce/timer | 用 `Timer`（可取消）+ Riverpod `ref.onDispose` |
| `_draining` 布尔标志 | 用 Completer 链 + Mutex 替代 |
