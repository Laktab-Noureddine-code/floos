import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/time/period.dart';
import 'package:floos/data/repositories/accounts_repository.dart';
import 'package:floos/data/repositories/transactions_repository.dart';
import 'package:floos/domain/services/balance_service.dart';
import 'package:floos/domain/services/fx_service.dart';
import 'package:floos/domain/services/totals_service.dart';

/// Converted income/expense for a period (base currency).
class PeriodTotals {
  const PeriodTotals({
    required this.income,
    required this.expense,
    required this.incomeByKey,
    required this.expenseByKey,
    required this.expenseByDay,
    required this.incomeByDay,
    required this.expenseCount,
    required this.incomeCount,
    this.missingRates = const {},
  });

  final int income;
  final int expense;
  final Map<String?, int> incomeByKey;
  final Map<String?, int> expenseByKey;
  final Map<LocalDay, int> expenseByDay;
  final Map<LocalDay, int> incomeByDay;
  final int expenseCount;
  final int incomeCount;
  final Set<String> missingRates;

  int get net => income - expense;
}

/// Shared aggregate computations used by Home, Report, widgets and alerts.
class SummaryService {
  const SummaryService(this.transactions, this.accounts);

  final TransactionsRepository transactions;
  final AccountsRepository accounts;

  static List<DaySum> toDaySums(List<AggRow> rows) => [
    for (final r in rows)
      DaySum(key: r.key, currency: r.currency, day: LocalDay.fromStorage(r.date), sum: r.sum, count: r.count),
  ];

  /// Income/expense totals for [period], grouped by [key], capped at [capAt]
  /// (future-dated items excluded, APP_PROMPT §13.2).
  Future<PeriodTotals> totals(
    Period period,
    String base,
    FxService fx, {
    AggKey key = AggKey.category,
    LocalDay? capAt,
  }) async {
    final exp = TotalsService.convert(
      toDaySums(await transactions.aggregate(type: 'expense', period: period, key: key, capAt: capAt)),
      base,
      fx,
    );
    final inc = TotalsService.convert(
      toDaySums(await transactions.aggregate(type: 'income', period: period, key: key, capAt: capAt)),
      base,
      fx,
    );
    return PeriodTotals(
      income: inc.total,
      expense: exp.total,
      incomeByKey: inc.byKey,
      expenseByKey: exp.byKey,
      expenseByDay: exp.byDay,
      incomeByDay: inc.byDay,
      expenseCount: exp.count,
      incomeCount: inc.count,
      missingRates: {...exp.missingRates, ...inc.missingRates},
    );
  }

  /// Net worth (base currency) as of the end of [day].
  Future<NetWorth> netWorth(LocalDay day, String base, FxService fx) async {
    final list = await accounts.withBalances(day);
    return BalanceService.netWorth(list.map((a) => a.toInput()), base, fx, day);
  }
}
