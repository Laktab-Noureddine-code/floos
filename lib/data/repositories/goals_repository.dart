import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:floos/core/money/money.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/utils/result.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/repositories/repo_base.dart';
import 'package:floos/data/repositories/settings_repository.dart';
import 'package:floos/data/repositories/transactions_repository.dart';
import 'package:floos/domain/services/fx_service.dart';
import 'package:floos/domain/services/goal_service.dart';

/// Draft for creating/updating a goal.
class GoalDraft {
  const GoalDraft({
    required this.name,
    required this.target,
    required this.start,
    required this.icon,
    required this.color,
    this.id,
    this.deadline,
    this.trackingMode = 'manual',
    this.linkedAccountId,
    this.priority = 0,
  });

  final String? id;
  final String name;
  final int target;
  final LocalDay start;
  final LocalDay? deadline;
  final String trackingMode;
  final String? linkedAccountId;
  final String icon;
  final String color;
  final int priority;
}

/// A goal with contributions and computed status.
class GoalView {
  const GoalView(this.row, this.contributions, this.status);
  final GoalRow row;
  final List<ContributionRow> contributions;
  final GoalStatus status;

  String get id => row.id;
  Set<int> get notifiedMilestones =>
      (jsonDecode(row.milestonesNotified) as List).map((e) => (e as num).toInt()).toSet();
}

class GoalsRepository extends RepoBase {
  GoalsRepository(super.db, {required this.transactions, super.clock, super.hooks});

  final TransactionsRepository transactions;

  Stream<List<GoalRow>> watchAll() => db.goalsDao.watchAll();

  Stream<List<ContributionRow>> watchAllContributions() => db.goalsDao.watchAllContributions();

  Future<GoalRow?> byId(String id) => db.goalsDao.byId(id);

  Future<Result<String>> save(GoalDraft d) => guard(() async {
    final name = d.name.trim();
    if (name.isEmpty || name.length > 40) return const Err(AppFailure.validation('goal_name_length'));
    if (d.target <= 0) return const Err(AppFailure.validation('amount_zero'));
    if (d.target >= kMaxMinorUnits) return const Err(AppFailure.validation('amount_too_large'));
    if (d.deadline != null && d.deadline! <= d.start) {
      return const Err(AppFailure.validation('deadline_before_start'));
    }
    if (d.trackingMode == 'linked' && d.linkedAccountId == null) {
      return const Err(AppFailure.validation('linked_account_required'));
    }
    final existing = d.id == null ? null : await db.goalsDao.byId(d.id!);
    final now = nowMs;
    final id = d.id ?? newId();
    await db.goalsDao.upsert(
      GoalsCompanion(
        id: Value(id),
        createdAt: Value(existing?.createdAt ?? now),
        updatedAt: Value(now),
        name: Value(name),
        targetAmount: Value(d.target),
        startDate: Value(d.start.toStorage()),
        deadline: Value(d.deadline?.toStorage()),
        trackingMode: Value(d.trackingMode),
        linkedAccountId: Value(d.trackingMode == 'linked' ? d.linkedAccountId : null),
        icon: Value(d.icon),
        color: Value(d.color),
        priority: Value(d.priority),
        status: Value(existing?.status ?? 'active'),
        completedAt: Value(existing?.completedAt),
        celebrated: Value(existing?.celebrated ?? false),
        milestonesNotified: Value(existing?.milestonesNotified ?? '[]'),
      ),
    );
    await hooks.onDataChanged();
    return Ok(id);
  });

