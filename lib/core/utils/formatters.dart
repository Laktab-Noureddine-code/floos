import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/time/period.dart';
import 'package:intl/intl.dart';

/// French date/period formatting helpers (intl `DateFormat`).
abstract final class Fmt {
  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// "Lundi 12 janvier 2026".
  static String longDay(LocalDay d) => _cap(DateFormat('EEEE d MMMM y', appLocaleName).format(d.toDateTime()));

  /// "12 janv. 2026".
  static String mediumDay(LocalDay d) => DateFormat('d MMM y', appLocaleName).format(d.toDateTime());

  /// "12 janv.".
  static String shortDay(LocalDay d) => DateFormat('d MMM', appLocaleName).format(d.toDateTime());

  /// "Janvier 2026".
  static String monthYear(LocalDay d) => _cap(DateFormat('MMMM y', appLocaleName).format(d.toDateTime()));

  /// "janv." for chart axes.
  static String monthShort(LocalDay d) => DateFormat('MMM', appLocaleName).format(d.toDateTime());

  /// "Juin 2027".
  static String monthYearShort(LocalDay d) => _cap(DateFormat('MMM y', appLocaleName).format(d.toDateTime()));

  /// "lundi".
  static String weekday(LocalDay d) => DateFormat('EEEE', appLocaleName).format(d.toDateTime());

  static String time(int minutes) => '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

  static String dateTime(DateTime dt) => DateFormat('d MMM y, HH:mm', appLocaleName).format(dt);

  /// Relative label: Aujourd'hui / Hier / Demain / date.
  static String relativeDay(AppLocalizations l, LocalDay d, LocalDay today) {
    if (d == today) return l.today;
    if (d == today.addDays(-1)) return l.yesterday;
    if (d == today.addDays(1)) return l.tomorrow;
    return mediumDay(d);
  }

  /// Label for a period: a calendar month shows "Janvier 2026"; a custom
  /// month shows "25 déc. – 24 janv."; weeks/custom show ranges.
  static String period(Period p) {
    switch (p.kind) {
      case PeriodKind.month when p.start.day == 1:
        return monthYear(p.start);
      case PeriodKind.year:
        return '${p.start.year}';
      case PeriodKind.month:
      case PeriodKind.week:
      case PeriodKind.custom:
        final sameYear = p.start.year == p.end.year;
        return sameYear
            ? '${shortDay(p.start)} – ${shortDay(p.end)}'
            : '${mediumDay(p.start)} – ${mediumDay(p.end)}';
    }
  }
}
