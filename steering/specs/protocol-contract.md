# ⚠️ 软硬件通信协议契约

> **优先级**: CRITICAL — 软硬件之间的唯一真值源
> **作用域**: 全局 — 固件和 APP 两端必须一致

> **用途**: 固件 (ESP32) 和 APP (Flutter) 之间唯一的真值源。
> **规则**: 任何 BLE 命令格式变更，必须先更新此文件，再同步修改两端代码。
> **更新**: 2026-05-08

---

## 一、BLE 连接参数

| 参数 | 值 | 位置 |
|------|-----|------|
| Service UUID | `0000ffe0-0000-1000-8000-00805f9b34fb` | 固件硬编码 |
| Characteristic UUID | `0000ffe1-0000-1000-8000-00805f9b34fb` | write-without-response + notify |
| MTU | 协商至 247，有效载荷 244 字节 | ble_service |
| 设备名称 | `T1` | BLE 广播 |
| 传输格式 | 文本协议，`\n` 结尾 | 所有命令和响应 |
| CRC32 多项式 | `0xEDB88320`，初始 `0xFFFFFFFF`，异或 `0xFFFFFFFF` | Logo / OTA 校验 |

---

## 二、命令表

### 2.1 风扇/速度控制

```
命令               参数范围             响应              备注
─────────────────────────────────────────────────────────────────
FAN:xx             0-100               OK:FAN            设置风扇PWM. 油门模式返回ERR
SPEED:xxx          0-340(kmh)          无                 设置运行速度. 高频命令不回复
                    或0-211(mph)
```

### 2.2 加湿器

```
命令               参数范围             响应              备注
─────────────────────────────────────────────────────────────────
WUHUA:x            0=关, 1=开          OK:WUHUA          油门模式下拒收
```

### 2.3 LED 控制

```
命令               参数范围             响应              备注
─────────────────────────────────────────────────────────────────
LED:s:r:g:b        s:1-2(灯带)         OK:LED            单灯带 RGB 设置
                   r,g,b:0-255
PRESET:x           1-14                OK:PRESET         应用预设颜色
BRIGHT:xx          0-100               OK:BRIGHT         全局亮度
STREAMLIGHT:x      0=关, 1=开          OK:STREAMLIGHT:x  流水灯开关
LED_GRADIENT:s:r:g:b:spd  spd:0-2     OK:LED_GRADIENT   渐变过渡(0=快0.5s,1=中1.5s,2=慢3s)
```

### 2.4 LCD / UI

```
命令               参数范围             响应              备注
─────────────────────────────────────────────────────────────────
LCD:x              0=熄屏, 1=开屏       OK:LCD
UI:x               1=Speed, 2=Color,   OK:UI            直接切换界面
                    3=RGB, 4=Bright,
                    5=Menu, 6=Logo,
                    8=Treadmill
```

### 2.5 音频

```
命令               参数范围             响应              备注
─────────────────────────────────────────────────────────────────
VOL:xx             0-100               OK:VOL            音量控制
```

### 2.6 油门模式

```
命令               参数范围             响应              备注
─────────────────────────────────────────────────────────────────
THROTTLE:x         0=关, 1=开          OK:THROTTLE       油门模式. 开→加湿器强制开
UNIT:x             0=km/h, 1=mph       OK:UNIT           速度单位切换
```

### 2.7 跑步机

```
命令               参数范围             响应              备注
─────────────────────────────────────────────────────────────────
TREAD:xxx          0-999               OK:TREAD:xxx      跑步机目标速度
```

### 2.8 WiFi

```
命令               参数范围             响应              备注
─────────────────────────────────────────────────────────────────
WIFI:ssid:password                     OK:WIFI           WiFi连接. 后续回复WIFI_IP或WIFI_ERR
WIFI_SCAN                              WIFI_SCAN:USE_PHONE  手机端扫描
```

### 2.9 GET 查询

```
命令               响应格式            说明
─────────────────────────────────────────────────────────────────
GET:FAN            FAN:xx             风扇速度
GET:WUHUA          WUHUA:x            加湿器状态
GET:BRIGHT         BRIGHT:xx          亮度
GET:STREAMLIGHT    STREAMLIGHT:x      流光状态
GET:PRESET         PRESET_REPORT:x    当前预设(1-14)
GET:ALL            STATUS:FAN:xx:WUHUA:x:BRIGHT:xx  全状态
GET:UI             UI:x               当前界面
GET:LOGO           LOGO_SLOTS:v0:v1:v2:active  Logo槽位状态
GET:VOL            VOL:xx             音量
GET:TREAD          TREAD_REPORT:xx    跑步机速度
```

