# Z-T1 🏍️

智能风冷骑行装置 — ZCritical 跨平台应用 + 嵌入式固件

## 项目结构

```
Z-T1/
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
