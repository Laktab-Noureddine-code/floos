import 'package:floos/core/money/money.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/domain/services/fx_service.dart';

/// A grouped sum in a source currency on a local day (from SQL aggregates).
class DaySum {
  const DaySum({
    required this.key,
    required this.currency,
    required this.day,
    required this.sum,
    this.count = 1,
  });

  final String? key;
  final String currency;
  final LocalDay day;
  final int sum;
  final int count;
}

/// Converted totals with any missing-rate currencies.
class ConvertedSums {
  const ConvertedSums(this.byKey, this.byDay, this.total, this.count, this.missingRates);

  final Map<String?, int> byKey;
  final Map<LocalDay, int> byDay;
  final int total;
  final int count;
  final Set<String> missingRates;
}

/// Income/expense totals in the base currency (APP_PROMPT §5.4).
///
/// Transfers are never income/expense; pending and excluded transactions are
/// already filtered out by the SQL aggregate.
abstract final class TotalsService {
  static ConvertedSums convert(Iterable<DaySum> rows, String base, FxService fx) {
    final byKey = <String?, int>{};
    final byDay = <LocalDay, int>{};
    var total = 0;
    var count = 0;
    final missing = <String>{};
    for (final r in rows) {
      final v = fx.convertMinor(r.sum, r.currency, base, r.day).valueOrNull;
      if (v == null) {
        missing.add(r.currency);
        continue;
      }
      byKey[r.key] = (byKey[r.key] ?? 0) + v;
      byDay[r.day] = (byDay[r.day] ?? 0) + v;
      total += v;
      count += r.count;
    }
    return ConvertedSums(byKey, byDay, total, count, missing);
  }

  /// Savings rate in whole percent ((income − expense) / income), or null.
  static int? savingsRatePct(int income, int expense) {
    if (income <= 0) return null;
    return divideHalfEvenInt((income - expense) * 100, income);
  }

  /// Percent change from [previous] to [current], or null when previous is 0.
  static int? changePct(int current, int previous) {
    if (previous == 0) return null;
    return divideHalfEvenInt((current - previous) * 100, previous.abs());
  }
}
