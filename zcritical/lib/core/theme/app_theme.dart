// ZCritical 主题配置
//
// 设计意图：
// - 集中管理所有 Material3 主题配置。Screen 和 Widget 不单独设置颜色/字体。
// - 深色主题（暗色背景 + 霓虹光效）是默认风格，对应风洞的科技感。
// - 同时提供浅色主题备用（设置中可切换）。
// - 使用 `ThemeExtension` 扩展自定义颜色（风速指示色、LED 预览色等）。
//
// 不做什么：
// - 不定义具体页面布局参数（padding、spacing 等）——那些归 Widget 自己管。
// - 不包含业务颜色（如 LED 预设色在 domain/ 定义）。

import 'package:flutter/material.dart';

/// App 主题入口。
///
/// 使用方式：
/// ```dart
/// MaterialApp(
///   themeMode: ThemeMode.system,
///   darkTheme: AppTheme.dark,
///   theme: AppTheme.light,
/// );
/// ```
abstract final class AppTheme {

  /// 深色主题（默认风格）。
  static ThemeData get dark => _buildDarkTheme();

  /// 浅色主题（备选）。
  static ThemeData get light => _buildLightTheme();

  // ---- 深色主题 ----

  static ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: colorScheme.surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        thumbColor: AppColors.accent,
        overlayColor: AppColors.accent.withValues(alpha: 0.2),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 0.5,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        AppColorExtension(),
      ],
    );
  }

  // ---- 浅色主题 ----

  static ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: colorScheme.surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        thumbColor: AppColors.accent,
        overlayColor: AppColors.accent.withValues(alpha: 0.2),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 0.5,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        AppColorExtension(),
      ],
    );
  }
}

// ---- 颜色常量 ----

/// ZCritical 品牌 & 功能色。
///
/// 暗色主题下使用高饱和度霓虹色，模拟风洞仪表盘。
abstract final class AppColors {
  AppColors._();

  // 品牌
  static const Color primary = Color(0xFF00BCD4);    // 青色 - 风洞科技感
  static const Color accent = Color(0xFF00E5FF);     // 亮青 - 高亮指示

  // 背景
  static const Color backgroundDark = Color(0xFF0D1117);   // 极深灰蓝
  static const Color surfaceDark = Color(0xFF161B22);      // 深色卡片
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  // 语义色
  static const Color connected = Color(0xFF4CAF50);        // 已连接
  static const Color disconnected = Color(0xFF9E9E9E);     // 未连接
  static const Color warning = Color(0xFFFFC107);          // 警告
  static const Color error = Color(0xFFFF5252);            // 错误

  // 风速指示色
  static const Color speedLow = Color(0xFF00E5FF);         // 低速（对应 accent）
  static const Color speedMid = Color(0xFFFFC107);         // 中速
  static const Color speedHigh = Color(0xFFFF5252);        // 高速

  // LED 预览色（提取自硬件 preset_colors.h）
  static const List<Color> presetPreviewColors = [
    Color(0xFFFF0000), // Red
    Color(0xFF00FF00), // Green
    Color(0xFF0000FF), // Blue
    Color(0xFFFFFF00), // Yellow
    Color(0xFFFF00FF), // Magenta
    Color(0xFF00FFFF), // Cyan
    Color(0xFFFFFFFF), // White
    Color(0xFFFF8000), // Orange
    Color(0xFF8000FF), // Purple
    Color(0xFF00FF80), // Mint
    Color(0xFFFF4080), // Pink
    Color(0xFF80FF00), // Lime
    Color(0xFF0040FF), // Ocean Blue
    Color(0xFFFF0000), // Rainbow (placeholder)
  ];
}

/// 自定义颜色扩展，通过 `Theme.of(context).extension<AppColorExtension>()` 访问。
class AppColorExtension extends ThemeExtension<AppColorExtension> {
  const AppColorExtension();

  /// 风速仪表盘圆环低值颜色
  Color get gaugeLow => AppColors.speedLow;

  /// 风速仪表盘圆环高值颜色
  Color get gaugeHigh => AppColors.speedHigh;

  /// BLE 已连接指示色
  Color get bleConnected => AppColors.connected;

  /// BLE 未连接指示色
  Color get bleDisconnected => AppColors.disconnected;

  @override
  ThemeExtension<AppColorExtension> copyWith() {
    return this;
  }

  @override
  ThemeExtension<AppColorExtension> lerp(
    covariant ThemeExtension<AppColorExtension>? other,
    double t,
  ) {
    return this;
  }
}
