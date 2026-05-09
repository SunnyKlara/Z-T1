# 固件端 — 会话交接 (可直接执行)

> **给下一个 AI**: 读完这页你就知道该做什么。这里是全部参数，不需要去别的文件找。
> **施工图**: `steering/development-blueprint.md` — 完整阶段规划、任务清单、验收标准

---

## 当前阶段: Phase 2 — 固件骨架 (📍 B1: HAL 驱动)

> 完整 Phase 2 包含 B1(HAL驱动) → B2(BLE协议层) → B3(功能模块)
> 详见 `steering/development-blueprint.md` 第三节

### 目标

```
实现 6 个 HAL 驱动 (LCD / LED / Encoder / Fan / Humidifier / Audio)
每写完一个 → idf.py build → 烧录验证 → 下一个
```

### 具体任务

| # | 文件 | 内容 |
|---|------|------|
| 1 | `firmware/zcritical-esp/CMakeLists.txt` | ESP-IDF 顶层 CMakeLists |
| 2 | `firmware/zcritical-esp/main/CMakeLists.txt` | 主组件 CMakeLists |
| 3 | `firmware/zcritical-esp/main/main.c` | 空壳入口 (~30行) |
| 4 | `firmware/zcritical-esp/sdkconfig.defaults` | SDK 默认配置 |

### main.c 空壳模板

```c
/* ═══════════════════════════════════════════════════════════════
 * STEER: 反臃肿 | scope=firmware | 修改前读 anti-bloat.md
 *
 * 职责: ESP32 固件入口 — 硬件初始化 + 主任务创建
 * 不做什么: 不包含命令分发（proto_dispatch.c）、不包含 Logo 上传（modules/logo/）
 *
 * ⚠️ 白板重建 — 不从 reference/ridewind-esp 搬运代码
 * ═══════════════════════════════════════════════════════════════ */

#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "nvs_flash.h"

static const char *TAG = "ZCRITICAL";

void app_main(void)
{
    // NVS 初始化
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES ||
        ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        nvs_flash_erase();
        nvs_flash_init();
    }

    ESP_LOGI(TAG, "ZCritical ESP32 started");

    // TODO B1: 初始化 HAL 层
    // TODO B2: 初始化状态 + 协议 + BLE

    // 主循环
    while (1) {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}
```

### 硬件参数（唯一真值源: `steering/hardware-config.md`）

| 参数 | 值 |
|------|-----|
| MCU | ESP32-S3 |
| BLE 设备名 | "T1" |
| BLE Service UUID | 0xFFE0 |
| BLE Char UUID | 0xFFE1 |
| LCD 芯片 | GC9A01, 2.4寸圆形 240×240, SPI |
| LCD SPI 引脚 | CS=IO4, DC=IO5, SDA=IO6, SCL=IO7 |
| 编码器 | EC11, 360度20位, S1=IO17, S2=IO18, KEY=IO8(拉低触发) |
| 风扇 PWM | IO40 (CH2, MOS管调速) |
| LED1 WS2812B | IO41 (6颗, 主灯) |
| LED2 WS2812B | IO16 (3颗, 尾灯) |
| 加湿器 GPIO | IO10 (CH1, MOS管开关) |
| 音频 I2S | MAX98357, DIN=IO13, BCLK=IO12, LRC=IO11, 44100Hz |
| 主任务周期 | 20ms |
| 命令队列深度 | 32 |
| Logo 格式 | 240×240 RGB565, 115200字节 |
| CRC32 多项式 | 0xEDB88320 |

### sdkconfig.defaults 关键配置

```
# BLE
CONFIG_BT_ENABLED=y
CONFIG_BT_BLUEDROID_ENABLED=y
CONFIG_BT_CLASSIC_ENABLED=n

# ESP32-S3
CONFIG_IDF_TARGET_ESP32S3=y

# Wi-Fi
CONFIG_ESP_WIFI_ENABLED=y

# SPI 模式
CONFIG_LCD_IO_SPI_MODE=0

# PSRAM
CONFIG_SPIRAM=y
CONFIG_SPIRAM_USE_CAPS_ALLOC=y

# 参考: reference/ridewind-esp/sdkconfig.defaults 获取完整配置
```

### 参考信息

| 想参考什么 | 在哪 |
|-----------|------|
| 原来的 CMakeLists.txt | `reference/ridewind-esp/CMakeLists.txt` |
| 原来的 sdkconfig | `reference/ridewind-esp/sdkconfig` |
| 原来的 partitions.csv | `reference/ridewind-esp/partitions.csv` |

### 验证标准

- [ ] `idf.py set-target esp32s3` 成功
- [ ] `idf.py build` 通过
- [ ] 输出合规检查报告

---

## B1 阶段预览（本次对话如果顺利可以继续）

```
目标: 6个 HAL 驱动全部实现
顺序: gpio → pwm → led → lcd → encoder → audio
每文件参考 ~300 行，职责单一优先
每写完一个 → idf.py build → 烧录验证 → 下一个
```

---

*最后更新: 2026-05-09 | 硬件参数已对齐 hardware-config.md | 白板重建，零行搬运*
