# RideWind ESP32 C 编码规范

> **用途**: 固件 C 代码的统一编码标准。与 AI 协作时自动应用。
> **核心理念**: 一致性 > 个人偏好。和 AI 协作的核心价值在于"每次输出的代码风格一致"。

---

## 一、命名规范

### 1.1 函数命名

```
模式: 模块前缀_动作_对象()
示例:
  led_set_color()          — 驱动层
  led_get_brightness()     — 驱动层 getter
  audio_engine_start()     — 服务层
  ble_service_notify()     — 服务层
  ui_speed_update()        — UI 层
  storage_logo_save()      — 存储层
```

**规则：**
- 全部小写 + 下划线
- 模块前缀反映所在文件（drv_led → led_xxx, ui_speed → ui_speed_xxx）
- 动作在前，对象在后
- 避免超过 4 个下划线（太长的函数名说明需要拆分）

### 1.2 变量命名

```c
// 全局变量 — g_ 前缀
app_state_t g_app_state;
QueueHandle_t g_cmd_queue;

// 静态变量（文件内全局）— s_ 前缀
static bool s_logo_binary_mode = false;
static uint32_t s_logo_bin_batch_bytes = 0;

// 局部变量 — 蛇形命名
uint8_t strip_index;
uint32_t calculated_crc;

// 常量 — 全大写 + 下划线
#define MAX_LOGO_SLOTS 3
#define LED_STRIP1_COUNT 6    // Main, IO41
```

### 1.3 类型命名

```c
// 结构体 — _t 后缀
typedef struct { ... } cmd_msg_t;
typedef struct { ... } app_state_t;

// 枚举 — _t 后缀
typedef enum { ... } cmd_type_t;
typedef enum { ... } led_strip_id_t;
```

### 1.4 文件命名

```
模式: 模块_子模块.c / .h
  drv_led.c / drv_led.h           — 驱动层：LED
  ble_service.c / ble_service.h   — 服务层：BLE
  ui_speed.c / ui_speed.h         — UI层：速度页面
  command_dispatch.c / command_dispatch.h — 服务层：命令分发
```

---

## 二、文件结构

### 2.1 每个 .c 文件的标准结构

```c
/**
 * 职责: [一句话说明这个文件的职责]
 * 不做什么: [明确排除的职责]
 */

/* ── 标准库 ── */
#include <stdio.h>
#include <string.h>

/* ── ESP-IDF ── */
#include "esp_log.h"
#include "freertos/FreeRTOS.h"

/* ── 项目内部 ── */
#include "board_config.h"
#include "drv_xxx.h"

static const char *TAG = "MODULE_NAME";

/* ── 静态变量 ── */
static int s_internal_state = 0;

/* ── 公开函数实现 ── */

void module_init(void) { ... }

void module_action(int param) { ... }

/* ── 静态辅助函数 ── */

static void helper_function(void) { ... }
```

### 2.2 每个 .h 文件的标准结构

```c
#pragma once

/* ── 公开类型 ── */

typedef struct { ... } xxx_t;

/* ── 公开函数声明 ── */

/**
 * @brief 初始化 XXX 模块
 * @return ESP_OK 成功, 其他 失败
 */
esp_err_t xxx_init(void);

/**
 * @brief 执行 XXX 操作
 * @param value 参数说明，含取值范围
 * @return ESP_OK 成功, ESP_ERR_INVALID_ARG 参数非法
 */
esp_err_t xxx_action(uint8_t value);
```

---

## 三、函数规范

### 3.1 函数长度

- 单个函数 ≤ **80 行**（C 函数天生比 Dart 长，但不超过这个上限）
- 超过 80 行 → 提取子函数
- 超过 120 行 → 必须拆分（设计问题）

### 3.2 参数数量

- 参数 ≤ **5 个**
- 超过 5 个 → 用结构体封装

```c
// ❌ 不好
void led_set_color(int r, int g, int b, int brightness, bool refresh, int delay_ms);

// ✅ 好
typedef struct { int r, g, b; } rgb_t;
void led_set_color(rgb_t color, uint8_t brightness);
```

### 3.3 错误处理

```c
// ✅ 所有外设操作检查返回值
esp_err_t err = drv_lcd_init();
if (err != ESP_OK) {
    ESP_LOGE(TAG, "LCD init failed: %s", esp_err_to_name(err));
    return err;
}

// ✅ 指针参数做 null 检查
void process_data(const uint8_t *data, size_t len) {
    if (!data || len == 0) {
        ESP_LOGW(TAG, "Invalid data pointer");
        return;
    }
    // ...
}

// ❌ 禁止静默忽略错误
drv_lcd_init();  // 返回值被丢弃

// ❌ 禁止 assert（Release 模式无效）
assert(ptr != NULL);

// ✅ 用 ESP_LOG 代替 assert
if (!ptr) { ESP_LOGE(TAG, "NULL pointer"); return; }
```

---

## 四、日志规范

```c
static const char *TAG = "MODULE";  // 每个 .c 文件声明

ESP_LOGI(TAG, "正常信息: %d", value);
ESP_LOGW(TAG, "警告: %s", reason);
ESP_LOGE(TAG, "错误: 0x%08X", error_code);
```

**日志级别规则：**
- `ESP_LOGI` → 正常业务流程标记
- `ESP_LOGW` → 可恢复的异常
- `ESP_LOGE` → 不可恢复的错误
- `ESP_LOGD` → Debug 信息，Release 自动移除
- 禁止 `printf` — 使用 ESP_LOG

---

## 五、注释规范

### 5.1 函数注释（Doxygen 风格）

```c
/**
 * @brief 将当前 LED 颜色持久化到 NVS
 * @return ESP_OK 成功, ESP_ERR_NVS_NOT_FOUND 首次使用（正常）
 */
static esp_err_t save_led_colors_to_nvs(void);
```

### 5.2 区段分隔

```c
/* ═══════════════════════════════════════════════════════════════
 *  风扇控制
 * ═══════════════════════════════════════════════════════════════ */

/* ── 辅助函数 ── */
```

使用 UTF-8 框线字符分区段（项目已采用此风格）。

### 5.3 TODO 标记

```c
// TODO(P1): 添加 NVS 读取失败的重试机制
// FIXME: 竞态：这里可能在 BLE 回调中被中断
// HACK: 临时方案，等 PSRAM 驱动稳定后替换
```

---

## 六、内存管理

- **PSRAM**: 大量数据使用 `heap_caps_malloc(size, MALLOC_CAP_SPIRAM)`
- **DRAM**: 小结构体和频繁访问的数据
- **禁止**: `malloc`/`free`（不用标准 C 的，用 FreeRTOS 的 `pvPortMalloc` 或 ESP-IDF 的 `heap_caps_malloc`）
- **必须**: `malloc` 后检查 `NULL`

---

## 七、格式规范

- **缩进**: 4 空格（不用 Tab）
- **行宽**: ≤ 100 字符
- **大括号**: K&R 风格（`if (...) {` 在同一行）
- **switch 缩进**: case 与 switch 对齐

```c
switch (cmd->type) {
case CMD_FAN:
    drv_pwm_set_duty(cmd->param.u8_val);
    break;
case CMD_LED:
    // ...
    break;
default:
    break;
}
```

---

*创建日期: 2026-05-08*
