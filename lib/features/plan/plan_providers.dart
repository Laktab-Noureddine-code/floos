import 'package:floos/app/providers.dart';
import 'package:floos/data/repositories/budgets_repository.dart';
import 'package:floos/data/repositories/debts_repository.dart';
import 'package:floos/data/repositories/goals_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// All non-archived budgets evaluated for the current period.
final budgetViewsProvider = FutureProvider<List<BudgetView>>((ref) async {
  ref
    ..watch(txTickProvider)
    ..watch(budgetsStreamProvider)
    ..watch(todayProvider);
  final repo = ref.watch(budgetsRepoProvider);
  final prefs = ref.watch(prefsProvider);
  final fx = ref.watch(fxProvider);
  final rows = ref.watch(budgetsStreamProvider).value ?? const [];
  return [for (final b in rows) await repo.evaluate(b, prefs, fx, historyPeriods: 6)];
});

/// All goals with live status.
final goalViewsProvider = FutureProvider<List<GoalView>>((ref) async {
  ref
    ..watch(txTickProvider)
    ..watch(goalsStreamProvider)
    ..watch(todayProvider);
  final repo = ref.watch(goalsRepoProvider);
  final goals = ref.watch(goalsStreamProvider).value ?? const [];
  final contributions = await ref.watch(databaseProvider).goalsDao.allContributions();
  final balances = {
    for (final a in await ref.watch(accountsRepoProvider).withBalances(ref.watch(todayProvider)))
      a.account.id: (a.balance, a.account.currencyCode),
  };
  final prefs = ref.watch(prefsProvider);
  final fx = ref.watch(fxProvider);
  return [for (final g in goals) repo.evaluate(g, contributions, balances, prefs, fx)];
});

/// All debts with payments and status.
final debtViewsProvider = FutureProvider<List<DebtView>>((ref) async {
  ref
    ..watch(txTickProvider)
    ..watch(debtsStreamProvider);
  return ref.watch(debtsRepoProvider).views(ref.watch(fxProvider));
});
