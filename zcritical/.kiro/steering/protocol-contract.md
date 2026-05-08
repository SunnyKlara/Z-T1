# ZCritical ↔ ESP32 协议契约

> **用途**: 定义APP与固件的不可变边界，避免重构时破坏通信协议。
> **对应固件**: `hardware/ridewind-esp/main/services/ble_service.c` + `protocol.c`

---

## 一、传输层契约

| 属性 | 值 | 含义 |
|------|-----|------|
| BLE Service UUID | `0000FFE0-0000-1000-8000-00805F9B34FB` | 广播过滤 + 服务发现 |
| BLE Characteristic UUID | `0000FFE1-0000-1000-8000-00805F9B34FB` | Write-without-response + Notify |
| MTU 协商目标 | 247 字节 | ATT_MTU，有效载荷 244 字节 |
| 发送最小间隔 | 2ms | 连续 BLE 包之间的最小延迟 |
| 连接参数优先级 | High (11.25ms interval) | 低延迟连接 |
| 设备名匹配 | "T1" (ESP32), "JDY"/"BT05"/"HC" (旧F4) | 扫描过滤 |

## 二、协议格式契约

```
所有命令格式: KEY:VALUE\n        (APP → ESP32)
所有响应格式: KEY:VALUE\r\n 或 KEY:VALUE\n  (ESP32 → APP，\r\n用于命令确认，\n用于事件报告)
```

**关键规则**:
- `:` 分隔键值
- `\n` 表示命令结束
- 不支持转义字符
- 数据包使用十六进制编码（每字节→2字符）

## 三、命令全集 (APP → ESP32)

### 基础控制
| 命令 | 参数范围 | 说明 |
|------|---------|------|
| `FAN:xx` | xx=0-100 | 风扇速度 |
| `WUHUA:x` | x=0/1 | 雾化器开关 |
| `BRIGHT:xx` | xx=0-100 | LED亮度 |
| `PRESET:xx` | xx=1-14 | LED预设索引 |
| `STREAMLIGHT:x` | x=0/1 | 流水灯开关 |
| `SPEED:xxx` | xxx=0-340 | 速度显示 |
| `LED:s:r:g:b` | s=区域, r/g/b=0-255 | 单区LED颜色 |
| `LED_GRADIENT:s:r:g:b:speed` | speed=渐变速度 | LED渐变 |
| `LCD:x` | x=0/1 | LCD开关 |
| `UI:index` | index=0-4 | 硬件UI切换 |

### 音量控制
| 命令 | 参数范围 |
|------|---------|
| `VOL:xx` | xx=0-100 |
| `GET:VOL` | — |

### 状态查询
| 命令 | 说明 |
|------|------|
| `GET:ALL` | 查询风扇+雾化+亮度 |
| `GET:PRESET` | 查询当前预设 |
| `GET:LOGO_SLOTS` | 查询Logo槽位 |
| `GET:STREAMLIGHT` | 查询流水灯 |

### WiFi音频
| 命令 | 说明 |
|------|------|
| `WIFI:ssid:password` | 发送WiFi凭据 |

### Logo上传
| 阶段 | 命令 | 说明 |
|------|------|------|
| 启动 | `LOGO_START:slot:size:crc32` | slot可选，size=字节数，crc32=CRC32值 |
| 启动(二进制) | `LOGO_START_BIN:size:crc32` | 二进制直传模式 |
| 数据 | `LOGO_DATA:seq:hex` | seq=序号，hex=16字节的十六进制 |
| 结束 | `LOGO_END` | 校验并写入Flash |
| 删除 | `LOGO_DELETE:slot` | slot=0-2 |

### OTA升级
| 阶段 | 命令 |
|------|------|
| 启动 | `OTA_START:size:crc32` |
| 数据 | `OTA_DATA:seq:hex` |
| 结束 | `OTA_END` |

## 四、响应全集 (ESP32 → APP)

