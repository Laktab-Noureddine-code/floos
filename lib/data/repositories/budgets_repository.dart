import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:floos/core/money/money.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/time/period.dart';
import 'package:floos/core/utils/result.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/db/daos/transactions_dao.dart';
import 'package:floos/data/repositories/repo_base.dart';
import 'package:floos/data/repositories/settings_repository.dart';
import 'package:floos/domain/services/budget_service.dart';
import 'package:floos/domain/services/fx_service.dart';
import 'package:floos/domain/services/totals_service.dart';

/// Budget periods.
const budgetPeriods = ['weekly', 'monthly', 'yearly', 'custom'];

/// Draft for creating/updating a budget.
class BudgetDraft {
  const BudgetDraft({
    required this.amount,
    required this.period,
    this.id,
    this.name,
    this.categoryId,
    this.includeSubcategories = true,
    this.customStart,
    this.customEnd,
    this.rollover = false,
    this.thresholds = const [80, 100],
  });

  final String? id;
  final String? name;
  final String? categoryId;
  final bool includeSubcategories;
  final int amount;
  final String period;
  final LocalDay? customStart;
  final LocalDay? customEnd;
  final bool rollover;
  final List<int> thresholds;
}

/// A budget with display data and its computed status.
class BudgetView {
  const BudgetView({
    required this.row,
    required this.def,
    required this.status,
    this.category,
    this.history = const [],
    this.daily = const {},
  });

  final BudgetRow row;
  final BudgetDef def;
  final BudgetStatus status;
  final CategoryRow? category;

  /// Last periods (oldest first) with spent and limit, for the detail chart.
  final List<(Period, int spent, int limit)> history;

  /// Daily spending in the current period (base currency).
  final Map<LocalDay, int> daily;

  String get id => row.id;
}

class BudgetsRepository extends RepoBase {
  BudgetsRepository(super.db, {super.clock, super.hooks});

  Stream<List<BudgetRow>> watchAll() => db.budgetsDao.watchAll();

  Future<BudgetRow?> byId(String id) => db.budgetsDao.byId(id);

  Future<Result<String>> save(BudgetDraft d) => guard(() async {
    if (d.amount <= 0) return const Err(AppFailure.validation('amount_zero'));
    if (d.amount >= kMaxMinorUnits) return const Err(AppFailure.validation('amount_too_large'));
    if (!budgetPeriods.contains(d.period)) return const Err(AppFailure.validation('period_invalid'));
    if (d.period == 'custom' &&
        (d.customStart == null || d.customEnd == null || d.customEnd! < d.customStart!)) {
      return const Err(AppFailure.validation('custom_range_invalid'));
    }
    final thresholds = d.thresholds.where((t) => t > 0 && t <= 200).toSet().toList()..sort();
    if (await db.budgetsDao.activeExists(d.categoryId, d.period, exceptId: d.id)) {
      return const Err(AppFailure.conflict('budget_exists'));
    }
    var name = d.name?.trim() ?? '';
    if (name.isEmpty && d.categoryId != null) {
      name = (await db.categoriesDao.byId(d.categoryId!))?.name ?? '';
    }
    final existing = d.id == null ? null : await db.budgetsDao.byId(d.id!);
    final now = nowMs;
    final id = d.id ?? newId();
    await db.budgetsDao.upsert(
      BudgetsCompanion(
        id: Value(id),
        createdAt: Value(existing?.createdAt ?? now),
        updatedAt: Value(now),
        name: Value(name),
        categoryId: Value(d.categoryId),
        includeSubcategories: Value(d.includeSubcategories),
        amount: Value(d.amount),
        period: Value(d.period),
        customStart: Value(d.customStart?.toStorage()),
        customEnd: Value(d.customEnd?.toStorage()),
        rollover: Value(d.rollover),
        alertThresholds: Value(jsonEncode(thresholds)),
        archived: Value(existing?.archived ?? false),
      ),
    );
    await hooks.onTransactionsChanged({});
    return Ok(id);
  });

  Future<Result<void>> setArchived(String id, {required bool archived}) => guard(() async {
    final b = await db.budgetsDao.byId(id);
    if (b == null) return const Err(AppFailure.notFound('budget_not_found'));
    if (!archived && await db.budgetsDao.activeExists(b.categoryId, b.period, exceptId: id)) {
      return const Err(AppFailure.conflict('budget_exists'));
    }
    await (db.update(db.budgets)..where((x) => x.id.equals(id)))
        .write(BudgetsCompanion(archived: Value(archived), updatedAt: Value(nowMs)));
    return const Ok(null);
  });

  Future<Result<void>> delete(String id) => guard(() async {
    await db.budgetsDao.deleteById(id);
    return const Ok(null);
  });

