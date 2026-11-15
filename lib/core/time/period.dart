import 'package:floos/core/time/local_day.dart';
import 'package:meta/meta.dart';

/// Kind of reporting/budget period.
enum PeriodKind { week, month, year, custom }

/// An inclusive range of local days with navigation helpers (APP_PROMPT §5.2).
@immutable
class Period {
  const Period({
    required this.kind,
    required this.start,
    required this.end,
    this.monthStartDay = 1,
    this.weekStartDay = 1,
  }) : assert(start <= end, 'start must be <= end');

  /// Custom-month period containing [date] (startDay clamped to 1–28).
  factory Period.month(LocalDay date, int startDay) {
    final s = clampStartDay(startDay);
    final LocalDay start;
    if (date.day >= s) {
      start = LocalDay(date.year, date.month, s);
    } else {
      start = LocalDay(date.year, date.month - 1, s);
    }
    final end = LocalDay(start.year, start.month + 1, s).addDays(-1);
    return Period(kind: PeriodKind.month, start: start, end: end, monthStartDay: s);
  }

  /// Week containing [date]; [weekStartDay] is ISO weekday (1 Mon, 6 Sat, 7 Sun).
  factory Period.week(LocalDay date, int weekStartDay) {
    final ws = weekStartDay.clamp(1, 7);
    final diff = (date.weekday - ws + 7) % 7;
    final start = date.addDays(-diff);
    return Period(
      kind: PeriodKind.week,
      start: start,
      end: start.addDays(6),
      weekStartDay: ws,
    );
  }

  /// Calendar year containing [date].
  factory Period.year(LocalDay date) => Period(
    kind: PeriodKind.year,
    start: LocalDay(date.year, 1, 1),
    end: LocalDay(date.year, 12, 31),
  );

  factory Period.custom(LocalDay start, LocalDay end) =>
      Period(kind: PeriodKind.custom, start: start, end: end);

  /// Builds the period of [kind] containing [date].
  factory Period.of(
    PeriodKind kind,
    LocalDay date, {
    int monthStartDay = 1,
    int weekStartDay = 1,
  }) => switch (kind) {
    PeriodKind.week => Period.week(date, weekStartDay),
    PeriodKind.month => Period.month(date, monthStartDay),
    PeriodKind.year => Period.year(date),
    PeriodKind.custom => Period.custom(date, date),
  };

  final PeriodKind kind;
  final LocalDay start;
  final LocalDay end;
  final int monthStartDay;
  final int weekStartDay;

  static int clampStartDay(int d) => d.clamp(1, 28);

  bool contains(LocalDay d) => d >= start && d <= end;

  /// Number of days in the period (inclusive).
  int get daysTotal => start.daysUntil(end) + 1;

  /// Days left including [today] (0 if the period is over).
  int daysLeft(LocalDay today) {
    if (today > end) return 0;
    if (today < start) return daysTotal;
    return today.daysUntil(end) + 1;
  }

  /// Days elapsed including [today] (clamped to 0…daysTotal).
  int daysElapsed(LocalDay today) {
    if (today < start) return 0;
    if (today > end) return daysTotal;
    return start.daysUntil(today) + 1;
  }

  Period previous() => switch (kind) {
    PeriodKind.week => Period.week(start.addDays(-1), weekStartDay),
    PeriodKind.month => Period.month(start.addDays(-1), monthStartDay),
    PeriodKind.year => Period.year(start.addDays(-1)),
    PeriodKind.custom => Period.custom(
      start.addDays(-daysTotal),
      start.addDays(-1),
    ),
  };

  Period next() => switch (kind) {
    PeriodKind.week => Period.week(end.addDays(1), weekStartDay),
    PeriodKind.month => Period.month(end.addDays(1), monthStartDay),
    PeriodKind.year => Period.year(end.addDays(1)),
    PeriodKind.custom => Period.custom(end.addDays(1), end.addDays(daysTotal)),
  };

  /// Same-length window in the previous period aligned day-to-day: from the
  /// previous period's start through day N (for "same point" comparisons).
  Period previousAligned(LocalDay today) {
    final prev = previous();
    final n = daysElapsed(today);
    final endDay = prev.start.addDays(n - 1);
    return Period.custom(prev.start, LocalDay.min(endDay, prev.end));
  }

  /// Stable key, e.g. `month:2026-01-25`.
  String get key => '${kind.name}:${start.toIso()}';

  /// Storage bounds: [startMs, endExclusiveMs).
  int get startMs => start.toStorage();
  int get endExclusiveMs => end.addDays(1).toStorage();

  /// Every day in the period.
  Iterable<LocalDay> get days sync* {
    for (var d = start; d <= end; d = d.addDays(1)) {
      yield d;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Period && other.kind == kind && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(kind, start, end);

  @override
  String toString() => 'Period(${kind.name} $start..$end)';
}
