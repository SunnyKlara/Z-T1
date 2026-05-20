# 固件端 — 会话交接

## 当前阶段：固件骨架完成 → 待烧录验证 + 功能精装

B0 ✅ BLE广播 | B1 ✅ 6 HAL | B2 ✅ 状态+协议 | B3 ✅ 7模块骨架

## B2+B3 成果（本次对话一次性完成）

**idf.py build 零错误零警告**。zcritical-esp.bin (0xce970 bytes)。

| 层 | 新增文件 | 个数 |
|----|---------|------|
| core/state/ | state_fan.h / state_led.h / state_ui.h / state_audio.h / state_logo.h / app_state.h / app_state.c | 7 |
| core/protocol/ | proto_parser.h/c / proto_dispatch.h/c | 4 |
| modules/fan/ | fan_module.h/c | 2 |
| modules/led/ | led_module.h/c (含14种预设) | 2 |
| modules/display/ | display_module.h/c | 2 |
| modules/encoder/ | encoder_module.h/c | 2 |
| modules/audio/ | audio_module.h/c | 2 |
| modules/logo/ | logo_module.h/c | 2 |
| modules/wifi/ | wifi_module.h/c | 2 |
| main.c | 重写集成全部 | 1 |
| **合计** | | **26 文件** |

## 固件能力

- ✅ BLE 广播 "T1"，接收 APP 命令
- ✅ 全部 31 条协议命令解析 + 分发
- ✅ 状态管理（5子结构体+互斥锁）
- ✅ 14 种 LED 预设
- ✅ 编码器调速/调预设 + BLE 上报
- ✅ 风扇PWM + 加湿器GPIO + 油门模式
- ✅ 7 模块骨架（audio/display/logo/wifi 待硬件验证后精装）

## 编译

`.\build_fw.ps1 build` — Windows, ESP-IDF v5.3.5

---

## BLE 广播优化（2026-05-11）

**变更文件**: `core/protocol/proto_ble.c`

**变更内容**:
- 广播主包：包含设备名称 "T1" + 标志位（`include_name = true`）
- 扫描响应：已移除（不再需要，名称直接在广播包中）
- Service UUID 从广播数据中移除（APP 按名称过滤，不需要 UUID）
- 目的：APP 扫描时可在广播包中直接获取设备名称，无需额外扫描请求

**影响**: 无协议变更。APP 端扫描按设备名称 "T1" 过滤，现在可直接匹配广播包。

---

*B0-B6 ✅ | POST 自检固件就绪 | 待烧录验证 → LVGL | 2026-05-11*

## POST 自检固件（2026-05-11）

**idf.py build 零错误零警告**。zcritical-esp.bin (0xd1130 bytes)。

开机自动跑 11 项硬件自检：PSRAM / 加湿器GPIO / 风扇PWM(50%) / LED1(6颗绿) / LED2(3颗蓝) / LCD / 编码器EC11 / 按键 / I2S / BLE / 模块层。

结果同时输出到串口 + LCD 屏幕。自检完成后 BLE 广播 T1 待命（APP 可连接）。没有 UI 没有菜单 — 纯验证硬件链路。

**下一步**: 用户烧录 → 看串口+LCD 结果 → 确认硬件 OK → 引入 LVGL 精装 UI。

## B6: 编码器页面切换 + BLE 命令→外设联动（2026-05-11）

**idf.py build 零错误零警告**。zcritical-esp.bin (0xd13f0 bytes)。

操作方式：
- 旋转编码器：Speed页调速 / Color页切换预设 / Bright页调亮度
- 长按按键：进入菜单
- 菜单中旋转+单击：选择页面 / 切加湿器 / 切油门

`proto_dispatch.c` 全部 TODO 已替换为真实 module 调用（fan/led/display/audio）。APP 发 BLE 命令可控制全部外设。

**idf.py build 零错误零警告**。zcritical-esp.bin (0xd0d20 bytes)。

- `hal_lcd.c`: 内嵌 5x8 位图字体（ASCII 0x20-0x7E, 95 字符），支持 size=1/2 缩放
- `display_module.c`: 6 个精装页面，含通用标题栏+BLE状态点
  - Speed: 24刻度表盘 + 大号速度值 + 底部状态栏（色块/加湿器/油门）
  - Color: 14 预设名 2列×7行
  - RGB: 颜色预览圆 + R/G/B 数值 + 三色进度条
  - Bright: 百分比 + 进度条 + 4 快捷值
  - Menu: 3×3 图标网格（FAN/LED/BRT/HUM/THR/LCD/LOGO/WIFI/INFO）
  - Logo/Treadmill: 占位


---

## UI 设计方案评估分支（2026-05-12 起）

**新分支**: `ui/lvgl-demo`（从 `app/a3-ble-connect` 切出，未提交代码）

**目的**: 评估 LVGL vs RideWind 贴图法两种 UI 方案，烧录看效果再决定。

**已分析**:
- RideWind UI 像素级布局（7 屏 + 共享背景图 + 53px 大数字 + 8帧滑动动画）已记录
- 两种方案对比已写在对话历史
- 三选项: A 像素复刻 RideWind / B LVGL 矢量重做 / C 全新设计

**下一步**: 在 `ui/lvgl-demo` 分支集成 LVGL + esp_lvgl_port + 复刻 1 个菜单页面，烧录验证视觉效果。

---

## 文档体系审计（2026-05-12）

**无代码变更**。对文档管理体系做了全面审查，产出分析报告（在对话历史中）。

**发现的关键问题**:
1. APP 端 17 个 steering 文件存在大量重叠（AI角色×3、行数限制×3、开发流程×3）
2. 固件端 anti-bloat.md 引用 RideWind 旧目录结构，与实际 core+modules 架构不符
3. 行数限制规则在多文件间矛盾（300 vs 350，硬限制 vs 参考值）
4. APP 端 architecture-map 是规划态，与实际代码量不匹配

**建议的下一步**:
- APP 端 17 文件合并为 5-6 个，消除重复
- 固件端 anti-bloat 用当前架构重写
- 统一矛盾规则（以 conversation-lessons 教训3 为准：职责单一 > 行数）

---

## 文档模式提炼（2026-05-12）

**新增文件**: `steering/knowledge/documentation-patterns.md`

从 ZCritical 实战中提炼出完整的 AI 协作操作系统，覆盖 4 大子系统、18 个可复用模式：
1. 知识管理（5 模式）：唯一入口、Session Handoff、唯一真值源、知识传承、能力边界
2. AI 协作模式（5 模式）：角色定位、契约驱动、沟通模板、产品思维注入、争议义务
3. 质量保障（5 模式）：架构边界、跨端同步、失败考古、命名统一、防腐烂
4. 自动化守护（3 模式）：IDE Hooks、构建脚本、文档演化机制

已注册到 `steering/specs/project-overview.md` 索引。
