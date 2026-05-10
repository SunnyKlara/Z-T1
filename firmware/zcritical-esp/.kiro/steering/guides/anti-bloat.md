# ⚠️ RideWind ESP32 固件防臃肿纲领

> **优先级**: CRITICAL — 违反此纲领 = 代码腐烂
> **作用域**: 固件端 — 所有 firmware/ 下的 C 文件

> **用途**: 确保固件代码（C/ESP-IDF）在迭代中保持干净可维护。
> **核心理念**: 固件的臃肿比软件更致命——编译慢、内存爆、调试难、Bug 难复现。
>             防臃肿靠的不是"写好代码"，而是**让破坏规则的成本高于遵守规则的成本**。

---

## 一、理解臃肿是怎么发生的

```
第1天:  干净的 main.c，150行，初始化+任务循环
第30天: 加个新 BLE 命令，往 dispatch_ble_command 塞 30 行 — "就一个 case"
第60天: 修个 Bug，在 main.c 加个全局变量 —"这里特殊处理一下就行"
第90天: Logo 上传逻辑全塞 main.c — "反正跟命令分发也挺像的"
第120天: main.c 500行了 —"算了，能跑就行，后面再说"
第180天: main.c 893行了 —"这谁写的？app_state 怎么有 50 个字段？"

问题出在第30天，不是第180天。
每一次妥协在当时都是合理的，但没有人阻止它发生。
```

---

## 二、嵌入式 C 代码臃肿的特定成因

```
❌ 全局变量无节制增长 → AppState 变成 200 字段的垃圾桶
❌ main.c 往死里塞 → 初始化+分发+Logo上传+业务逻辑全挤一个文件
❌ 无职责声明 → 每个 .c 文件做什么全靠猜
❌ #define 散落各处 → board_config.h/pin_config.h/preset_colors.h 各自为政
❌ UI 页面互相耦合 → ui_manager.c 知道所有 UI 的内部细节
❌ 驱动层没有统一接口 → drv_led 和 drv_pwm 设计风格不一致
❌ FreeRTOS 资源泄漏 → Queue/Queue、Task 创建后没有对应的清理
❌ 临界区过大 → APP_STATE_LOCK 锁住太多代码
❌ 日志滥用 → ESP_LOG 在 BLE 回调里打印大量调试信息
```

---

## 三、七道防线

### 防线 1: 文件行数是参考信号，不是硬性限制

**核心原则**：可维护性 > 行数。逻辑清晰的 500 行好过强行拆分的 3 个 100 行碎片。

| 区域 | 参考行数 | 执行方式 |
|------|---------|---------|
| `main/main.c` | **~500 行** | AI 自查 + 提交前检查报告 |
| `main/app/*.c` — 应用层 | **~400 行** | AI 自查 |
| `main/drivers/*.c` — 驱动层 | **~300 行** | AI 自查 |
| `main/services/*.c` — 服务层 | **~400 行** | AI 自查 |
| `main/ui/*.c` — UI 页面 | **~350 行** | AI 自查 |
| `main/config/*.h` — 配置文件 | **~400 行** | 宽松 |
| `main/resources/*.c` — 资源文件 | **不限** | 资源文件天然大 |
| 预警线 | **200 行** | AI 自查时触发 |

**当前问题文件（需关注）：**
- `main.c` — **893 行** 🔴 职责过多，需拆分为 3 个文件
- `drv_lcd.c` — 待检查
- `ui_manager.c` — 待检查
- `ui_treadmill.c` — 待检查
- `led_effects.c` — 待检查

**判断标准（替代行数检查）**：
写完文件后问自己：
1. 这个文件的职责能用一句话说清楚吗？
2. 如果要修改一个功能，需要动这个文件的多少地方？
3. 新同事打开这个文件，3 分钟内能理解全貌吗？

三个答案都是"是" → 不拆，行数多少无所谓。

### 防线 2: 目录结构就是架构边界

```
main/
├── config/     → 只能放 #define / const / 配置宏。禁止函数实现。
├── drivers/    → 硬件抽象层。每文件一个外设。禁止包含业务逻辑或 UI 逻辑。
├── app/        → 应用层状态机。只能 #include "drivers/", "config/"。
├── services/   → BLE/协议/WiFi/音频/存储。可以 #include "drivers/", "app/"。
├── ui/         → LCD 渲染逻辑。每文件一个界面页面。#include "drivers/", "app/"。
├── utils/      → 纯数学/工具函数。禁止 #include "app/" 或 "ui/"。
├── resources/  → 图片/字体/音频资源数据。禁止函数实现。
└── lib/        → 第三方库。禁止修改。
```

