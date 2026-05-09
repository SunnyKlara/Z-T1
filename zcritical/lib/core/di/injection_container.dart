// ══════════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=200 | scope=app-core | 修改前读 anti-bloat.md
//
// 职责: GetIt 依赖注入配置 — 注册 Repository/Service/DataSource 单例和工厂
// 不做什么: 不使用代码生成（injectable）、不注册 UI 层对象（Provider/Screen）
// ══════════════════════════════════════════════════════════════════
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