### 2.10 Logo 上传协议

```
命令                    响应                  说明
──────────────────────────────────────────────────────────────
LOGO_START:s:size:crc    LOGO_READY:s           开始上传(s=0-2, 0xFF=自动分配)
LOGO_START_BIN:s:size:crc LOGO_READY:s          二进制模式(s bit7=1)
LOGO_DATA:seq:hex_...     LOGO_ACK:seq          每16包ACK一次
LOGO_END                  LOGO_OK:s             成功
                          或 LOGO_FAIL:CRC/LOG   失败
LOGO_DELETE:s             OK:LOGO_DELETE        删除Logo
```

**Logo 格式（不可变）：**
- 尺寸: 240×240 像素
- 格式: RGB565 (每像素 2 字节)
- 大小: 115200 字节
- 固件存储: 16 字节 header + 115200 字节数据 + CRC32

---

## 三、硬件主动上报

```
上报格式                               触发条件
──────────────────────────────────────────────────────────────
SPEED_REPORT:display:unit              旋转编码器调速度时
THROTTLE_REPORT:0/1                    油门模式进出时
UNIT_REPORT:0/1                        单位切换时
PRESET_REPORT:1-14                     预设切换时
STREAMLIGHT_REPORT:0/1                 流光开关时
ENGINE_START                           引擎声启动时
ENGINE_READY                           引擎声就绪时
WIFI_IP:x.x.x.x                        WiFi连接成功后
WIFI_ERR:reason                        WiFi连接失败
AUDIO_READY:ip:port                    TCP音频服务就绪
WIFI_SCAN:USE_PHONE                    让手机扫描WiFi
```

---

## 四、LED 预设对照表

**固件 (`preset_colors.h`) 和 APP (`led_presets.dart`) 必须 14 种完全对齐：**

| 编号 | 名称 | Left/Main (R,G,B) | Right/Tail (R,G,B) |
|------|------|--------------------|---------------------|
| 1 | Flame Red | 255,0,0 | 255,0,0 |
| 2 | Neon Green | 0,255,0 | 0,255,0 |
| 3 | Deep Blue | 0,0,255 | 0,0,255 |
| 4 | Sakura Pink | 255,105,180 | 255,20,147 |
| 5 | Golden Hour | 255,215,0 | 255,140,0 |
| 6 | Mint Fresh | 0,255,128 | 0,206,209 |
| 7 | Lavender | 138,43,226 | 147,112,219 |
| 8 | Crimson | 220,20,60 | 178,34,34 |
| 9 | Ocean Blue | 0,64,255 | 0,191,255 |
| 10 | Lime | 128,255,0 | 50,205,50 |
| 11 | Police Flash | 255,0,0 | 0,0,255 |
| 12 | Sunset Glow | 255,69,0 | 255,140,0 |
| 13 | Purple Haze | 128,0,128 | 186,85,211 |
| 14 | Rainbow | (动态渐变色) | (动态渐变色) |

---

## 五、速度映射约定

```
内部值 (ESP32):       0-100 (app_state.current_speed_kmh)
显示值 km/h:          0-340 (内部值 × 3.4)
显示值 mph:           0-211 (内部值 × 3.4 ÷ 1.60934)

APP 发送 SPEED:xxx → 固件接收后 ÷ 3.4 → 内部值
固件上报 SPEED_REPORT:display:unit → APP 直接使用 display 值
```

---

## 六、变更流程

1. 在此文件中添加/修改命令定义
2. 固件端：修改 `core/protocol/proto_parser.c` / `core/protocol/proto_dispatch.c`
3. APP端：修改 `command_sender.dart` / `protocol_parser.dart`
4. 两端联调验证
5. 更新 UX测试大纲中的命令表

**禁止**：先改代码再加文档。文档不更新 = 文档失效 = 协作崩溃。


## 七、BLE 通信技术细节

### 7.1 数据收发模型

