import 'package:meta/meta.dart';
/// A local calendar day (no time, no zone). DST-safe arithmetic uses calendar
/// fields, never fixed 24 h durations (Constitution III).
@immutable
class LocalDay implements Comparable<LocalDay> {
  /// Normalizes overflowing fields (e.g. month 13, day 0).
  factory LocalDay(int year, int month, int day) {
    final d = DateTime.utc(year, month, day);
    return LocalDay._(d.year, d.month, d.day);
  }

  const LocalDay._(this.year, this.month, this.day);

  factory LocalDay.fromDateTime(DateTime dt) {
    final l = dt.toLocal();
    return LocalDay._(l.year, l.month, l.day);
  }

  /// Decodes a stored value: UTC ms of local midnight. A day stored in another
  /// zone is mapped to the nearest local midnight (±14 h) so travel and DST
  /// never shift the calendar day.
  factory LocalDay.fromStorage(int utcMs) {
    final l = DateTime.fromMillisecondsSinceEpoch(utcMs);
    if (l.hour >= 12) {
      final next = DateTime(l.year, l.month, l.day + 1);
      return LocalDay._(next.year, next.month, next.day);
    }
    return LocalDay._(l.year, l.month, l.day);
  }

  /// Parses `yyyy-MM-dd`.
  static LocalDay? tryParse(String s) {
    final m = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(s.trim());
    if (m == null) return null;
    final y = int.parse(m[1]!);
    final mo = int.parse(m[2]!);
    final d = int.parse(m[3]!);
    if (mo < 1 || mo > 12 || d < 1 || d > daysInMonth(y, mo)) return null;
    return LocalDay(y, mo, d);
  }

  final int year;
  final int month;
  final int day;

  /// UTC ms of this day's local midnight (the storage format).
  int toStorage() => DateTime(year, month, day).millisecondsSinceEpoch;

  /// Local midnight as a [DateTime].
  DateTime toDateTime() => DateTime(year, month, day);

  DateTime at(int minutes) =>
      DateTime(year, month, day, minutes ~/ 60, minutes % 60);

  LocalDay addDays(int n) => LocalDay(year, month, day + n);

  /// Adds months, clamping the day to the target month's length.
  LocalDay addMonths(int n) {
    final total = year * 12 + (month - 1) + n;
    final y = total ~/ 12;
    final m = total % 12 + 1;
    final d = day > daysInMonth(y, m) ? daysInMonth(y, m) : day;
    return LocalDay._(y, m, d);
  }

  LocalDay addYears(int n) => addMonths(12 * n);

  /// ISO weekday: Monday = 1 … Sunday = 7.
  int get weekday => DateTime.utc(year, month, day).weekday;

  /// Days from this day to [other] (positive if [other] is later).
  int daysUntil(LocalDay other) =>
      DateTime.utc(other.year, other.month, other.day)
          .difference(DateTime.utc(year, month, day))
          .inDays;

  bool isBefore(LocalDay o) => compareTo(o) < 0;
  bool isAfter(LocalDay o) => compareTo(o) > 0;
  bool operator <(LocalDay o) => compareTo(o) < 0;
  bool operator >(LocalDay o) => compareTo(o) > 0;
  bool operator <=(LocalDay o) => compareTo(o) <= 0;
  bool operator >=(LocalDay o) => compareTo(o) >= 0;

  int get key => year * 10000 + month * 100 + day;

  @override
  int compareTo(LocalDay other) => key.compareTo(other.key);

  @override
  bool operator ==(Object other) => other is LocalDay && other.key == key;

  @override
  int get hashCode => key;

  /// `yyyy-MM-dd`.
  String toIso() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  @override
  String toString() => toIso();

  static bool isLeap(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

  static int daysInMonth(int y, int m) {
    const days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (m == 2 && isLeap(y)) return 29;
    return days[m - 1];
  }

  static LocalDay min(LocalDay a, LocalDay b) => a <= b ? a : b;
  static LocalDay max(LocalDay a, LocalDay b) => a >= b ? a : b;
}