  static BudgetDef defOf(BudgetRow b) => BudgetDef(
    id: b.id,
    amount: b.amount,
    period: b.period,
    createdDay: LocalDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(b.createdAt)),
    rollover: b.rollover,
    customStart: b.customStart == null ? null : LocalDay.fromStorage(b.customStart!),
    customEnd: b.customEnd == null ? null : LocalDay.fromStorage(b.customEnd!),
    thresholds: BudgetDef.parseThresholds(b.alertThresholds),
  );

  /// Category ids covered by a budget (null = all expenses).
  Future<Set<String>?> categoryScope(BudgetRow b) async {
    if (b.categoryId == null) return null;
    if (!b.includeSubcategories) return {b.categoryId!};
    final all = await db.categoriesDao.getAll();
    return {b.categoryId!, ...all.where((c) => c.parentId == b.categoryId).map((c) => c.id)};
  }

  /// Evaluates one budget for the period containing [at] (default today).
  Future<BudgetView> evaluate(
    BudgetRow b,
    AppPrefs prefs,
    FxService fx, {
    LocalDay? at,
    int historyPeriods = 0,
  }) async {
    final today = clock.today();
    final def = defOf(b);
    final scope = await categoryScope(b);
    final current = BudgetService.periodFor(
      def,
      at ?? today,
      monthStartDay: prefs.monthStartDay,
      weekStartDay: prefs.weekStartDay,
    );
    // One aggregate covering rollover/history periods, bucketed in Dart.
    final back = def.period == 'custom'
        ? 0
        : [historyPeriods, if (def.rollover) BudgetService.maxRolloverPeriods else 0].reduce((a, c) => a > c ? a : c);
    var from = current;
    for (var i = 0; i < back; i++) {
      from = from.previous();
    }
    final range = Period.custom(from.start, current.end);
    final rows = await db.transactionsDao.aggregate(
      type: 'expense',
      startMs: range.startMs,
      endExclusiveMs: LocalDay.min(range.end, today).addDays(1).toStorage(),
      categoryIds: scope ?? const {},
    );
    final converted = TotalsService.convert(
      rows.map((r) => DaySum(key: null, currency: r.currency, day: LocalDay.fromStorage(r.date), sum: r.sum)),
      prefs.baseCurrency,
      fx,
    );
    int spentIn(Period p) => converted.byDay.entries
        .where((e) => p.contains(e.key) && e.key <= today)
        .fold<int>(0, (a, e) => a + e.value);
    final status = BudgetService.evaluate(
      def,
      today,
      spentIn,
      at: at,
      monthStartDay: prefs.monthStartDay,
      weekStartDay: prefs.weekStartDay,
    );
    final history = <(Period, int, int)>[];
    if (historyPeriods > 0 && def.period != 'custom') {
      var p = current;
      for (var i = 0; i < historyPeriods; i++) {
        final s = BudgetService.evaluate(
          def,
          today,
          spentIn,
          at: p.start,
          monthStartDay: prefs.monthStartDay,
          weekStartDay: prefs.weekStartDay,
        );
        history.insert(0, (p, s.spent, s.available));
        p = p.previous();
      }
    }
    final category = b.categoryId == null ? null : await db.categoriesDao.byId(b.categoryId!);
    return BudgetView(
      row: b,
      def: def,
      status: status,
      category: category,
      history: history,
      daily: {
        for (final e in converted.byDay.entries)
          if (status.period.contains(e.key)) e.key: e.value,
      },
    );
  }

  Future<List<BudgetView>> evaluateActive(AppPrefs prefs, FxService fx) async {
    final rows = await db.budgetsDao.active();
    return [for (final b in rows) await evaluate(b, prefs, fx)];
  }

  /// Logs newly crossed thresholds for the *current* period only and returns
  /// them (alerts never fire for past periods, APP_PROMPT §13.6).
  Future<List<(BudgetView, int)>> newAlerts(AppPrefs prefs, FxService fx, Set<int> changedDays) async {
    final today = clock.today();
    final out = <(BudgetView, int)>[];
    for (final view in await evaluateActive(prefs, fx)) {
      final p = view.status.period;
      final relevant = changedDays.isEmpty ||
          changedDays.any((d) => p.contains(LocalDay.fromStorage(d)));
      if (!relevant || !p.contains(today)) continue;
      for (final t in view.def.thresholds) {
        if (view.status.progressPermille >= t * 10) {
          final inserted = await db.budgetsDao.logAlert(view.id, p.startMs, t, nowMs);
          if (inserted) out.add((view, t));
        }
      }
    }
    return out;
  }

  /// Transactions of a budget in its current period.
  Future<TxFilter> filterFor(BudgetView v) async {
    final scope = await categoryScope(v.row);
    return TxFilter(
      startMs: v.status.period.startMs,
      endExclusiveMs: v.status.period.endExclusiveMs,
      types: const {'expense'},
      categoryIds: scope ?? const {},
    );
  }
}
