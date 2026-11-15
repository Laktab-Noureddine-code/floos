import 'package:floos/core/time/clock.dart';
import 'package:floos/core/time/period_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalDay', () {
    test('normalizes and does calendar arithmetic', () {
      expect(LocalDay(2026, 13, 1), LocalDay(2027, 1, 1));
      expect(LocalDay(2026, 3, 0), LocalDay(2026, 2, 28));
      expect(LocalDay(2024, 1, 31).addMonths(1), LocalDay(2024, 2, 29));
      expect(LocalDay(2025, 1, 31).addMonths(1), LocalDay(2025, 2, 28));
      expect(LocalDay(2025, 12, 31).addDays(1), LocalDay(2026, 1, 1));
      expect(LocalDay(2026, 1, 1).daysUntil(LocalDay(2026, 3, 1)), 59);
      expect(LocalDay(2026, 1, 12).weekday, DateTime.monday);
      expect(LocalDay(2024, 2, 29).addYears(1), LocalDay(2025, 2, 28));
    });

    test('storage round trip is stable (DST safe)', () {
      for (var d = LocalDay(2026, 1, 1); d < LocalDay(2027, 1, 1); d = d.addDays(1)) {
        expect(LocalDay.fromStorage(d.toStorage()), d);
      }
    });

    test('fromStorage maps a shifted midnight to the nearest day (travel)', () {
      final d = LocalDay(2026, 6, 15);
      final shiftedBack = d.toStorage() - const Duration(hours: 3).inMilliseconds;
      final shiftedFwd = d.toStorage() + const Duration(hours: 5).inMilliseconds;
      expect(LocalDay.fromStorage(shiftedBack), d);
      expect(LocalDay.fromStorage(shiftedFwd), d);
    });

    test('parse and format', () {
      expect(LocalDay.tryParse('2026-02-29'), isNull);
      expect(LocalDay.tryParse('2024-02-29'), LocalDay(2024, 2, 29));
      expect(LocalDay.tryParse('bad'), isNull);
      expect(LocalDay(2026, 1, 5).toIso(), '2026-01-05');
      expect(LocalDay.isLeap(2000), isTrue);
      expect(LocalDay.isLeap(1900), isFalse);
      expect(LocalDay.min(LocalDay(2026, 1, 1), LocalDay(2026, 1, 2)), LocalDay(2026, 1, 1));
      expect(LocalDay.max(LocalDay(2026, 1, 1), LocalDay(2026, 1, 2)), LocalDay(2026, 1, 2));
    });
  });

  group('month periods', () {
    test('start day 1 equals calendar month', () {
      final p = Period.month(LocalDay(2026, 2, 14), 1);
      expect(p.start, LocalDay(2026, 2, 1));
      expect(p.end, LocalDay(2026, 2, 28));
      expect(p.daysTotal, 28);
    });

    test('start day 25 before and after', () {
      final after = Period.month(LocalDay(2026, 1, 26), 25);
      expect(after.start, LocalDay(2026, 1, 25));
      expect(after.end, LocalDay(2026, 2, 24));
      final before = Period.month(LocalDay(2026, 1, 3), 25);
      expect(before.start, LocalDay(2025, 12, 25));
      expect(before.end, LocalDay(2026, 1, 24));
    });

    test('start day is clamped to 28 (edge case 1)', () {
      final p = Period.month(LocalDay(2026, 3, 30), 31);
      expect(p.start, LocalDay(2026, 3, 28));
      expect(Period.clampStartDay(0), 1);
    });

    test('every start day covers contiguous periods across leap years', () {
      for (var s = 1; s <= 28; s++) {
        var p = Period.month(LocalDay(2023, 12, 15), s);
        for (var i = 0; i < 30; i++) {
          final n = p.next();
          expect(n.start, p.end.addDays(1));
          expect(n.previous(), p);
          p = n;
        }
      }
    });

    test('contains, daysLeft, daysElapsed', () {
      final p = Period.month(LocalDay(2026, 1, 10), 1);
      expect(p.contains(LocalDay(2026, 1, 31)), isTrue);
      expect(p.contains(LocalDay(2026, 2, 1)), isFalse);
      expect(p.daysLeft(LocalDay(2026, 1, 31)), 1);
      expect(p.daysLeft(LocalDay(2026, 2, 3)), 0);
      expect(p.daysLeft(LocalDay(2025, 12, 3)), 31);
      expect(p.daysElapsed(LocalDay(2026, 1, 10)), 10);
      expect(p.daysElapsed(LocalDay(2025, 12, 31)), 0);
      expect(p.daysElapsed(LocalDay(2026, 3, 1)), 31);
      expect(p.days.length, 31);
      expect(p.key, 'month:2026-01-01');
    });

    test('previousAligned compares day N to day N', () {
      final p = Period.month(LocalDay(2026, 3, 10), 1);
      final a = p.previousAligned(LocalDay(2026, 3, 10));
      expect(a.start, LocalDay(2026, 2, 1));
      expect(a.end, LocalDay(2026, 2, 10));
      final late = Period.month(LocalDay(2026, 3, 31), 1).previousAligned(LocalDay(2026, 3, 31));
      expect(late.end, LocalDay(2026, 2, 28));
    });
  });

  group('week and year periods', () {
    test('week start Monday, Saturday, Sunday', () {
      final wed = LocalDay(2026, 1, 14);
      expect(Period.week(wed, 1).start, LocalDay(2026, 1, 12));
      expect(Period.week(wed, 6).start, LocalDay(2026, 1, 10));
      expect(Period.week(wed, 7).start, LocalDay(2026, 1, 11));
      expect(Period.week(wed, 1).daysTotal, 7);
      expect(Period.week(wed, 1).next().start, LocalDay(2026, 1, 19));
      expect(Period.week(wed, 1).previous().start, LocalDay(2026, 1, 5));
    });

    test('year and custom', () {
      final y = Period.year(LocalDay(2024, 6, 1));
      expect(y.daysTotal, 366);
      expect(y.next().start, LocalDay(2025, 1, 1));
      expect(y.previous().start, LocalDay(2023, 1, 1));
      final c = Period.custom(LocalDay(2026, 1, 1), LocalDay(2026, 1, 10));
      expect(c.previous().end, LocalDay(2025, 12, 31));
      expect(c.next().start, LocalDay(2026, 1, 11));
      expect(Period.of(PeriodKind.year, LocalDay(2026, 5, 5)).start, LocalDay(2026, 1, 1));
      expect(Period.of(PeriodKind.custom, LocalDay(2026, 5, 5)).daysTotal, 1);
    });

    test('calculator helpers', () {
      const calc = PeriodCalculator(monthStartDay: 25, weekStartDay: 6);
      final months = calc.lastMonths(LocalDay(2026, 1, 3), 12);
      expect(months.length, 12);
      expect(months.last.start, LocalDay(2025, 12, 25));
      expect(calc.weekPeriodFor(LocalDay(2026, 1, 14)).start, LocalDay(2026, 1, 10));
      expect(calc.yearPeriodFor(LocalDay(2026, 1, 14)).start, LocalDay(2026, 1, 1));
      expect(calc.periodFor(PeriodKind.month, LocalDay(2026, 1, 26)).start, LocalDay(2026, 1, 25));
    });
  });

  test('clock', () {
    final c = FixedClock(DateTime(2026, 1, 12, 15));
    expect(c.today(), LocalDay(2026, 1, 12));
    expect(const Clock().today(), LocalDay.fromDateTime(DateTime.now()));
  });
}
