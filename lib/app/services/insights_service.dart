import 'package:floos/app/services/summary_service.dart';
import 'package:floos/core/time/clock.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/time/period.dart';
import 'package:floos/data/repositories/budgets_repository.dart';
import 'package:floos/data/repositories/goals_repository.dart';
import 'package:floos/data/repositories/recurring_repository.dart';
import 'package:floos/data/repositories/settings_repository.dart';
import 'package:floos/data/repositories/transactions_repository.dart';
import 'package:floos/domain/services/fx_service.dart';
import 'package:floos/domain/services/goal_service.dart';
import 'package:floos/domain/services/insight_engine.dart';
import 'package:floos/domain/services/recurring_engine.dart';

/// Gathers inputs for the [InsightEngine] from repositories (APP_PROMPT §5.9).
class InsightsService {
  const InsightsService({
    required this.summary,
    required this.budgets,
    required this.goals,
    required this.recurring,
    required this.transactions,
    this.clock = const Clock(),
  });

  final SummaryService summary;
  final BudgetsRepository budgets;
  final GoalsRepository goals;
  final RecurringRepository recurring;
  final TransactionsRepository transactions;
  final Clock clock;

  Future<List<Insight>> compute(AppPrefs prefs, FxService fx) async {
    final today = clock.today();
    final period = Period.month(today, prefs.monthStartDay);
    final base = prefs.baseCurrency;
    final current = await summary.totals(period, base, fx, capAt: today);
    final prevAligned = period.previousAligned(today);
    final previous = await summary.totals(prevAligned, base, fx);
    final cats = {for (final c in await transactions.db.categoriesDao.getAll()) c.id: c};

    final budgetInputs = [
      for (final v in await budgets.evaluateActive(prefs, fx))
        BudgetInsightInput(
          id: v.id,
          name: v.row.name.isEmpty ? '' : v.row.name,
          percent: v.status.percent,
          spent: v.status.spent,
          available: v.status.available,
          perDay: v.status.remainingPerDay,
        ),
    ];

    final balances = {
      for (final a in await summary.accounts.withBalances(today)) a.account.id: (a.balance, a.account.currencyCode),
    };
    final contributions = await goals.db.goalsDao.allContributions();
    final goalInputs = <GoalInsightInput>[];
    for (final g in await goals.db.goalsDao.getAll()) {
      if (g.status != 'active') continue;
      final v = goals.evaluate(g, contributions, balances, prefs, fx);
      if (v.status.state == GoalState.behind) {
        goalInputs.add(GoalInsightInput(id: g.id, name: g.name, neededPerMonth: v.status.neededPerMonth ?? 0));
      }
    }

    final bills = <BillInsightInput>[];
    for (final r in await recurring.getAll()) {
      if (!r.active || r.templateType != 'expense') continue;
      final next = RecurringEngine.between(
        RecurringRepository.scheduleOf(r),
        LocalDay.fromStorage(r.nextDueDate),
        r.occurrencesCount,
        today,
        today.addDays(InsightEngine.billWindowDays),
      );
      if (next.isEmpty) continue;
      final account = await transactions.db.accountsDao.byId(r.templateAccountId);
      final name = RecurringRepository.displayName(r).isNotEmpty
          ? RecurringRepository.displayName(r)
          : (cats[r.templateCategoryId]?.name ?? '');
      bills.add(BillInsightInput(
        ruleId: r.id,
        name: name,
        amount: r.templateAmount,
        currency: account?.currencyCode ?? base,
        daysUntil: today.daysUntil(next.first),
      ));
    }

    // Category trend: compare day N to day N, rolled up to parents.
    Map<String, int> roll(Map<String?, int> m) {
      final out = <String, int>{};
      for (final e in m.entries) {
        if (e.key == null) continue;
        final root = cats[e.key]?.parentId ?? e.key!;
        out[root] = (out[root] ?? 0) + e.value;
      }
      return out;
    }

    final curByCat = roll(current.expenseByKey);
    final prevByCat = roll(previous.expenseByKey);
    final trends = [
      for (final e in curByCat.entries)
        if (cats[e.key] != null)
          CategoryTrendInput(categoryId: e.key, name: cats[e.key]!.name, current: e.value, previous: prevByCat[e.key] ?? 0),
    ];

    // Unusual: today's/recent expenses > 3× category median (90 days).
    final unusual = <UnusualTxInput>[];
    final recent = await transactions.get(
      TxFilter(types: const {'expense'}, startMs: today.addDays(-6).toStorage(), endExclusiveMs: today.addDays(1).toStorage()),
      limit: 50,
    );
    final medians = <String, int>{};
    for (final t in recent) {
      final cid = t.tx.categoryId;
      if (cid == null || t.tx.excludeFromReports) continue;
      final m = medians[cid] ??= InsightEngine.median(
        await transactions.db.transactionsDao.categoryAmounts(cid, today.addDays(-90).toStorage()),
      );
      unusual.add(UnusualTxInput(
        txId: t.tx.id,
        categoryName: t.categoryName ?? '',
        amount: t.tx.amount,
        currency: t.accountCurrency,
        median: m,
      ));
    }

    final last = await transactions.db.transactionsDao.lastTransactionDate();
    final count = await transactions.db.transactionsDao.count(includePending: false);
    final lastBackup = prefs.lastBackupAt;
    return InsightEngine.compute(InsightInputs(
      budgets: budgetInputs,
      goalsBehind: goalInputs,
      bills: bills,
      categoryTrends: trends,
      unusual: unusual,
      income: current.income,
      expense: current.expense,
      daysSinceLastTx: last == null ? null : LocalDay.fromStorage(last).daysUntil(today),
      daysSinceBackup: lastBackup == null ? null : clock.now().difference(lastBackup).inDays,
      hasData: count > 0,
      dismissed: (prefs.dismissedInsights[period.key] ?? const []).toSet(),
    ));
  }
}
