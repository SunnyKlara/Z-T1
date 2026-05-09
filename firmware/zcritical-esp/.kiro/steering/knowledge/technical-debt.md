# ⚠️ 固件端已知技术债务

> **用途**: 记录固件端已知的技术债务，防止遗忘。新对话开始时必须阅读。
> **更新**: 发现新问题时添加，修复后标记。
> **对标**: zcritical/.kiro/steering/technical-risks.md

---

## P0 严重（必须修复才能稳定运行）

### 1. main.c 严重超标 — 893行
- **文件**: `main.c`
- **问题**: 包含 Logo 上传协议（~350行）+ BLE 命令分发（~400行）+ 初始化（~100行）+ 任务循环（~30行）
- **影响**: 难以维护，新功能无处可加
- **修复**: 拆分为 main.c + `services/command_dispatch.c` + `services/logo_receiver.c`
- **状态**: ⚠️ 待修复

### 2. BLE 看门狗 — 6秒检测窗口
- **文件**: `ble_service.c`
- **问题**: APP 异常断连（直接关蓝牙不走正常断开流程），6秒看门狗才能检测到
- **影响**: 6秒内 APP 重连可能失败
- **修复**: 缩短检测窗口或增加心跳包
- **状态**: ⚠️ 待修复

### 3. Logo 上传断连清理 — PSAM 泄漏
- **文件**: `main.c` / `ble_service.c`
- **问题**: BLE 断连时，如果 Logo 正在上传，PSAM 缓冲需要正确释放
- **影响**: 内存泄漏，PSAM 耗尽
- **当前**: 已有 `logo_rx_cleanup()` 和 BLE 断连清理，需回归测试确认
- **状态**: 👀 需回归测试

---

## P1 中等（影响功能但不阻塞）

### 1. OTA 升级未实现
- **文件**: `main.c`
- **问题**: `CMD_OTA_START/DATA/END` 三个 case 返回 `ERR:NOT_IMPL`
- **影响**: 无法通过 APP 远程升级固件
- **状态**: ⚠️ 待实现

### 2. WiFi 音频与引擎合成 I2S 冲突
- **文件**: `audio_engine.c` / `wifi_audio_service.c`
- **问题**: WiFi 音频流和引擎合成可能同时使用 I2S 输出，冲突风险
- **影响**: 两个音频源同时播放可能噪音
- **状态**: 👀 需验证

### 3. OTA 期间断连
- **文件**: `main.c` / `ble_service.c`
- **问题**: OTA 升级期间如果 BLE 断连，固件可能进入不可恢复状态
- **状态**: ⚠️ 需在 OTA 实现时设计容错

---

## P2 低（改进项）

### 1. 固件文件行数审计
- **问题**: 多个文件行数未知，可能导致超标
- **需检查**: `drv_lcd.c`, `ui_manager.c`, `ui_treadmill.c`, `led_effects.c`, `protocol.c`, `ble_service.c`
- **状态**: ⚠️ 待审计

### 2. ui_volume.c 死代码
- **文件**: `ui_volume.c` / `ui_volume.h`
- **问题**: UI7 音量界面已禁用，重定向到菜单。但文件保留
- **决定**: 保留（未来可能启用）
- **状态": ✅ 已知

### 3. 引擎音频层文件可能过大
- **文件**: `resources/engine.mp3`
- **问题**: MP3 格式固件需要解码。PCM 格式更直接但更大
- **状态": ℹ️ 维持现状

---

## 已完成修复（回归测试标记）

| 编号 | 描述 | 文件 | 版本 |
|------|------|------|------|
| FIX-01 | 呼吸模式旋转编码器自动退出 | ui_bright.c | R1 |
| FIX-02 | 菜单动画期间积累编码器 delta | ui_menu.c | R1 |
| FIX-03 | 油门退出使用 max(当前, 保存) | ui_speed.c | R1 |
| FIX-04 | 双击退出前同步 led_edit 到 led_colors | ui_rgb.c | R1 |
| FIX-05 | FB 分配失败显示 MEM FULL | ui_treadmill.c | R1 |
| FIX-06 | BLE 断连清理 Logo/Audio PSRAM | ble_service.c | R1 |
| FIX-07 | UI 转场调用旧 UI 的 exit | ui_manager.c | R2 |
| FIX-08 | RGB Mode 0 切换灯带保存当前编辑 | ui_rgb.c | R2 |
| FIX-09 | Logo 删除动画优化 | ui_logo.c | R2 |
| FIX-10 | 跑步机单击=暂停/恢复 | ui_treadmill.c | R2 |
| FIX-11 | 编码器方向反转不清零累积 | drv_encoder.c | R2 |
| FIX-12 | 编码器累积上限 6→20 | drv_encoder.c | R2 |
| FIX-13 | BLE 队列 xQueueSend 超时 0→100ms | ble_service.c | R2 |
| FIX-14 | 油门 idle 时 fan_speed 匹配 | ui_speed.c | R3 |
| FIX-15 | BLE SPEED:0 后清空编码器队列 | main.c | R3 |
| FIX-16 | LCD:0 时先退出跑步机 | ui_manager.c | R3 |
| FIX-17 | 油门中 FAN 命令返回 ERR | main.c | R3 |
| FIX-18 | BLE 切屏不闪现菜单中间帧 | main.c | R3 |
| FIX-19 | BLE 删 Logo 后 UI6 自动重绘 | ui_logo+main | R3 |
| FIX-20 | 重启后呼吸自动恢复 | main.c | R3 |
| FIX-21 | 按键逻辑重构：单击=油门进出 | ui_speed.c | R4 |

---

*创建日期: 2026-05-08*