### 命令确认 (以`\r\n`结尾)
| 响应 | 含义 |
|------|------|
| `OK:FAN:xx` | 风扇设置确认 |
| `OK:WUHUA:x` | 雾化器确认 |
| `OK:BRIGHT:xx` | 亮度确认 |
| `OK:PRESET:xx` | 预设确认 |
| `OK:STREAMLIGHT:x` | 流水灯确认 |
| `OK:LED` | LED颜色确认 |
| `OK:LED_GRADIENT` | LED渐变确认 |
| `OK:SPEED` | 速度确认 |

### 状态查询响应
| 响应 | 说明 |
|------|------|
| `STATUS:FAN:x:WUHUA:x:BRIGHT:x` | 完整状态 |
| `PRESET_REPORT:x` | 预设值 |
| `LOGO_SLOTS:v0:v1:v2:active` | Logo槽位状态 |
| `VOL:xx` | 音量 |
| `STREAMLIGHT:x` | 流水灯状态 |

### WiFi
| 响应 | 说明 |
|------|------|
| `WIFI_IP:x.x.x.x` | WiFi连接成功 |
| `WIFI_ERR:reason` | WiFi连接失败 |
| `AUDIO_READY:ip:port` | TCP音频服务器就绪 |
| `WIFI_SCAN:USE_PHONE` | 由手机端扫描 |

### Logo上传
| 响应 | 说明 |
|------|------|
| `LOGO_ERASING` | Flash擦除中 |
| `LOGO_READY:slot` | 就绪，槽位已分配 |
| `LOGO_ACK:seq` | 累积确认到seq |
| `LOGO_ACK_BIN:bytes` | 二进制模式已收到字节数 |
| `LOGO_SACK:base:bitmap` | 选择性确认 |
| `LOGO_OK:slot` | 上传成功 |
| `LOGO_FAIL:reason` | 上传失败 |
| `LOGO_ERROR:reason` | 错误 |

### OTA
| 响应 | 说明 |
|------|------|
| `OTA_READY` | 就绪 |
| `OTA_ACK:seq` | 确认 |
| `OTA_OK` | 成功 |
| `OTA_FAIL:reason` | 失败 |

### 硬件事件报告 (以`\n`结尾)
| 响应 | 说明 |
|------|------|
| `SPEED_REPORT:value:unit` | 旋钮调整速度 |
| `THROTTLE_REPORT:x` | 油门状态 |
| `UNIT_REPORT:x` | 单位切换 |
| `PRESET_REPORT:x` | 旋钮切换预设 |
| `ENGINE_START` | 开机 |
| `ENGINE_READY` | 启动完成 |
| `BTN:type:action` | 按钮事件 |
| `SENSOR:type:value` | 传感器数据 |
| `KNOB:delta` / `ENCODER:delta` | 编码器增量 |

## 五、CRC32 契约

```dart
// 与 STM32/ESP32 固件完全一致，严禁修改
static const List<int> _table = [0x00000000, 0x77073096, ...]; // 256项查找表
// 多项式: 0xEDB88320 (reflected)
// 初始值: 0xFFFFFFFF
// 最终异或: 0xFFFFFFFF
// 用于: Logo数据校验, OTA固件校验
```

## 六、Logo传输关键参数

| 参数 | 值 | 来源 |
|------|-----|------|
| Logo图片格式 | 240×240 RGB565 | ESP32 LCD分辨率 |
| Logo原始大小 | 115,200 字节 | 240×240×2 |
| 每包数据量 | 16 字节(hex模式) / 244 字节(bin模式) | 协议约定 |
| ACK频率 | 每16包 | ESP32 `LOGO_BATCH_SIZE` |
| 滑动窗口 | 20-60 包 | 自适应调整 |
| 超时时间 | 80-800ms (RTT自适应) | `RTTEstimator.getTimeout()` |
| 最大重试 | 10次/包(hex) / 3次/段(bin) | 协议约定 |
| 断点续传 | 进度持久化1小时有效 | SharedPreferences |

## 七、修改协议时的检查清单

修改任何协议相关代码时，必须确认:
- [ ] ESP32 固件是否同步更新
- [ ] `PROTOCOL_SPECIFICATION.md` 是否同步更新
- [ ] `ProtocolParser` 的正则是否覆盖新格式
- [ ] `isAckResponse()` 是否排除新确认类型
- [ ] 单元测试是否覆盖新命令/响应
