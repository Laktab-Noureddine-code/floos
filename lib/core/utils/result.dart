/// Failure categories (APP_PROMPT §12).
enum FailureKind {
  validation,
  notFound,
  conflict,
  storage,
  crypto,
  importFormat,
  permissionDenied,
}

/// A typed, user-presentable failure. [code] maps to a localized message.
class AppFailure {
  const AppFailure(this.kind, this.code, {this.details, this.args = const {}});

  const AppFailure.validation(this.code, {this.args = const {}})
    : kind = FailureKind.validation,
      details = null;

  const AppFailure.notFound(this.code)
    : kind = FailureKind.notFound,
      details = null,
      args = const {};

  const AppFailure.conflict(this.code, {this.args = const {}})
    : kind = FailureKind.conflict,
      details = null;

  const AppFailure.storage(this.code, {this.details})
    : kind = FailureKind.storage,
      args = const {};

  const AppFailure.crypto(this.code, {this.details})
    : kind = FailureKind.crypto,
      args = const {};

  const AppFailure.importFormat(this.code, {this.details, this.args = const {}})
    : kind = FailureKind.importFormat;

  const AppFailure.permissionDenied(this.code)
    : kind = FailureKind.permissionDenied,
      details = null,
      args = const {};

  final FailureKind kind;

  /// Stable error code, e.g. `amount_zero`, `same_account`.
  final String code;

  /// Developer details (never shown, never contains personal data).
  final String? details;

  /// Arguments for the localized message.
  final Map<String, Object> args;

  @override
  String toString() => 'AppFailure(${kind.name}, $code)';
}

/// Simple success/failure result used by repositories and services.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  AppFailure? get failureOrNull => switch (this) {
    Ok() => null,
    Err(:final failure) => failure,
  };

  /// Returns the value or throws (tests and invariants only).
  T get requireValue => switch (this) {
    Ok(:final value) => value,
    Err(:final failure) => throw StateError(failure.toString()),
  };

  Result<R> map<R>(R Function(T) f) => switch (this) {
    Ok(:final value) => Ok(f(value)),
    Err(:final failure) => Err(failure),
  };

  R fold<R>(R Function(T) ok, R Function(AppFailure) err) => switch (this) {
    Ok(:final value) => ok(value),
    Err(:final failure) => err(failure),
  };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final AppFailure failure;
}
