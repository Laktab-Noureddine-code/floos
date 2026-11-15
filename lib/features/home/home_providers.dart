import 'package:floos/app/providers.dart';
import 'package:floos/app/services_providers.dart';
import 'package:floos/app/services/summary_service.dart';
import 'package:floos/core/time/period.dart';
import 'package:floos/data/repositories/budgets_repository.dart';
import 'package:floos/data/repositories/transactions_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected Home period as an offset (0 = current custom month).
class HomePeriodOffset extends Notifier<int> {
  @override
  int build() => 0;

  void set(int v) => state = v;
}

final homePeriodOffsetProvider = NotifierProvider<HomePeriodOffset, int>(HomePeriodOffset.new);

/// Custom-month period shown on Home (APP_PROMPT §5.2: never calendar month).
final homePeriodProvider = Provider<Period>((ref) {
  var p = ref.watch(periodCalculatorProvider).monthPeriodFor(ref.watch(todayProvider));
  final offset = ref.watch(homePeriodOffsetProvider);
  for (var i = 0; i < offset; i++) {
    p = p.previous();
  }
  for (var i = 0; i > offset; i--) {
    p = p.next();
  }
  return p;
});

/// Home list ordering toggles (pinned first / recently edited).
class HomeListMode extends Notifier<TxOrder> {
  @override
  TxOrder build() => TxOrder.dateDesc;

  void toggle(TxOrder o) => state = state == o ? TxOrder.dateDesc : o;
}

final homeListModeProvider = NotifierProvider<HomeListMode, TxOrder>(HomeListMode.new);

/// Header + "Your Money" numbers.
class HomeSummary {
  const HomeSummary({required this.balance, required this.delta, required this.totals, required this.missingRates});
  final int balance;
  final int delta;
  final PeriodTotals totals;
  final Set<String> missingRates;
}

final homeSummaryProvider = FutureProvider<HomeSummary>((ref) async {
  ref
    ..watch(txTickProvider)
    ..watch(accountsStreamProvider);
  final today = ref.watch(todayProvider);
  final prefs = ref.watch(prefsProvider);
  final fx = ref.watch(fxProvider);
  final period = ref.watch(homePeriodProvider);
  final summary = ref.watch(summaryServiceProvider);
  final nw = await summary.netWorth(today, prefs.baseCurrency, fx);
  final current = Period.month(today, prefs.monthStartDay);
  final prevDay = current.previousAligned(today).end;
  final before = await summary.netWorth(prevDay, prefs.baseCurrency, fx);
  final totals = await summary.totals(period, prefs.baseCurrency, fx, capAt: today);
  return HomeSummary(
    balance: nw.total,
    delta: nw.total - before.total,
    totals: totals,
    missingRates: {...nw.missingRates, ...totals.missingRates},
  );
});

/// Last ~10 transactions of the period.
final homeTransactionsProvider = StreamProvider<List<TxView>>((ref) {
  final p = ref.watch(homePeriodProvider);
  final order = ref.watch(homeListModeProvider);
  return ref.watch(transactionsRepoProvider).watch(
    TxFilter(startMs: p.startMs, endExclusiveMs: p.endExclusiveMs),
    order: order == TxOrder.dateDesc ? TxOrder.dateDesc : order,
    limit: 10,
  );
});

/// Pending recurring items awaiting confirmation.
final pendingProvider = StreamProvider<List<TxView>>(
  (ref) => ref.watch(transactionsRepoProvider).watch(const TxFilter(pendingOnly: true), limit: 20),
);

/// Up to 5 budgets (most spent first) for the Home snapshot.
final budgetSnapshotProvider = FutureProvider<List<BudgetView>>((ref) async {
  ref
    ..watch(txTickProvider)
    ..watch(budgetsStreamProvider);
  final views = await ref.watch(budgetsRepoProvider).evaluateActive(ref.watch(prefsProvider), ref.watch(fxProvider));
  views.sort((a, b) => b.status.spent.compareTo(a.status.spent));
  return views.take(5).toList();
});

/// Whether any transaction exists (for the Home empty state).
final hasAnyTransactionProvider = FutureProvider<bool>((ref) async {
  ref.watch(txTickProvider);
  return (await ref.watch(databaseProvider).transactionsDao.count()) > 0;
});
