import 'package:floos/core/time/local_day.dart';
import 'package:floos/domain/services/recurring_engine.dart';
import 'package:flutter_test/flutter_test.dart';

LocalDay d(int y, int m, int day) => LocalDay(y, m, day);

void main() {
  group('Schedule', () {
    test('daily every 3 days', () {
      final s = Schedule(frequency: Frequency.daily, start: d(2026, 1, 1), interval: 3);
      expect(s.first(), d(2026, 1, 1));
      expect(s.nextAfter(d(2026, 1, 1)), d(2026, 1, 4));
      expect(s.firstOnOrAfter(d(2026, 1, 5)), d(2026, 1, 7));
    });

    test('weekly on a weekday, every 2 weeks', () {
      final s = Schedule(frequency: Frequency.weekly, start: d(2026, 1, 1), interval: 2, byWeekday: DateTime.monday);
      expect(s.first(), d(2026, 1, 5));
      expect(s.nextAfter(d(2026, 1, 5)), d(2026, 1, 19));
      expect(s.firstOnOrAfter(d(2026, 1, 6)), d(2026, 1, 19));
      final same = Schedule(frequency: Frequency.weekly, start: d(2026, 1, 1));
      expect(same.first().weekday, d(2026, 1, 1).weekday);
    });

    test('monthly on the 31st clamps (edge case 1) and re-expands', () {
      final s = Schedule(frequency: Frequency.monthly, start: d(2026, 1, 31), byMonthDay: 31);
      expect(s.nextAfter(d(2026, 1, 31)), d(2026, 2, 28));
      expect(s.nextAfter(d(2026, 2, 28)), d(2026, 3, 31));
      expect(s.nextAfter(d(2026, 3, 31)), d(2026, 4, 30));
      final leap = Schedule(frequency: Frequency.monthly, start: d(2024, 1, 30), byMonthDay: 30);
      expect(leap.nextAfter(d(2024, 1, 30)), d(2024, 2, 29));
    });

    test('monthly with month-day before start day starts next month', () {
      final s = Schedule(frequency: Frequency.monthly, start: d(2026, 1, 10), byMonthDay: 5);
      expect(s.first(), d(2026, 2, 5));
    });

    test('quarterly and yearly', () {
      final q = Schedule(frequency: Frequency.monthly, start: d(2026, 1, 15), interval: 3);
      expect(q.nextAfter(d(2026, 1, 15)), d(2026, 4, 15));
      final y = Schedule(frequency: Frequency.yearly, start: d(2024, 2, 29));
      expect(y.nextAfter(d(2024, 2, 29)), d(2025, 2, 28));
      expect(y.nextAfter(d(2025, 2, 28)), d(2026, 2, 28));
      expect(y.firstOnOrAfter(d(2028, 1, 1)), d(2028, 2, 29));
    });
  });

  group('RecurringEngine.due', () {
    test('catch-up after 6 months creates every occurrence (edge case 12)', () {
      final s = Schedule(frequency: Frequency.monthly, start: d(2026, 1, 31), byMonthDay: 31);
      final r = RecurringEngine.due(s, d(2026, 1, 31), 0, d(2026, 7, 31));
      expect(r.days, [d(2026, 1, 31), d(2026, 2, 28), d(2026, 3, 31), d(2026, 4, 30), d(2026, 5, 31), d(2026, 6, 30), d(2026, 7, 31)]);
      expect(r.nextDue, d(2026, 8, 31));
      expect(r.deactivate, isFalse);
    });

    test('daily catch-up over 180 days', () {
      final s = Schedule(frequency: Frequency.daily, start: d(2026, 1, 1));
      final r = RecurringEngine.due(s, d(2026, 1, 1), 0, d(2026, 6, 29));
      expect(r.days.length, 180);
    });

    test('nothing due yet', () {
      final s = Schedule(frequency: Frequency.monthly, start: d(2026, 2, 5));
      final r = RecurringEngine.due(s, d(2026, 2, 5), 0, d(2026, 2, 4));
      expect(r.days, isEmpty);
      expect(r.nextDue, d(2026, 2, 5));
    });

    test('end date deactivates', () {
      final s = Schedule(frequency: Frequency.monthly, start: d(2026, 1, 5), end: d(2026, 3, 1));
      final r = RecurringEngine.due(s, d(2026, 1, 5), 0, d(2026, 6, 1));
      expect(r.days, [d(2026, 1, 5), d(2026, 2, 5)]);
      expect(r.deactivate, isTrue);
    });

    test('max occurrences deactivates', () {
      final s = Schedule(frequency: Frequency.weekly, start: d(2026, 1, 5), maxOccurrences: 3);
      final r = RecurringEngine.due(s, d(2026, 1, 5), 0, d(2026, 6, 1));
      expect(r.days.length, 3);
      expect(r.deactivate, isTrue);
      final partial = RecurringEngine.due(s, d(2026, 1, 12), 1, d(2026, 1, 12));
      expect(partial.days, [d(2026, 1, 12)]);
      expect(partial.deactivate, isFalse);
      final last = RecurringEngine.due(s, d(2026, 1, 19), 2, d(2026, 1, 19));
      expect(last.deactivate, isTrue);
    });

    test('between and reminder day', () {
      final s = Schedule(frequency: Frequency.monthly, start: d(2026, 1, 5));
      expect(RecurringEngine.between(s, d(2026, 1, 5), 0, d(2026, 2, 1), d(2026, 4, 30)), [d(2026, 2, 5), d(2026, 3, 5), d(2026, 4, 5)]);
      expect(RecurringEngine.reminderDay(d(2026, 2, 5), 2), d(2026, 2, 3));
      expect(RecurringEngine.reminderDay(d(2026, 2, 5), null), isNull);
      expect(RecurringEngine.reminderDay(d(2026, 2, 5), 30), d(2026, 1, 29));
    });
  });
}
