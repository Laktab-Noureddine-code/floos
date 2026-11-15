import 'package:floos/core/time/clock.dart';
import 'package:floos/core/utils/logger.dart';
import 'package:floos/core/utils/result.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:uuid/uuid.dart';

/// Hooks fired after data writes (budget alerts, widgets, notifications).
abstract class WriteHooks {
  /// Transactions changed on these storage days (local-midnight ms).
  Future<void> onTransactionsChanged(Set<int> days);

  /// Any other data change (accounts, goals, budgets…).
  Future<void> onDataChanged();
}

/// No-op hooks (tests).
class NoopHooks implements WriteHooks {
  const NoopHooks();

  @override
  Future<void> onTransactionsChanged(Set<int> days) async {}

  @override
  Future<void> onDataChanged() async {}
}

/// Delegating hooks whose target can be set after construction.
class HookRelay implements WriteHooks {
  WriteHooks target = const NoopHooks();

  @override
  Future<void> onTransactionsChanged(Set<int> days) => target.onTransactionsChanged(days);

  @override
  Future<void> onDataChanged() => target.onDataChanged();
}

/// Shared helpers for repositories.
abstract class RepoBase {
  RepoBase(this.db, {this.clock = const Clock(), WriteHooks? hooks})
    : hooks = hooks ?? const NoopHooks();

  final AppDatabase db;
  final Clock clock;
  final WriteHooks hooks;

  static const _uuid = Uuid();

  String newId() => _uuid.v4();
  int get nowMs => clock.now().millisecondsSinceEpoch;

  /// Runs [body] mapping unexpected exceptions to a storage failure.
  Future<Result<T>> guard<T>(Future<Result<T>> Function() body) async {
    try {
      return await body();
    } on Object catch (e, st) {
      AppLogger.error('storage', e, st);
      return Err(AppFailure.storage('storage_error', details: e.runtimeType.toString()));
    }
  }
}
