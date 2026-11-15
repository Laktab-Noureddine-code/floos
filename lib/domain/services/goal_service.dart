import 'package:floos/core/money/money.dart';
import 'package:floos/core/time/local_day.dart';

/// Goal tracking state shown in the status banner (design.md §4.3).
enum GoalState { onTrack, behind, completed, noDeadline }

/// A goal contribution (negative = withdrawal).
class GoalContributionInput {
  const GoalContributionInput(this.amount, this.day);
  final int amount;
  final LocalDay day;
}

/// Pure goal input.
class GoalInput {
  const GoalInput({
    required this.target,
    required this.start,
    this.deadline,
    this.contributions = const [],
    this.linkedBalance,
    this.manuallyCompleted = false,
  });

  final int target;
  final LocalDay start;
  final LocalDay? deadline;
  final List<GoalContributionInput> contributions;

  /// Linked savings account balance (base currency) when in linked mode.
  final int? linkedBalance;
  final bool manuallyCompleted;
}

/// Computed goal status (APP_PROMPT §5.6).
class GoalStatus {
  const GoalStatus({
    required this.saved,
    required this.remaining,
    required this.progressPermille,
    required this.state,
    this.expectedNow,
    this.behindPct,
    this.neededPerMonth,
    this.avgMonthly,
    this.estimatedCompletion,
  });

  final int saved;
  final int remaining;

  /// saved / target × 1000 (not clamped; clamp for the bar only).
  final int progressPermille;
  final GoalState state;
  final int? expectedNow;
  final int? behindPct;
  final int? neededPerMonth;
  final int? avgMonthly;
  final LocalDay? estimatedCompletion;

  double get barFraction => (progressPermille.clamp(0, 1000)) / 1000;
  int get percent => divideHalfEvenInt(progressPermille, 10);
  bool get isCompleted => state == GoalState.completed;
}

/// Goal math: saved, progress, on-track/behind, needed per month.
abstract final class GoalService {
  static const milestones = [25, 50, 75, 100];

  static GoalStatus evaluate(GoalInput g, LocalDay today) {
    final contributed = g.contributions.fold<int>(0, (a, c) => a + c.amount);
    final saved = contributed + (g.linkedBalance ?? 0);
    final remaining = saved >= g.target ? 0 : g.target - saved;
    final permille = g.target <= 0 ? 0 : divideHalfEvenInt(saved * 1000, g.target);
    if (saved >= g.target || g.manuallyCompleted) {
      return GoalStatus(
        saved: saved,
        remaining: remaining,
        progressPermille: permille,
        state: GoalState.completed,
      );
    }
    final deadline = g.deadline;
    if (deadline == null) {
      final months = _monthsBetween(g.start, today) + 1;
      final avg = divideHalfEvenInt(contributed, months);
      LocalDay? eta;
      if (avg > 0) {
        final monthsNeeded = (remaining + avg - 1) ~/ avg;
        eta = today.addMonths(monthsNeeded);
      }
      return GoalStatus(
        saved: saved,
        remaining: remaining,
        progressPermille: permille,
        state: GoalState.noDeadline,
        avgMonthly: avg,
        estimatedCompletion: eta,
      );
    }
    final totalDays = g.start.daysUntil(deadline).clamp(1, 1 << 30);
    final elapsed = g.start.daysUntil(today).clamp(0, totalDays);
    final expected = divideHalfEvenInt(g.target * elapsed, totalDays);
    final onTrack = saved * 10 >= expected * 9;
    final behindPct = onTrack || expected <= 0
        ? null
        : 100 - divideHalfEvenInt(saved * 100, expected);
    final monthsLeft = monthsLeftUntil(today, deadline);
    final needed = (remaining + monthsLeft - 1) ~/ monthsLeft;
    return GoalStatus(
      saved: saved,
      remaining: remaining,
      progressPermille: permille,
      state: onTrack ? GoalState.onTrack : GoalState.behind,
      expectedNow: expected,
      behindPct: behindPct,
      neededPerMonth: needed,
    );
  }

  /// Whole months from [today] to [deadline], at least 1.
  static int monthsLeftUntil(LocalDay today, LocalDay deadline) {
    final m = _monthsBetween(today, deadline);
    return m < 1 ? 1 : m;
  }

  static int _monthsBetween(LocalDay a, LocalDay b) {
    var m = (b.year - a.year) * 12 + (b.month - a.month);
    if (b.day < a.day) m -= 1;
    return m < 0 ? 0 : m;
  }

  /// Milestones (25/50/75/100) reached but not yet notified.
  static List<int> newMilestones(int progressPermille, Set<int> notified) => [
    for (final m in milestones)
      if (progressPermille >= m * 10 && !notified.contains(m)) m,
  ];

  /// Cumulative saved series by contribution day (for the detail chart).
  static List<(LocalDay, int)> cumulative(List<GoalContributionInput> contributions) {
    final sorted = [...contributions]..sort((a, b) => a.day.compareTo(b.day));
    var acc = 0;
    return [
      for (final c in sorted) (c.day, acc += c.amount),
    ];
  }
}
