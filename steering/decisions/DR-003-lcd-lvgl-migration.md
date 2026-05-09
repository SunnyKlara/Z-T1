# DR-003: LCD UI 渲染方案 — 手写点阵 → LVGL 迁移

| 字段 | 值 |
|------|-----|
| **状态** | 已确认 |
| **决策日期** | 2026-05-09 |
| **涉及模块** | 固件端 |
| **决策者** | Klara |

## 1. 背景

RideWind 用纯手写点阵字体渲染 LCD UI（`ui_common.c/h` + 10 个 `ui_*.c` 文件，总计 ~70KB C 代码）。问题是：
1. 不支持中文字体（字库太大不适合点阵）
2. 不支持字体缩放
3. 每个新页面需要 200-400 行代码
4. 动画效果有限（手写帧动画）
5. 维护成本高——改一个颜色/字体/间距要改多处

但 LVGL 之前尝试过，效果不好。需要找出根因并针对性解决。

## 2. LVGL 之前的失败原因分析

| 问题 | 可能原因 | 解决方案 |
|------|---------|---------|
| 编译不过 | ESP-IDF v5.x 和 LVGL 版本不匹配 | 锁定 LVGL v8.4（ESP-IDF v5.x 官方适配） |
| 圆形屏显示异常 | LVGL 默认矩形 | `lv_display_set_rotation()` + 内容区裁剪 |
| 帧率低 | 开了双缓冲，内存不够 | 单缓冲 + 局部刷新（240×240 不需要双缓冲） |
| 和 FreeRTOS 冲突 | LVGL tick 默认 1ms 太频繁 | 改为 5ms tick, 放 Core 0（和 BLE 错开） |
| 字体太大 | 完整 TrueType 字库几十 MB | 只提取需要的字符 → 几 KB |

## 3. 方案对比

| 维度 | 手写点阵 | LVGL |
|------|---------|------|
| 开发效率 | 每个页面 200-400 行 | 50-100 行 |
| 字体 | 自制点阵，无中文 | TrueType 任意字号/语言 |
| 动画 | 手写帧动画 | 内置过渡/缩放/渐变 |
| 维护性 | 改一处要改很多地方 | 主题系统全局生效 |
| 社区 | 无 | 活跃, ESP-IDF 官方组件 |
| ROM 占用 | ~20KB | ~200KB |
| CPU 占用 | 低 | 中（可控） |

ESP32-S3 有 8MB Flash，LVGL 200KB 开销完全可接受。

## 4. 最终选择

**迁移到 LVGL v8.4**。

**但保留 RideWind 的 UI 设计**——7 个页面的布局、编码器交互逻辑、菜单导航、速度动画不推翻，只是把底层渲染从 `drv_lcd_draw_xxx()` 换成 LVGL。

**渲染函数映射**：
```
drv_lcd_draw_string()       → lv_label_create()
drv_lcd_draw_circle()       → lv_arc_create()
drv_lcd_fill_rect()         → lv_obj_create() + bg_color
drv_lcd_draw_pixel()        → lv_canvas（不推荐）或 lv_img
ui_common_draw_progress_bar() → lv_bar_create()
```

## 5. 实施步骤

```
Step 1: 最简验证（1天）
  - LVGL v8.4 集成到 ESP-IDF
  - GC9A01 上显示 "Hello World"
  - 验证: SPI 正常、颜色正确、≥30fps

Step 2: 逐页迁移（每页 1-2 天）
  顺序: Speed → Color → RGB → Bright → Menu → Logo → Treadmill
  每迁移一个 → 烧录验证 → 确认无误再下一个

Step 3: 清理
  - 删除旧 ui_*.c 文件
  - 统一主题配置
  - 字体资源提取
```

**字符提取策略**：只提取 UI 实际需要的字符（~100 个字符），不要完整字库。
```
"0123456789 km/hmph%RGBTreadmillSpeedColorMenuBrightLogoVolumePreset"
```

## 6. 不做的

- ❌ 不用 LVGL v9（ESP-IDF 官方适配还在 v8.4）
- ❌ 不推翻 RideWind 的 UI 设计（交互逻辑已经打磨过）
- ❌ 不开双缓冲（内存开销大，对 240×240 单缓冲足够）

## 7. 风险与对策

| 风险 | 对策 |
|------|------|
| LVGL 和 ESP-IDF 版本冲突 | 锁定 LVGL v8.4 + ESP-IDF v5.1.x |
| 圆形屏内容溢出 | 所有内容限制在直径 220px 的圆形区域内 |
| 迁移时引入新 BUG | 逐页迁移，每页烧录验证后再下一个 |
| 编码器交互和 LVGL 冲突 | LVGL input device 直接绑定编码器事件 |

## 8. 相关参考

- 硬件配置: `steering/specs/hardware-config.md` (第三节 LCD)
- 旧 UI 代码: `reference/ridewind-esp/main/ui/` (10 个文件)
- 旧 LCD 驱动: `reference/ridewind-esp/main/drivers/drv_lcd.c`
- 已知陷阱: `steering/knowledge/known-pitfalls.md` (坑 10)
