import 'dart:async';
import 'dart:developer' as developer;

/// Sink for sanitized error records (persisted to the diagnostics log).
typedef ErrorSink = Future<void> Function(String kind, String message, String? stack);

/// Release-safe logger: never logs amounts, notes or other personal data
/// (Constitution II). Only error *types* and stack traces are recorded.
abstract final class AppLogger {
  static ErrorSink? sink;

  static const bool _release = bool.fromEnvironment('dart.vm.product');

  /// Debug-only informational log.
  static void debug(String message) {
    if (!_release) developer.log(message, name: 'floos');
  }

  /// Records an error with its type and stack (no message payloads).
  static void error(String kind, Object error, [StackTrace? stack]) {
    final message = error.runtimeType.toString();
    if (!_release) {
      developer.log('$kind: $message', name: 'floos', error: error, stackTrace: stack);
    }
    final s = sink;
    if (s != null) {
      // Fire and forget; logging must never throw.
      unawaited(s(kind, message, stack?.toString()).catchError((Object _) {}));
    }
  }
}