  /// Adds a contribution (positive) or withdrawal (negative). If
  /// [fromAccountId] is given and the goal is linked, also creates a transfer
  /// to the linked savings account (APP_PROMPT §5.6).
  Future<Result<void>> contribute(
    String goalId,
    int amount,
    LocalDay day, {
    String? note,
    String? fromAccountId,
  }) => guard(() async {
    if (amount == 0) return const Err(AppFailure.validation('amount_zero'));
    if (amount.abs() >= kMaxMinorUnits) return const Err(AppFailure.validation('amount_too_large'));
    final g = await db.goalsDao.byId(goalId);
    if (g == null) return const Err(AppFailure.notFound('goal_not_found'));
    String? txId;
    if (fromAccountId != null && g.linkedAccountId != null && amount > 0) {
      final from = await db.accountsDao.byId(fromAccountId);
      final to = await db.accountsDao.byId(g.linkedAccountId!);
      if (from == null || to == null) return const Err(AppFailure.notFound('account_not_found'));
      if (from.currencyCode != to.currencyCode) {
        return const Err(AppFailure.validation('transfer_currency_mismatch'));
      }
      final r = await transactions.save(
        TxDraft(
          type: 'transfer',
          amount: amount,
          accountId: fromAccountId,
          toAccountId: g.linkedAccountId,
          day: day,
          note: note,
        ),
      );
      if (r case Err(:final failure)) return Err(failure);
      txId = r.valueOrNull;
      // A transfer into the linked account already raises "saved" via the
      // account balance; no manual contribution row is needed.
      await hooks.onDataChanged();
      return const Ok(null);
    }
    final now = nowMs;
    await db.goalsDao.addContribution(
      GoalContributionsCompanion.insert(
        id: newId(),
        createdAt: now,
        updatedAt: now,
        goalId: goalId,
        amount: amount,
        date: day.toStorage(),
        note: Value(note?.trim().isEmpty ?? true ? null : note!.trim()),
        transactionId: Value(txId),
      ),
    );
    await hooks.onDataChanged();
    return const Ok(null);
  });

  Future<Result<void>> deleteContribution(String id) => guard(() async {
    await db.goalsDao.deleteContribution(id);
    await hooks.onDataChanged();
    return const Ok(null);
  });

  /// `active` | `completed` | `archived`.
  Future<Result<void>> setStatus(String id, String status) => guard(() async {
    await (db.update(db.goals)..where((g) => g.id.equals(id))).write(
      GoalsCompanion(
        status: Value(status),
        completedAt: Value(status == 'completed' ? nowMs : null),
        updatedAt: Value(nowMs),
      ),
    );
    await hooks.onDataChanged();
    return const Ok(null);
  });

  Future<void> markCelebrated(String id) => (db.update(db.goals)..where((g) => g.id.equals(id)))
      .write(const GoalsCompanion(celebrated: Value(true)));

  Future<void> markMilestones(String id, Set<int> milestones) =>
      (db.update(db.goals)..where((g) => g.id.equals(id)))
          .write(GoalsCompanion(milestonesNotified: Value(jsonEncode(milestones.toList()..sort()))));

  Future<Result<void>> delete(String id) => guard(() async {
    await db.goalsDao.deleteById(id);
    await hooks.onDataChanged();
    return const Ok(null);
  });

  /// Computes the status of [g]; [balances] are account balances (account
  /// currency) used for linked mode.
  GoalView evaluate(
    GoalRow g,
    List<ContributionRow> contributions,
    Map<String, (int balance, String currency)> balances,
    AppPrefs prefs,
    FxService fx,
  ) {
    final today = clock.today();
    int? linked;
    if (g.trackingMode == 'linked' && g.linkedAccountId != null) {
      final b = balances[g.linkedAccountId];
      if (b != null) {
        linked = fx.convertMinor(b.$1, b.$2, prefs.baseCurrency, today).valueOrNull ?? b.$1;
      }
    }
    final mine = contributions.where((c) => c.goalId == g.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final status = GoalService.evaluate(
      GoalInput(
        target: g.targetAmount,
        start: LocalDay.fromStorage(g.startDate),
        deadline: g.deadline == null ? null : LocalDay.fromStorage(g.deadline!),
        contributions: [
          for (final c in mine) GoalContributionInput(c.amount, LocalDay.fromStorage(c.date)),
        ],
        linkedBalance: linked,
        manuallyCompleted: g.status == 'completed' && g.completedAt != null,
      ),
      today,
    );
    return GoalView(g, mine, status);
  }

  /// Marks goals completed when saved ≥ target; returns newly completed ids.
  Future<List<String>> autoComplete(List<GoalView> views) async {
    final done = <String>[];
    for (final v in views) {
      if (v.row.status == 'active' && v.status.saved >= v.row.targetAmount) {
        await (db.update(db.goals)..where((g) => g.id.equals(v.id))).write(
          GoalsCompanion(status: const Value('completed'), completedAt: Value(nowMs)),
        );
        done.add(v.id);
      }
    }
    return done;
  }
}