**禁止的 #include 方向（违反即架构破坏）：**
- `drivers/` → ⛔ 不能 #include `services/`、`ui/`
- `app/` → ⛔ 不能 #include `services/`、`ui/`
- `ui/` → ⛔ 页面之间不能互相 #include（只能通过 `ui_manager.h` 调用）
- `config/` → ⛔ 不能 #include 任何业务代码
- `services/` → ⛔ 不能 #include `ui/`

**检查方法：**
```bash
# 跨层依赖检查
grep -r '#include.*services/' main/drivers/
grep -r '#include.*services/' main/app/
grep -r '#include.*ui_' main/drivers/
grep -r '#include.*ui_' main/services/
```

### 防线 3: 每个 .c/.h 文件顶部有 STEER 约束 + 职责声明

```c
/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | max_lines=300 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: GC9A01 圆形 LCD 驱动——初始化、画像素、清屏、局部刷新
 * 不做什么: 不处理 UI 逻辑、不管理 framebuffer 策略、不处理显示内容
 * ═══════════════════════════════════════════════════════════════ */
```

**规则：**
- 新建文件必须包含完整的 STEER 块 + 职责声明
- 修改已有文件时，如果缺少 STEER 块，必须先补上
- 职责声明中"不做什么"比"做什么"更重要——防止越界

### 防线 4: AppState 的字段必须按域分组 + 每个域有上限

```c
typedef struct {
    // ══ 风扇/PWM ══  (上限: 5个字段)
    uint8_t fan_speed;           // 0-100, PWM 占空比
    
    // ══ 加湿器 ══  (上限: 5个字段)
    uint8_t wuhuaqi_state;       // 0=关, 1=开, 2=油门(强制开)
    uint8_t wuhuaqi_state_saved; // 油门之前的加湿器状态
    
    // ══ LED 颜色 ══  (上限: 10个字段)
    uint8_t led_colors[2][3];    // [strip(0-1)][rgb(0-2)], 0-255 — Main/Tail
    uint8_t led_edit[2][3];      // RGB界面编辑暂存
    uint8_t brightness;          // 0-100
    uint8_t preset_index;        // 1-14
    int     preset_dirty;        // 预设变更标记
    
    // ══ 速度 ══  (上限: 5个字段)
    int16_t current_speed_kmh;   // 内部值 0-100（非显示值）
    int16_t last_reported_speed; // BLE 上报的显示值 0-340
    uint8_t speed_unit;          // 0=km/h, 1=mph
    
    // ══ UI ══  (上限: 8个字段)
    uint8_t ui;                  // 当前界面编号
    uint8_t menu_selected;       // 菜单选中页
    
    // ══ 音频 ══  (上限: 5个字段)
    uint8_t volume;              // 0-100
    
    // ══ Logo ══  (上限: 5个字段)
    uint8_t active_logo_slot;    // 0-2
    
    // ══ 流水灯/特效 ══  (上限: 5个字段)
    uint8_t streamlight_active;  // 流水灯状态
} app_state_t;
```

**规则：**
- AppState 总字段数 ≤ 40 个
- 每个域 ≤ 10 个字段
- 单个域超过 10 个字段 → 拆成子结构体
- 总字段数超过 40 个 → 重构讨论
- 新增字段必须在注释中标明所属域

### 防线 5: 新功能三步走（写入 commit 或 session-handoff）

每次加新功能，必须先回答三个问题：

```
Q1: 这个功能属于哪个域？
    (风扇/PWM / 加湿器 / LED / 速度 / UI / 音频 / Logo / BLE / WiFi / 存储 / ...)

Q2: 这个域对应的文件在哪？
    (列出具体 .c 文件路径)

Q3: 现有文件能容纳吗？
    - 职责匹配吗？（检查文件头部的"不做什么"）
    - 加了之后行数还在限制以内吗？
    → 如果任何一个答案是"否"，新建文件
```

### 防线 6: 一次提交只做一件事

| ✅ 允许 | ❌ 禁止 |
|--------|--------|
| 修一个 Bug | 修 Bug + 顺便重构 LED 驱动 |
| 加一个新 UI 页面 | 加 UI + 顺便改编码器驱动 |
| 拆分 main.c | 拆分 + 顺便改协议格式 |
| 添加新 BLE 命令 | 加命令 + 顺便重构整个 dispatch |
| 修改编码规范 | 改规范 + 顺便加新功能 |

