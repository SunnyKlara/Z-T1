# CRITICAL T1 桌面级智能风洞

![CRITICAL T1 桌面级智能风洞](images/critical_t1_poster.jpg)

> 融合超声波水雾发烟、AI辅助与独立APP智控，实现"声光电一体化"可视化流体实验体验。

## 项目结构

```
CRITICAL-T1/
├── zcritical/    Flutter 应用 (ZCritical)
│   ├── lib/
│   └── pubspec.yaml
├── firmware/     ESP32-S3 固件 (ridewind-esp)
│   ├── main/
│   └── CMakeLists.txt
├── reference/    RideWind 旧版参考代码（只读）
└── .kiro/        团队协作规范 (steering)
```

## 技术栈

| 层 | 技术 |
|---|------|
| 应用 | Flutter 3.x + Dart (ZCritical) |
| 固件 | ESP-IDF v5.x + C |
| 通信 | BLE 5.0 + WiFi (UDP) |
| LED | WS2812B 可寻址灯带 |

## 启动

```bash
# App
cd zcritical && flutter pub get && flutter run

# Firmware
cd firmware && idf.py build flash monitor
```
