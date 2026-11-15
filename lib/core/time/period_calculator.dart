import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/time/period.dart';

export 'package:floos/core/time/local_day.dart';
export 'package:floos/core/time/period.dart';

/// Period helpers bound to the user's settings (APP_PROMPT §5.2).
class PeriodCalculator {
  const PeriodCalculator({this.monthStartDay = 1, this.weekStartDay = 1});

  final int monthStartDay;
  final int weekStartDay;

  /// Custom month containing [date]: if `date.day >= startDay` it runs from
  /// `(y, m, startDay)` to `(y, m+1, startDay) − 1 day`, else it starts in the
  /// previous month.
  Period monthPeriodFor(LocalDay date) => Period.month(date, monthStartDay);

  Period weekPeriodFor(LocalDay date) => Period.week(date, weekStartDay);

  Period yearPeriodFor(LocalDay date) => Period.year(date);

  Period periodFor(PeriodKind kind, LocalDay date) => Period.of(
    kind,
    date,
    monthStartDay: monthStartDay,
    weekStartDay: weekStartDay,
  );

  /// The last [count] custom months ending with the one containing [date],
  /// oldest first.
  List<Period> lastMonths(LocalDay date, int count) {
    final out = <Period>[monthPeriodFor(date)];
    while (out.length < count) {
      out.insert(0, out.first.previous());
    }
    return out;
  }
}
