import 'package:floos/app/providers.dart';
import 'package:floos/app/services/summary_service.dart';
import 'package:floos/app/services_providers.dart';
import 'package:floos/core/time/period.dart';
import 'package:floos/data/repositories/transactions_repository.dart';
import 'package:floos/domain/services/report_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected Report period (null = current custom month).
class ReportPeriod extends Notifier<Period?> {
  @override
  Period? build() => null;

  void set(Period? p) => state = p;
}

final reportPeriodProvider = NotifierProvider<ReportPeriod, Period?>(ReportPeriod.new);

/// Expense / income toggle.
class ReportType extends Notifier<String> {
  @override
  String build() => 'expense';

  void set(String v) => state = v;
}

final reportTypeProvider = NotifierProvider<ReportType, String>(ReportType.new);

final effectiveReportPeriodProvider = Provider<Period>(
  (ref) => ref.watch(reportPeriodProvider) ?? ref.watch(periodCalculatorProvider).monthPeriodFor(ref.watch(todayProvider)),
);

class ReportData {
  const ReportData({
    required this.period,
    required this.current,
    required this.previous,
    required this.items,
    required this.stats,
    required this.byTag,
    required this.byAccount,
    required this.cashFlow,
  });

  final Period period;
  final PeriodTotals current;
  final PeriodTotals previous;
  final List<BreakdownItem> items;
  final ReportStats stats;
  final List<BreakdownItem> byTag;
  final List<BreakdownItem> byAccount;

  /// Last 6 periods (oldest first): period, income, expense.
  final List<(Period, int, int)> cashFlow;
}

/// Report aggregates for the selected period and type.
final reportDataProvider = FutureProvider<ReportData>((ref) async {
  ref.watch(txTickProvider);
  final period = ref.watch(effectiveReportPeriodProvider);
  final type = ref.watch(reportTypeProvider);
  final base = ref.watch(prefsProvider).baseCurrency;
  final fx = ref.watch(fxProvider);
  final today = ref.watch(todayProvider);
  final cats = ref.watch(categoriesMapProvider);
  final summary = ref.watch(summaryServiceProvider);
  final txs = ref.watch(transactionsRepoProvider);
  final cur = await summary.totals(period, base, fx, capAt: today);
  final prevP = period.previous();
  final prev = await summary.totals(prevP, base, fx, capAt: today);
  final byKey = type == 'expense' ? cur.expenseByKey : cur.incomeByKey;
  final prevKey = type == 'expense' ? prev.expenseByKey : prev.incomeByKey;
  final items = ReportService.rollUp(
    byKey,
    {for (final c in cats.values) c.id: c.parentId},
    previous: prevKey,
  );
  final days = ReportService.avgPerDay(cur.expense, period, today);
  final views = await txs.get(TxFilter(startMs: period.startMs, endExclusiveMs: period.endExclusiveMs, types: {type}));
  final biggest = views.isEmpty ? null : (views.toList()..sort((a, b) => b.tx.amount.compareTo(a.tx.amount))).first;
  final payees = <String?, int>{};
  for (final v in views) {
    final p = v.tx.payee;
    if (p != null && p.isNotEmpty) payees[p] = (payees[p] ?? 0) + v.tx.amount;
  }
  final counts = <String?, int>{};
  for (final v in views) {
    counts[v.tx.categoryId] = (counts[v.tx.categoryId] ?? 0) + 1;
  }
  final stats = ReportStats(
    income: cur.income,
    expense: cur.expense,
    savingsRatePct: cur.income > 0 ? (((cur.income - cur.expense) * 100) / cur.income).round() : null,
    avgPerDay: days,
    transactionCount: cur.expenseCount + cur.incomeCount,
    biggestExpenseTxId: biggest?.tx.id,
    biggestExpense: biggest?.tx.amount ?? 0,
    mostFrequentCategoryId: ReportService.argMax(counts),
    topPayee: ReportService.argMax(payees),
  );
  final tagTotals = await summary.totals(period, base, fx, key: AggKey.tag, capAt: today);
  final accTotals = await summary.totals(period, base, fx, key: AggKey.account, capAt: today);
  final cashFlow = <(Period, int, int)>[];
  var p = period;
  for (var i = 0; i < 6; i++) {
    final t = i == 0 ? cur : await summary.totals(p, base, fx, capAt: today);
    cashFlow.insert(0, (p, t.income, t.expense));
    p = p.previous();
  }
  return ReportData(
    period: period,
    current: cur,
    previous: prev,
    items: items,
    stats: stats,
    byTag: ReportService.flat(type == 'expense' ? tagTotals.expenseByKey : tagTotals.incomeByKey),
    byAccount: ReportService.flat(type == 'expense' ? accTotals.expenseByKey : accTotals.incomeByKey),
    cashFlow: cashFlow,
  );
});
