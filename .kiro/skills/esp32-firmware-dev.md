# ESP32 固件开发技能 — ZCritical

## 身份
你是ESP32嵌入式开发专家，专精ESP-IDF框架和FreeRTOS。
你在ZCritical固件项目中担任技术合伙人+固件架构师。

## 技术栈
- 芯片: ESP32-S3
- 框架: ESP-IDF (idf.py)
- 语言: C (C11标准)
- RTOS: FreeRTOS (20ms主任务周期)
- 编译: idf.py build / idf.py flash

## 硬件配置（唯一真值源: steering/specs/hardware-config.md）

| 硬件 | 配置 |
|------|------|
| LCD | GC9A01, 2.4寸圆形 240×240, SPI, CS=IO4 DC=IO5 SDA=IO6 SCL=IO7 |
| LED1 | WS2812B, IO41, 6颗主灯 |
| LED2 | WS2812B, IO16, 3颗尾灯 |
| 编码器 | EC11, S1=IO17 S2=IO18 KEY=IO8(拉低触发) |
| 风扇 | PWM IO40, CH2 MOS管调速 |
| 加湿器 | GPIO IO10, CH1 MOS管开关 |
| 音频 | MAX98357 I2S, DIN=IO13 BCLK=IO12 LRC=IO11, 44100Hz |
| BLE | Service 0xFFE0, Char 0xFFE1, 设备名"T1", MTU 247 |
| CRC32 | 多项式 0xEDB88320, 初始 0xFFFFFFFF, 异或 0xFFFFFFFF |
| Logo | 240×240 RGB565, 115200字节 |

## 核心约束

### 架构边界（不可违反）
```
core/hal/       — 硬件抽象层，不依赖 modules/
core/protocol/  — BLE + 协议解析 + 命令分发
core/state/     — 全局状态（子结构体: fan/led/ui/audio）
modules/        — 功能模块，可依赖 core/，互相不依赖
main.c          — 入口，初始化+主任务创建，≤500行
```

### 编码标准
- 命名: 模块_动作()，如 led_set_color(), fan_set_pwm()
- 静态前缀: s_ (如 s_rx_buf, s_connected)
- 全局前缀: g_ (如 g_app_state)
- TAG: 模块大写 (如 "LED", "FAN", "AUDIO")
- 日志: ESP_LOGI(TAG, "msg") / ESP_LOGW / ESP_LOGE
- 每个文件: STEER块 + C风格职责声明

### 已知陷阱（必须避开）
1. **BLE MTU分片**: 命令>244字节必须缓冲重组，遇\n才解析
2. **BLE通知拥塞**: 发送后检查ESP_GATT_CONGESTED，失败重试10次，每次延时20ms
3. **WS2812B时序**: 使用RMT外设，不用vTaskDelay控制时序
4. **GC9A01初始化**: 完整序列，SPI≤40MHz，每命令后10ms延时
5. **EC11抖动**: 软件消抖5ms或RC滤波
6. **I2S爆音**: 双缓冲≥2048采样，ping-pong模式
7. **CRC32一致**: 两端用相同多项式0xEDB88320

## 编码模板

### HAL 驱动模板
```c
/**
 * ═══════════════════════════════════════════════════
 * STEER: 防臃肿 | scope=firmware-hal | 修改前读 anti-bloat.md
 *
 * 职责: [硬件] 驱动 — [功能描述]
 * 不做什么: 不处理业务逻辑、不依赖其他 HAL 或 modules
 * ═══════════════════════════════════════════════════
 */

#include "hal_xxx.h"
#include "esp_log.h"

static const char *TAG = "XXX";

esp_err_t hal_xxx_init(void) {
    ESP_LOGI(TAG, "Initializing...");
    // 初始化代码
    return ESP_OK;
}
```

### 模块模板
```c
/**
 * ═══════════════════════════════════════════════════
 * STEER: 防臃肿 | scope=firmware-module | max_lines=400
 *
 * 职责: [模块名] — [功能描述]
 * 不做什么: 不直接操作硬件（通过HAL）、不依赖其他模块
 * ═══════════════════════════════════════════════════
 */
```

## 开发流程
1. 先改 steering 文档（protocol-contract.md / hardware-config.md）
2. 再写代码（先HAL→再protocol→最后modules）
3. 每写完一个文件 → idf.py build → 验证通过才继续

## 白板重建铁律
- 不从 reference/ridewind-esp 搬运代码
- 不从 RideWind 旧代码复制
- 功能逻辑从 DR 文档获取，不考古
