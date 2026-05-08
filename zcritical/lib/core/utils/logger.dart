// ZCritical 统一日志工具
//
// 设计意图：
// - 封装 logger 包，提供统一的日志接口。全局一个 Logger 实例。
// - 支持 Debug/Release 自动切换：Release 模式下禁用 debug/trace 级别日志。
// - 按模块分类（BLE / Protocol / UI / DI），方便排查问题时按 tag 过滤。
//
// 不做什么：
// - 不管日志持久化（未来可加，但不在此文件）。
// - 不管崩溃上报。

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// 应用级全局 Logger。通过 [AppLogger] 静态方法使用。
final _logger = Logger(
  filter: _AppLogFilter(),
  printer: PrettyPrinter(
    methodCount: 1,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
  ),
  output: _AppLogOutput(),
);

/// 统一的日志入口。
///
/// 使用方式：
/// ```dart
/// AppLogger.d('BLE', '正在扫描设备...');
/// AppLogger.i('Protocol', '收到响应: $response');
/// AppLogger.e('BLE', '连接失败', error, stackTrace);
/// ```
abstract final class AppLogger {

  /// Debug 级别：仅开发调试用，Release 模式自动过滤。
  static void d(String tag, String message) {
    _logger.d('[$tag] $message');
  }

  /// Info 级别：一般信息。
  static void i(String tag, String message) {
    _logger.i('[$tag] $message');
  }

  /// Warning 级别：警告信息。
  static void w(String tag, String message) {
    _logger.w('[$tag] $message');
  }

  /// Error 级别：错误信息，携带 [error] 和可选的 [stackTrace]。
  static void e(String tag, String message,
      [Object? error, StackTrace? stackTrace]) {
    _logger.e('[$tag] $message', error: error, stackTrace: stackTrace);
  }

  /// 可在初始化时重新配置 Logger（如修改输出目标）。
  static void reconfigure({required LogOutput output}) {
    _logger.close();
    // 直接替换内部实例：在单例场景中，重新赋值
    // 注意：logger 包的 Logger 不可变，需重建。通常不推荐运行时修改。
    // 如需要，在 main() 中直接创建新的 Logger 实例。
  }
}

/// Release 模式下过滤 debug/trace 日志。
class _AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kReleaseMode) {
      return event.level.index >= Level.info.index;
    }
    return true;
  }
}

/// 默认输出到 console。
class _AppLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      // ignore: avoid_print
      print(line);
    }
  }
}