**原因**: "顺便改"最危险。两个变更混在一起，review 看不出问题，回滚也回不干净。

### 防线 7: Steering 文件跟着代码一起改

| 代码变更 | 需更新的文档 |
|----------|------------|
| 新增/修改 BLE 命令格式 | `steering/protocol-contract.md` |
| 修改 AppState 字段 | `firmware/.kiro/steering/architecture.md` 状态管理一节 |
| 拆分文件 | `firmware/.kiro/steering/architecture.md` 文件规模一节 |
| 新增 UI 界面 | `firmware/.kiro/steering/architecture.md` UI 界面表 |
| 发现 Bug | `firmware/ridewind-esp/UX测试大纲.md` 已修复 Bug 清单 |
| 对话结束 | `firmware/.kiro/session-handoff.md` |

---

## 四、固件端特定规则

### 4.1 全局变量铁律

**禁止在其他文件中新增全局变量。全局变量只能在 `app_state.h` 中定义。**

```c
// ❌ 禁止——在 main.c 中定义全局变量
static bool s_logo_binary_mode = false;

// ✅ 允许——在 app_state.h 中定义，通过 app_state 访问
// 或者，如果只在本文件使用且非业务状态，可以用 static
// 但必须加注释说明为什么不是全局状态
```

### 4.2 FreeRTOS 资源管理

```c
// ✅ 创建资源时必须注册清理逻辑
QueueHandle_t cmd_queue = xQueueCreate(CMD_QUEUE_DEPTH, sizeof(cmd_msg_t));
// 在对应的 deinit 函数中：
// vQueueDelete(cmd_queue);

// ✅ Task 创建时记录 handle
TaskHandle_t main_task_handle;
xTaskCreatePinnedToCore(main_task, "main", 4096, NULL, 5, &main_task_handle, 1);
// 在对应的 deinit 函数中：
// vTaskDelete(main_task_handle);
```

### 4.3 临界区规范

```c
// ✅ 好——最小化临界区
APP_STATE_LOCK();
g_app_state.fan_speed = speed;
APP_STATE_UNLOCK();

drv_pwm_set_duty(speed);  // 耗时操作在锁外

// ❌ 坏——临界区包含耗时操作
APP_STATE_LOCK();
g_app_state.fan_speed = speed;
drv_pwm_set_duty(speed);  // 硬件操作在锁内
APP_STATE_UNLOCK();
```

### 4.4 BLE 回调规范

```c
// BLE 回调中：
// ✅ 可以: 接收数据、xQueueSend 入队、简单计算
// ❌ 禁止: 调用 ble_service_notify_str（异步发送可能在回调中出问题）
// ❌ 禁止: 阻塞等待（BLE 回调在系统线程中）
// ❌ 禁止: 直接修改 g_app_state（跨核竞争，必须通过 Queue）
// ⚠️  例外: Logo 数据快速路径（hex_decode → PSRAM memcpy → ACK）因性能需要直接在回调中处理
```

### 4.5 内存分配规范

```c
// 大量数据 → PSRAM
uint8_t *buf = heap_caps_malloc(size, MALLOC_CAP_SPIRAM);
if (!buf) {
    ESP_LOGE(TAG, "PSRAM alloc failed for %u bytes", (unsigned)size);
    return;  // 安全降级
}

// 频繁访问的小数据 → DRAM (默认)
cmd_msg_t *cmd = malloc(sizeof(cmd_msg_t));
if (!cmd) {
    ESP_LOGW(TAG, "malloc failed");
    return;
}
```

---

## 五、原型阶段与正式阶段

> ⚠️ **这条规则是 2026-05-08 从 RideWind 教训中学到的。**

### 核心问题

固件的 `main.c` 最初可能只是"测试代码"，但因为没有规定"原型何时退出"，一路膨胀到 893 行。

### 两阶段定义

| 阶段 | 特征 | 规范要求 |
|------|------|---------|
| **原型阶段** | 文件头部注明 `// 原型：...` + 退出条件 | 可超行数，但必须注明 |
| **正式阶段** | 文件头部有 `STEER` 块 + 职责声明 | 必须遵守所有规范 |

### 退出条件（任一触发即强制拆分）

| 触发条件 | 处理方式 |
|---------|---------|
| 文件行数超过 200 行 | 立即拆分，不等 |
| 原型功能被用于真实硬件（上了 PCB 板） | 必须正式化后才能继续 |
| 开始修改/迭代该文件的功能 | 必须先拆分再改 |

