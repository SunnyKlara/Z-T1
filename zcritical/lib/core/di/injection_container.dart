// ZCritical 依赖注入配置
//
// 设计意图：
// - 使用 GetIt 作为 Service Locator。所有 Repository / Service / DataSource 在此注册。
// - 单例（Singleton）用于全局共享对象（BLE Service、Logger、SharedPreferences）。
// - 工厂（Factory）用于每次请求新建的对象（UseCase、Provider 状态）。
// - `init()` 在 `main()` 中调用一次。`sl<>()` 作为全局快捷访问。
//
// 不做什么：
// - 不使用代码生成（injectable）。Flutter 3.41.6 缺少 _macros SDK。
// - 不注册 UI 层对象（Provider / Screen）。UI 对象由 Riverpod 管理。
//
// 使用方式：
// ```dart
// // main() 中初始化
// await InjectionContainer.init();
//
// // 任意位置获取
// final repo = sl<DeviceRepository>();
// ```

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 全局 Service Locator 实例。
final sl = GetIt.instance;

/// 依赖注入容器。
abstract final class InjectionContainer {

  /// 初始化所有依赖。在 `main()` 中 `WidgetsFlutterBinding.ensureInitialized()` 之后调用。
  static Future<void> init() async {
    _registerCore();
    await _registerAsync();
    _registerRepositories();
    _registerUseCases();
  }

  /// Core 层同步注册（零依赖对象）。
  static void _registerCore() {
    // 暂无需要同步注册的 core 对象。
    // 预留：Crc32Calculator、PlatformInfo 等。
  }

  /// 需要异步初始化的依赖。
  static Future<void> _registerAsync() async {
    // SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    sl.registerSingleton<SharedPreferences>(prefs);
  }

  /// Data 层 Repository 实现注册。
  /// 当前 Phase 0：暂为空。等 Phase 1 实现 Repository 时注册。
  static void _registerRepositories() {
    // 示例（Phase 1 实现时取消注释）：
    // sl.registerLazySingleton<DeviceRepository>(
    //   () => DeviceRepositoryImpl(bleService: sl(), mapper: sl()),
    // );
  }

  /// Domain 层 UseCase 注册。
  /// 当前 Phase 0：暂为空。
  static void _registerUseCases() {
    // 示例（Phase 1 实现时取消注释）：
    // sl.registerFactory<ConnectDeviceUseCase>(
    //   () => ConnectDeviceUseCase(repository: sl()),
    // );
  }

  /// 重置所有注册（仅测试用）。
  @visibleForTesting
  static Future<void> reset() async {
    await sl.reset();
  }
}
