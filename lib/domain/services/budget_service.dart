import 'dart:convert';

import 'package:floos/core/money/money.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/time/period.dart';

/// Budget health level (APP_PROMPT §5.5).
enum BudgetLevel { ok, warning, over }

/// Budget definition (pure input).
class BudgetDef {
  const BudgetDef({
    required this.id,
    required this.amount,
    required this.period,
    required this.createdDay,
    this.rollover = false,
    this.customStart,
    this.customEnd,
    this.thresholds = const [80, 100],
  });

  final String id;
  final int amount;

  /// `weekly` | `monthly` | `yearly` | `custom`.
  final String period;
  final LocalDay createdDay;
  final bool rollover;
  final LocalDay? customStart;
  final LocalDay? customEnd;
  final List<int> thresholds;

  static List<int> parseThresholds(String json) {
    try {
      final list = (jsonDecode(json) as List).map((e) => (e as num).toInt()).toList()..sort();
      return list.where((e) => e > 0 && e <= 200).toSet().toList();
    } on Object {
      return const [80, 100];
    }
  }
}

/// Computed budget status for one period.
class BudgetStatus {
  const BudgetStatus({
    required this.period,
    required this.available,
    required this.spent,
    required this.rolloverIn,
    required this.level,
    required this.progressPermille,
    required this.remaining,
    required this.remainingPerDay,
    required this.projected,
    required this.daysLeft,
  });

  final Period period;
  final int available;
  final int spent;
  final int rolloverIn;
  final BudgetLevel level;

  /// spent / available × 1000 (integer, can exceed 1000).
  final int progressPermille;
  final int remaining;
  final int remainingPerDay;
  final int projected;
  final int daysLeft;

  int get percent => (progressPermille / 10).round();
  bool get projectedOver => projected > available;
  int get projectedOverBy => projected - available;
}

/// Budget math (APP_PROMPT §5.5): rollover, levels, per-day, projection.
abstract final class BudgetService {
  static const warningPermille = 700;
  static const overPermille = 1000;
  static const maxRolloverPeriods = 12;

  /// Period of [def] containing [day].
  static Period periodFor(BudgetDef def, LocalDay day, {int monthStartDay = 1, int weekStartDay = 1}) =>
      switch (def.period) {
        'weekly' => Period.week(day, weekStartDay),
        'yearly' => Period.year(day),
        'custom' => Period.custom(def.customStart ?? day, def.customEnd ?? day),
        _ => Period.month(day, monthStartDay),
      };

  static BudgetLevel levelFor(int permille) {
    if (permille > overPermille) return BudgetLevel.over;
    if (permille >= warningPermille) return BudgetLevel.warning;
    return BudgetLevel.ok;
  }

  /// Evaluates [def] for the period containing [today].
  /// [spentIn] returns spent (base currency) within a period, capped at today.
  static BudgetStatus evaluate(
    BudgetDef def,
    LocalDay today,
    int Function(Period) spentIn, {
    LocalDay? at,
    int monthStartDay = 1,
    int weekStartDay = 1,
  }) {
    final period = periodFor(def, at ?? today, monthStartDay: monthStartDay, weekStartDay: weekStartDay);
    final rolloverIn = def.rollover && def.period != 'custom'
        ? _rollover(def, period, spentIn)
        : 0;
    final available = def.amount + rolloverIn;
    final spent = spentIn(period);
    final permille = available <= 0
        ? (spent > 0 ? overPermille + 1 : 0)
        : divideHalfEvenInt(spent * 1000, available);
    final daysLeft = period.daysLeft(today);
    final remaining = available - spent;
    final perDay = daysLeft == 0 || remaining <= 0 ? 0 : remaining ~/ daysLeft;
    final elapsed = period.daysElapsed(today);
    final projected = elapsed == 0
        ? spent
        : divideHalfEvenInt(spent * period.daysTotal, elapsed);
    return BudgetStatus(
      period: period,
      available: available,
      spent: spent,
      rolloverIn: rolloverIn,
      level: levelFor(permille),
      progressPermille: permille,
      remaining: remaining,
      remainingPerDay: perDay,
      projected: projected,
      daysLeft: daysLeft,
    );
  }

  /// Rollover into [current] = previous (available − spent), recursive from
  /// the budget's creation, capped at 12 periods back. Can be negative.
  static int _rollover(BudgetDef def, Period current, int Function(Period) spentIn) {
    final chain = <Period>[];
    var p = current.previous();
    while (chain.length < maxRolloverPeriods && p.end >= def.createdDay) {
      chain.insert(0, p);
      p = p.previous();
    }
    var carry = 0;
    for (final period in chain) {
      final available = def.amount + carry;
      carry = available - spentIn(period);
    }
    return carry;
  }

  /// Thresholds newly crossed by [status] (percent values), given the
  /// thresholds already logged for this period.
  static List<int> crossedThresholds(BudgetDef def, BudgetStatus status, Set<int> alreadyLogged) =>
      [
        for (final t in def.thresholds)
          if (status.progressPermille >= t * 10 && !alreadyLogged.contains(t)) t,
      ];

  /// Cumulative daily spending for charts (base currency), from [daily].
  static List<int> cumulative(Period period, Map<LocalDay, int> daily, LocalDay today) {
    var acc = 0;
    final out = <int>[];
    for (final d in period.days) {
      if (d > today) break;
      acc += daily[d] ?? 0;
      out.add(acc);
    }
    return out;
  }
}
