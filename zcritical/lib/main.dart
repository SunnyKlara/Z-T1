// ══════════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=50 | scope=app | 修改前读 anti-bloat.md
//
// 职责: Flutter 应用入口 — WidgetsBinding 初始化 + runApp
// 不做什么: 不配置路由、不配置主题、不注册依赖。这些在 app.dart
// ══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ZCriticalApp());
}
