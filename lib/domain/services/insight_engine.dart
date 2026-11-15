import 'package:floos/core/money/money.dart';

/// Insight kinds in priority order (APP_PROMPT §5.9).
enum InsightKind {
  budgetOver,
  budgetWarning,
  goalBehind,
  upcomingBill,
  categoryUp,
  unusualTransaction,
  savingsRate,
  noRecentLogs,
  backupOverdue,
}

/// A ranked, tappable, dismissible insight. UI renders text from [kind] and
/// [params] through l10n.
class Insight {
  const Insight({
    required this.id,
    required this.kind,
    required this.priority,
    required this.route,
    this.params = const {},
  });

  /// Stable id for dismissal, e.g. `budgetOver:<budgetId>`.
  final String id;
  final InsightKind kind;

  /// Higher = more important.
  final int priority;
  final String route;
  final Map<String, Object> params;
}

class BudgetInsightInput {
  const BudgetInsightInput({
    required this.id,
    required this.name,
    required this.percent,
    required this.spent,
    required this.available,
    required this.perDay,
  });
  final String id;
  final String name;
  final int percent;
  final int spent;
  final int available;
  final int perDay;
}

class GoalInsightInput {
  const GoalInsightInput({required this.id, required this.name, required this.neededPerMonth});
  final String id;
  final String name;
  final int neededPerMonth;
}

class BillInsightInput {
  const BillInsightInput({
    required this.ruleId,
    required this.name,
    required this.amount,
    required this.currency,
    required this.daysUntil,
  });
  final String ruleId;
  final String name;
  final int amount;
  final String currency;
  final int daysUntil;
}

class CategoryTrendInput {
  const CategoryTrendInput({
    required this.categoryId,
    required this.name,
    required this.current,
    required this.previous,
  });
  final String categoryId;
  final String name;
  final int current;
  final int previous;
}

class UnusualTxInput {
  const UnusualTxInput({
    required this.txId,
    required this.categoryName,
    required this.amount,
    required this.currency,
    required this.median,
  });
  final String txId;
  final String categoryName;
  final int amount;
  final String currency;
  final int median;
}

/// Everything the engine needs, pre-aggregated by repositories.
class InsightInputs {
  const InsightInputs({
    this.budgets = const [],
    this.goalsBehind = const [],
    this.bills = const [],
    this.categoryTrends = const [],
    this.unusual = const [],
    this.income = 0,
    this.expense = 0,
    this.daysSinceLastTx,
    this.daysSinceBackup,
    this.hasData = false,
    this.dismissed = const {},
  });

  final List<BudgetInsightInput> budgets;
  final List<GoalInsightInput> goalsBehind;
  final List<BillInsightInput> bills;
  final List<CategoryTrendInput> categoryTrends;
  final List<UnusualTxInput> unusual;
  final int income;
  final int expense;
  final int? daysSinceLastTx;

  /// null = never backed up.
  final int? daysSinceBackup;
  final bool hasData;

  /// Insight ids dismissed for the current period.
  final Set<String> dismissed;
}

/// Deterministic local insights ranked by priority (APP_PROMPT §5.9).
abstract final class InsightEngine {
  static const warningPct = 80;
  static const trendPct = 20;
  static const unusualFactor = 3;
  static const billWindowDays = 3;
  static const noLogDays = 3;
  static const backupDays = 30;

  static List<Insight> compute(InsightInputs i) {
    final out = <Insight>[];
    for (final b in i.budgets) {
      if (b.percent > 100) {
        out.add(Insight(
          id: 'budgetOver:${b.id}',
          kind: InsightKind.budgetOver,
          priority: 1000 + b.percent,
          route: '/budgets/${b.id}',
          params: {'name': b.name, 'over': b.spent - b.available, 'percent': b.percent},
        ));
      } else if (b.percent >= warningPct) {
        out.add(Insight(
          id: 'budgetWarning:${b.id}',
          kind: InsightKind.budgetWarning,
          priority: 900 + b.percent,
          route: '/budgets/${b.id}',
          params: {'name': b.name, 'percent': b.percent, 'perDay': b.perDay},
        ));
      }
    }
    for (final g in i.goalsBehind) {
      out.add(Insight(
        id: 'goalBehind:${g.id}',
        kind: InsightKind.goalBehind,
        priority: 800,
        route: '/goals/${g.id}',
        params: {'name': g.name, 'needed': g.neededPerMonth},
      ));
    }
    for (final b in i.bills) {
      if (b.daysUntil >= 0 && b.daysUntil <= billWindowDays) {
        out.add(Insight(
          id: 'bill:${b.ruleId}',
          kind: InsightKind.upcomingBill,
          priority: 700 + (billWindowDays - b.daysUntil),
          route: '/recurring/${b.ruleId}/edit',
          params: {'name': b.name, 'amount': b.amount, 'currency': b.currency, 'days': b.daysUntil},
        ));
      }
    }
    for (final c in i.categoryTrends) {
      if (c.previous <= 0) continue;
      final pct = divideHalfEvenInt((c.current - c.previous) * 100, c.previous);
      if (pct >= trendPct) {
        out.add(Insight(
          id: 'categoryUp:${c.categoryId}',
          kind: InsightKind.categoryUp,
          priority: 600 + pct.clamp(0, 99),
          route: '/report/category/${c.categoryId}',
          params: {'name': c.name, 'percent': pct},
        ));
      }
    }
    for (final u in i.unusual) {
      if (u.median > 0 && u.amount > u.median * unusualFactor) {
        out.add(Insight(
          id: 'unusual:${u.txId}',
          kind: InsightKind.unusualTransaction,
          priority: 500,
          route: '/transactions?id=${u.txId}',
          params: {'name': u.categoryName, 'amount': u.amount, 'currency': u.currency},
        ));
      }
    }
    if (i.income > 0) {
      final rate = divideHalfEvenInt((i.income - i.expense) * 100, i.income);
      if (rate > 0) {
        out.add(Insight(
          id: 'savingsRate',
          kind: InsightKind.savingsRate,
          priority: 400,
          route: '/report',
          params: {'percent': rate},
        ));
      }
    }
    if (i.hasData && (i.daysSinceLastTx ?? 0) >= noLogDays) {
      out.add(Insight(
        id: 'noRecentLogs',
        kind: InsightKind.noRecentLogs,
        priority: 300,
        route: '/add',
        params: {'days': i.daysSinceLastTx ?? 0},
      ));
    }
    if (i.hasData && (i.daysSinceBackup == null || i.daysSinceBackup! >= backupDays)) {
      out.add(const Insight(
        id: 'backupOverdue',
        kind: InsightKind.backupOverdue,
        priority: 350,
        route: '/settings/backup',
      ));
    }
    out
      ..removeWhere((x) => i.dismissed.contains(x.id))
      ..sort((a, b) => b.priority.compareTo(a.priority));
    return out;
  }

  /// Median of a sorted-or-unsorted list (integer, half-even).
  static int median(List<int> values) {
    if (values.isEmpty) return 0;
    final s = [...values]..sort();
    final mid = s.length ~/ 2;
    return s.length.isOdd ? s[mid] : divideHalfEvenInt(s[mid - 1] + s[mid], 2);
  }
}