### 铁律

> **"先试试看"不是"不遵守规范"的借口。**
> 
> 实验在分支上做。效果好合并（先正式化再合），效果不好删分支。

---

## 六、main.c 拆分路线图

当前 `main.c` (893行) 包含的内容：

| 区域 | 行数 | 应归属 | 新文件名 |
|------|------|--------|---------|
| Logo 上传协议（hex/binary decode + CRC + 文件写入） | ~350行 | services/ | `services/logo_receiver.c` |
| BLE 命令分发 `dispatch_ble_command()` | ~400行 | services/ | `services/command_dispatch.c` |
| 主任务循环 `main_task()` | ~30行 | main.c | 保留 |
| 硬件初始化 `app_main()` | ~100行 | main.c | 保留 |

**拆分后目标：**
- `main.c` → ~150行（初始化 + 任务循环 + 头文件引用）
- `services/command_dispatch.c` → ~400行（命令分发 switch-case）
- `services/logo_receiver.c` → ~350行（Logo 上传协议完整实现）

### 拆分步骤

```
步骤 1: 创建 services/command_dispatch.c + .h
         - 移动 dispatch_ble_command() 函数体
         - 移动响应构造辅助函数
         - 移动所有 case 块
         - 保留 app_state.h / protocol.h 依赖

步骤 2: 创建 services/logo_receiver.c + .h
         - 移动所有 Logo 上传相关代码：
           - hex_nibble(), logo_upload_feed_hex()
           - logo_upload_feed_binary()
           - logo_is_binary_mode(), logo_rx_cleanup()
           - LOGO_START/DATA/END 的 case 块
         - 移动 s_logo_rx 静态变量到 logo_receiver.c

步骤 3: 清理 main.c
         - 删除已移动的函数
         - 添加 #include "services/command_dispatch.h"
         - 添加 #include "services/logo_receiver.h"
         - 验证编译
         - 验证 main.c ≤ 500 行
```

---

## 七、臃肿早期预警信号

| 信号 | 严重程度 | 处理 |
|------|---------|------|
| .c 文件超过 200 行 | 🟡 预警 | 计划拆分 |
| 新增文件无 STEER 块 | 🟡 预警 | 补上再合 |
| 新增文件无职责声明 | 🟡 预警 | 补上再合 |
| AppState 字段超过 30 个 | 🟡 预警 | 讨论是否需要拆子结构 |
| AppState 某个域超过 10 个字段 | 🟡 预警 | 拆分该域为子结构 |
| dispatch_ble_command 新增 case | 🟡 预警 | 考虑是否该拆到独立文件 |
| main.c 超过 500 行 | 🔴 严重 | 必须拆分 |
| 驱动层 #include "ui_" | 🔴 严重 | 必须修复 |
| 驱动层 #include "services/" | 🔴 严重 | 必须修复 |
| 新增全局变量不在 app_state.h | 🔴 严重 | 必须移入或说明 |
| "先这样，后面再整理" | 🔴 严重 | 后面永远不会整理 |

---

## 八、需要妥协时的原则

1. **架构方向不能妥协** — include 方向、层次边界
2. **行数可以临时超标** — 但必须开 issue，标注"下次迭代拆分"，main.c 不超过 600
3. **职责可以临时模糊** — 但必须在职责声明里写清楚"正在越界"
4. **命名可以后期改** — 名字不对不破坏架构
5. **注释可以后期补** — 逻辑对最重要

**一句话**: 可以暂时允许乱，但必须让所有人知道这是乱的（issue + 职责声明标注），并且有明确的清理时间。

---

## 九、与 APP 端的协同原则

1. **协议契约先行** — BLE 命令格式变更同时在 `steering/protocol-contract.md` 中更新
2. **LED 预设同步** — `preset_colors.h` (固件) ↔ `led_presets.dart` (APP) 必须 14 种完全对齐
3. **速度映射一致** — `speed_math.h` (固件) ↔ APP 速度换算逻辑必须一致
4. **Logo 格式锁定** — 240×240 RGB565 115200字节，不可变
5. **CRC32 多项式锁定** — 0xEDB88320，不可变
6. **固件修改要保守** — 不改变已有命令格式（向后兼容）
7. **APP 要容忍** — 对未知响应不做 crash，只打日志

---

*创建日期: 2026-05-08 | 基于 ZCritical anti-bloat.md 定制*
