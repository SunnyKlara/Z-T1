// ZCritical 应用入口
// 职责: 启动 Flutter App。配置（主题/路由/DI）推迟到 app.dart。

import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ZCriticalApp());
}
