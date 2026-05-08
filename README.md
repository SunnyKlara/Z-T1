# Z-T1

桌面级智能风洞 — 1:64 微缩模型，桌上风速实验室。

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
