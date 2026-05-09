// ══════════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=120 | scope=app-core | 修改前读 anti-bloat.md
//
// 职责: Result<T> 统一结果类型 — 替代异常，纯 Dart，零依赖
// 不做什么: 不依赖任何业务 model、不引入第三方库
// ══════════════════════════════════════════════════════════════════
// - 提供 map/fold/getOrElse 等函数式组合方法。
//
// 使用示例：
// ```dart
// Result<int> divide(int a, int b) {
//   if (b == 0) return Result.failure('除数不能为零');
//   return Result.ok(a ~/ b);
// }
//
// // 模式匹配
// result.map(
//   ok: (value) => print('结果: $value'),
//   failure: (error) => print('失败: $error'),
// );
// ```

sealed class Result<T> {
  const Result();

  /// 成功的 [Result]，携带值 [value]。
  const factory Result.ok(T value) = _Ok<T>;

  /// 失败的 [Result]，携带错误描述 [error]。
  const factory Result.failure(String error) = _Failure<T>;

  /// 是否为成功结果
  bool get isOk => this is _Ok<T>;

  /// 是否为失败结果
  bool get isFailure => this is _Failure<T>;

  /// 成功时返回值，失败时返回 [defaultValue]。
  T getOrElse(T defaultValue) => switch (this) {
        _Ok(:final value) => value,
        _Failure() => defaultValue,
      };

  /// 成功时返回 [T]，失败时抛出异常（仅限万不得已时使用）。
  T getOrThrow() => switch (this) {
        _Ok(:final value) => value,
        _Failure(:final error) =>
          throw ResultException(error),
      };

  /// 成功时返回 [T]，失败时返回 null。
  T? getOrNull() => switch (this) {
        _Ok(:final value) => value,
        _Failure() => null,
      };

  /// 获取成功值；如果失败则调用 [onFailure] 并返回其结果。
  T getOrHandle(T Function(String error) onFailure) => switch (this) {
        _Ok(:final value) => value,
        _Failure(:final error) => onFailure(error),
      };

  /// 模式匹配：成功和失败分别走不同分支。
  R map<R>({
    required R Function(T value) ok,
    required R Function(String error) failure,
  }) =>
      switch (this) {
        _Ok(:final value) => ok(value),
        _Failure(:final error) => failure(error),
      };

  /// 成功时执行 [onOk] 副作用，始终返回自身（用于链式调用）。
  Result<T> onSuccess(void Function(T value) onOk) {
    if (this case _Ok(:final value)) onOk(value);
    return this;
  }

  /// 失败时执行 [onFailure] 副作用，始终返回自身。
  Result<T> onFailure(void Function(String error) onFailure) {
    if (this case _Failure(:final error)) onFailure(error);
    return this;
  }

  /// 将成功值转换为另一种类型（map 的简化版，仅映射成功分支）。
  Result<R> mapSuccess<R>(R Function(T value) transform) =>
      switch (this) {
        _Ok(:final value) => Result.ok(transform(value)),
        _Failure(:final error) => Result.failure(error),
      };

  /// 成功时调用 [fn] 并用其结果替换当前 Result（flatMap/bind）。
  Result<R> flatMap<R>(Result<R> Function(T value) fn) => switch (this) {
        _Ok(:final value) => fn(value),
        _Failure(:final error) => Result.failure(error),
      };

  /// 解构为 (value, error) 记录类型，方便 Dart 3 的模式解构使用。
  (T?, String?) get toRecord => switch (this) {
        _Ok(:final value) => (value, null),
        _Failure(:final error) => (null, error),
      };

  @override
  String toString() => switch (this) {
        _Ok(:final value) => 'Ok($value)',
        _Failure(:final error) => 'Failure($error)',
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return switch ((this, other)) {
      (_Ok<T>(value: final v1), _Ok<T>(value: final v2)) => v1 == v2,
      (_Failure<T>(error: final e1), _Failure<T>(error: final e2)) => e1 == e2,
      _ => false,
    };
  }

  @override
  int get hashCode => switch (this) {
        _Ok(:final value) => value.hashCode ^ 0x1,
        _Failure(:final error) => error.hashCode ^ 0x2,
      };
}

/// 成功变体
final class _Ok<T> extends Result<T> {
  final T value;
  const _Ok(this.value);
}

/// 失败变体
final class _Failure<T> extends Result<T> {
  final String error;
  const _Failure(this.error);
}

/// 当调用 [Result.getOrThrow] 且结果为失败时抛出。
class ResultException implements Exception {
  final String message;
  const ResultException(this.message);

  @override
  String toString() => 'ResultException: $message';
}
