import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/time/period.dart';

/// One slice of a breakdown (category, account, tag or payee).
class BreakdownItem {
  const BreakdownItem({
    required this.key,
    required this.total,
    this.previous = 0,
    this.count = 0,
    this.children = const [],
  });

  final String key;
  final int total;
  final int previous;
  final int count;
  final List<BreakdownItem> children;

  /// Share of [grandTotal] in permille.
  int sharePermille(int grandTotal) =>
      grandTotal <= 0 ? 0 : (total * 1000 + grandTotal ~/ 2) ~/ grandTotal;
}

/// Stats block for the Report tab (APP_PROMPT §5.10).
class ReportStats {
  const ReportStats({
    required this.income,
    required this.expense,
    required this.savingsRatePct,
    required this.avgPerDay,
    required this.transactionCount,
    this.biggestExpenseTxId,
    this.biggestExpense = 0,
    this.mostFrequentCategoryId,
    this.topPayee,
  });

  final int income;
  final int expense;
  final int? savingsRatePct;
  final int avgPerDay;
  final int transactionCount;
  final String? biggestExpenseTxId;
  final int biggestExpense;
  final String? mostFrequentCategoryId;
  final String? topPayee;
}

/// Pure report helpers; heavy aggregation happens in SQL.
abstract final class ReportService {
  /// Rolls category totals up to their parent (APP_PROMPT §13.14).
  /// [parentOf] maps child id → parent id.
  static List<BreakdownItem> rollUp(
    Map<String?, int> totals,
    Map<String, String?> parentOf, {
    Map<String?, int> previous = const {},
    Map<String?, int> counts = const {},
  }) {
    final childrenByParent = <String, List<BreakdownItem>>{};
    final own = <String, int>{};
    final prevRoll = <String, int>{};
    final countRoll = <String, int>{};
    for (final e in totals.entries) {
      final id = e.key;
      if (id == null) continue;
      final parent = parentOf[id];
      final root = parent ?? id;
      if (parent != null) {
        childrenByParent.putIfAbsent(root, () => []).add(
          BreakdownItem(key: id, total: e.value, previous: previous[id] ?? 0, count: counts[id] ?? 0),
        );
      } else {
        own[root] = (own[root] ?? 0) + e.value;
      }
    }
    for (final e in previous.entries) {
      final id = e.key;
      if (id == null) continue;
      final root = parentOf[id] ?? id;
      prevRoll[root] = (prevRoll[root] ?? 0) + e.value;
    }
    for (final e in counts.entries) {
      final id = e.key;
      if (id == null) continue;
      final root = parentOf[id] ?? id;
      countRoll[root] = (countRoll[root] ?? 0) + e.value;
    }
    final roots = {...own.keys, ...childrenByParent.keys};
    final items = [
      for (final r in roots)
        BreakdownItem(
          key: r,
          total: (own[r] ?? 0) + (childrenByParent[r]?.fold<int>(0, (a, c) => a + c.total) ?? 0),
          previous: prevRoll[r] ?? 0,
          count: countRoll[r] ?? 0,
          children: [
            if (childrenByParent.containsKey(r) && (own[r] ?? 0) > 0)
              BreakdownItem(key: r, total: own[r]!),
            ...?childrenByParent[r],
          ]..sort((a, b) => b.total.compareTo(a.total)),
        ),
    ]..sort((a, b) => b.total.compareTo(a.total));
    return items.where((i) => i.total > 0).toList();
  }

  /// Sorted breakdown from a flat map (accounts, tags, payees).
  static List<BreakdownItem> flat(Map<String?, int> totals, {Map<String?, int> counts = const {}}) => [
    for (final e in totals.entries)
      if (e.key != null && e.value > 0)
        BreakdownItem(key: e.key!, total: e.value, count: counts[e.key] ?? 0),
  ]..sort((a, b) => b.total.compareTo(a.total));

  /// Buckets daily sums into the given periods (e.g. 12 custom months).
  static List<int> bucket(Map<LocalDay, int> daily, List<Period> periods) => [
    for (final p in periods)
      daily.entries.where((e) => p.contains(e.key)).fold<int>(0, (a, e) => a + e.value),
  ];

  /// Daily series over a period (0 for empty days).
  static List<int> dailySeries(Period p, Map<LocalDay, int> daily) => [
    for (final d in p.days) daily[d] ?? 0,
  ];

  /// Average daily spend over elapsed days.
  static int avgPerDay(int total, Period p, LocalDay today) {
    final days = p.daysElapsed(today);
    return days <= 0 ? 0 : (total + days ~/ 2) ~/ days;
  }

  /// Key with the highest value, or null.
  static String? argMax(Map<String?, int> m) {
    String? best;
    var bestV = 0;
    for (final e in m.entries) {
      if (e.key != null && e.value > bestV) {
        best = e.key;
        bestV = e.value;
      }
    }
    return best;
  }
}