```
APP → 固件 (Write Without Response):
  命令字符串 + \n → BLE Char 0xFFE1 写入

固件 → APP (Notify):
  响应字符串 + \r\n → BLE Char 0xFFE1 通知
```

### 7.2 MTU 分片处理

```
MTU 协商: 247 字节
有效载荷: 244 字节 (247 - 3 字节 ATT 头)

长命令处理:
  如果命令字符串 > 244 字节:
    固件端 s_rx_buf 缓冲, 按 \n 分割重组
    APP 发送时自动分包（BLE 协议栈处理）

典型命令长度:
  FAN:100               8 字节  ← 单包
  LED:3:255:128:64      17 字节 ← 单包
  WIFI:ssid:password    可变    ← 可能超过 MTU
  LOGO_DATA:seq:hex...  可变    ← 多条命令
```

### 7.3 Logo 上传交互序列

```
APP                              固件
│                                │
├──LOGO_START:slot:size:crc32──→│  解析参数, 分配 PSRAM 缓冲
│←────────LOGO_READY:slot───────┤
│                                │
├──LOGO_DATA:0:hexdata1────────→│  每16包 ACK 一次
├──LOGO_DATA:1:hexdata2────────→│
│                         ...    │
├──LOGO_DATA:15:hexdata16──────→│
│←────────LOGO_ACK:15───────────┤
│                         ...    │
├──LOGO_DATA:N:hexdata─────────→│
│                                │
├──LOGO_END────────────────────→│  CRC32 校验 → LittleFS 写入
│←──────LOGO_OK:slot────────────┤  或 LOGO_FAIL:CRC:expected:actual
│                                │

总包数: 115200 / 16字节/包 = 7200 包 (hex 模式)
ACK 频率: 每 16 包
```

### 7.4 硬件主动上报时序

```
速度变化上报 (高频):
  编码器旋转 → SPEED_REPORT:display:unit
  频率: 最高 ~50Hz (20ms 任务周期)

预设变化上报 (低频):
  编码器切换预设 → PRESET_REPORT:n
  频率: 按需

连接状态:
  连接建立 → 不主动上报
  异常断连 → BLE 看门狗 6秒检测 → 断开 → 重新广播
```

### 7.5 同步查询模式

```
APP 发 GET 命令 → 等待 notify 响应(超时3秒) → 解析结果

GET:ALL 响应: STATUS:FAN:50:WUHUA:1:BRIGHT:80
GET:FAN 响应: FAN:50
GET:LOGO 响应: LOGO_SLOTS:1:0:1:0
```


## 八、LED 预设颜色表（完整14种 + RGB值）

| # | 名称 | Main/Left (R,G,B) | Right/Tail (R,G,B) |
|---|------|-------------------|---------------------|
| 1 | Flame Red | 255,0,0 | 255,0,0 |
| 2 | Neon Green | 0,255,0 | 0,255,0 |
| 3 | Deep Blue | 0,0,255 | 0,0,255 |
| 4 | Sakura Pink | 255,105,180 | 255,20,147 |
| 5 | Golden Hour | 255,215,0 | 255,140,0 |
| 6 | Mint Fresh | 0,255,128 | 0,206,209 |
| 7 | Lavender | 138,43,226 | 147,112,219 |
| 8 | Crimson | 220,20,60 | 178,34,34 |
| 9 | Ocean Blue | 0,64,255 | 0,191,255 |
| 10 | Lime | 128,255,0 | 50,205,50 |
| 11 | Police Flash | 255,0,0 | 0,0,255 |
| 12 | Sunset Glow | 255,69,0 | 255,140,0 |
| 13 | Purple Haze | 128,0,128 | 186,85,211 |
| 14 | Rainbow | (动态渐变色) | (动态渐变色) |

> ⚠️ APP 端 `led_presets.dart` 和固件端 `modules/led/led_presets.h` 必须使用相同的 RGB 值。


## 九、速度映射公式（两端必须一致）

```
内部值 (固件 current_speed_kmh): 0-100
显示值 km/h:                    internal × 3.4  (0-340)
显示值 mph:                     internal × 3.4 ÷ 1.60934  (0-211)

APP 发 SPEED:display → 固件接收后 ÷ 3.4 → 内部值
固件上报 SPEED_REPORT:display:unit → APP 直接使用 display
```

---

*创建日期: 2026-05-08 | 修订: 2026-05-08 (补充技术实现细节)*
