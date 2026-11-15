import 'package:floos/core/time/local_day.dart';

/// Recurrence frequency.
enum Frequency { daily, weekly, monthly, yearly }

/// Pure schedule of a recurring rule (APP_PROMPT §4.10, §5.7).
class Schedule {
  const Schedule({
    required this.frequency,
    required this.start,
    this.interval = 1,
    this.byWeekday,
    this.byMonthDay,
    this.end,
    this.maxOccurrences,
  });

  final Frequency frequency;
  final LocalDay start;
  final int interval;

  /// ISO weekday 1–7 for weekly rules.
  final int? byWeekday;

  /// 1–31 for monthly/yearly rules, clamped to short months.
  final int? byMonthDay;
  final LocalDay? end;
  final int? maxOccurrences;

  int get _step => interval < 1 ? 1 : interval;
  int get _anchorDay => (byMonthDay ?? start.day).clamp(1, 31);

  /// The k-th occurrence candidate (k ≥ 0) before start-alignment.
  LocalDay _candidate(int k) {
    switch (frequency) {
      case Frequency.daily:
        return start.addDays(k * _step);
      case Frequency.weekly:
        final wd = byWeekday ?? start.weekday;
        final first = start.addDays((wd - start.weekday + 7) % 7);
        return first.addDays(7 * _step * k);
      case Frequency.monthly:
        return _monthDay(start.year * 12 + start.month - 1 + k * _step);
      case Frequency.yearly:
        return _monthDay(start.year * 12 + start.month - 1 + 12 * _step * k);
    }
  }

  LocalDay _monthDay(int monthIndex) {
    final y = monthIndex ~/ 12;
    final m = monthIndex % 12 + 1;
    final dim = LocalDay.daysInMonth(y, m);
    return LocalDay(y, m, _anchorDay > dim ? dim : _anchorDay);
  }

  /// First occurrence on or after the start date.
  LocalDay first() => firstOnOrAfter(start);

  /// Smallest occurrence ≥ [day].
  LocalDay firstOnOrAfter(LocalDay day) {
    var k = _estimate(day);
    while (k > 0 && !(_candidate(k - 1) < day)) {
      k--;
    }
    while (_candidate(k) < day || _candidate(k) < start) {
      k++;
    }
    return _candidate(k);
  }

  /// Next occurrence strictly after [day].
  LocalDay nextAfter(LocalDay day) => firstOnOrAfter(day.addDays(1));

  int _estimate(LocalDay day) {
    if (day <= start) return 0;
    final k = switch (frequency) {
      Frequency.daily => start.daysUntil(day) ~/ _step,
      Frequency.weekly => start.daysUntil(day) ~/ (7 * _step),
      Frequency.monthly => ((day.year - start.year) * 12 + day.month - start.month) ~/ _step,
      Frequency.yearly => (day.year - start.year) ~/ _step,
    };
    return k < 0 ? 0 : k;
  }

  bool isWithinEnd(LocalDay d, int alreadyGenerated) {
    if (end != null && d > end!) return false;
    if (maxOccurrences != null && alreadyGenerated >= maxOccurrences!) return false;
    return true;
  }
}

/// Result of a catch-up run for one rule.
class DueResult {
  const DueResult({
    required this.days,
    required this.nextDue,
    required this.deactivate,
  });

  /// Occurrence days to materialize (≤ today), oldest first.
  final List<LocalDay> days;

  /// New next due date after these occurrences.
  final LocalDay nextDue;

  /// True when the rule reached its end date / max occurrences.
  final bool deactivate;
}

/// Recurring schedule math. The repository-backed runner lives in
/// `RecurringRepository.runDue` and is idempotent thanks to the unique
/// `(recurring_rule_id, date)` index.
abstract final class RecurringEngine {
  /// Safety cap on occurrences generated per rule per run.
  static const maxCatchUp = 1000;

  /// Occurrences with date ≤ [today] starting at [nextDue].
  static DueResult due(Schedule s, LocalDay nextDue, int generated, LocalDay today) {
    final days = <LocalDay>[];
    var d = nextDue;
    var count = generated;
    while (d <= today && days.length < maxCatchUp) {
      if (!s.isWithinEnd(d, count)) {
        return DueResult(days: days, nextDue: d, deactivate: true);
      }
      days.add(d);
      count++;
      d = s.nextAfter(d);
    }
    final ended = !s.isWithinEnd(d, count);
    return DueResult(days: days, nextDue: d, deactivate: ended);
  }

  /// Occurrences between [from] and [to] inclusive (for "Upcoming" lists).
  static List<LocalDay> between(Schedule s, LocalDay nextDue, int generated, LocalDay from, LocalDay to) {
    final out = <LocalDay>[];
    var d = nextDue;
    var count = generated;
    while (d <= to && out.length < 400) {
      if (!s.isWithinEnd(d, count)) break;
      if (d >= from) out.add(d);
      count++;
      d = s.nextAfter(d);
    }
    return out;
  }

  /// Reminder day for an occurrence, or null when reminders are off.
  static LocalDay? reminderDay(LocalDay due, int? remindDaysBefore) =>
      remindDaysBefore == null ? null : due.addDays(-remindDaysBefore.clamp(0, 7));
}
