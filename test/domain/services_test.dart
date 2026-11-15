import 'package:floos/core/money/currency.dart';
import 'package:floos/core/money/money.dart';
import 'package:floos/core/time/period.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/domain/services/balance_service.dart';
import 'package:floos/domain/services/budget_service.dart';
import 'package:floos/domain/services/debt_service.dart';
import 'package:floos/domain/services/fx_service.dart';
import 'package:floos/domain/services/goal_service.dart';
import 'package:floos/domain/services/insight_engine.dart';
import 'package:floos/domain/services/pin_hasher.dart';
import 'package:floos/domain/services/report_service.dart';
import 'package:floos/domain/services/totals_service.dart';
import 'package:flutter_test/flutter_test.dart';

LocalDay d(int y, int m, int day) => LocalDay(y, m, day);

void main() {
  group('FxService', () {
    final fx = FxService([
      FxRate(from: 'EUR', to: 'MAD', rateE6: 10800000, day: d(2026, 1, 1)),
      FxRate(from: 'EUR', to: 'MAD', rateE6: 11000000, day: d(2026, 2, 1)),
      FxRate(from: 'USD', to: 'JPY', rateE6: 150000000, day: d(2026, 1, 1)),
    ]);

    test('uses latest rate on or before the date', () {
      expect(fx.convertMinor(10000, 'EUR', 'MAD', d(2026, 1, 15)).requireValue, 108000);
      expect(fx.convertMinor(10000, 'EUR', 'MAD', d(2026, 2, 15)).requireValue, 110000);
      expect(fx.convertMinor(10000, 'EUR', 'MAD', d(2025, 12, 1)).requireValue, 108000);
      expect(fx.hasRateOnOrBefore('EUR', 'MAD', d(2025, 12, 1)), isFalse);
      expect(fx.hasRateOnOrBefore('EUR', 'MAD', d(2026, 1, 1)), isTrue);
    });

    test('inverse pair and same currency', () {
      expect(fx.convertMinor(108000, 'MAD', 'EUR', d(2026, 1, 15)).requireValue, 10000);
      expect(fx.convertMinor(5, 'MAD', 'MAD', d(2026, 1, 1)).requireValue, 5);
      expect(fx.hasAnyRate('MAD', 'EUR'), isTrue);
    });

    test('digit differences and missing rate', () {
      expect(fx.convertMinor(100, 'USD', 'JPY', d(2026, 1, 2)).requireValue, 150);
      expect(fx.convertMinor(100, 'GBP', 'MAD', d(2026, 1, 2)).failureOrNull?.code, 'rate_missing');
      expect(fx.convert(Money(100, Currencies.of('USD')), Currencies.of('JPY'), d(2026, 1, 2)).requireValue.minor, 150);
    });

    test('banker rounding and implied rate', () {
      expect(FxService.convertWithRate(1, Currencies.of('USD'), Currencies.of('USD'), 500000), 0);
      expect(FxService.convertWithRate(3, Currencies.of('USD'), Currencies.of('USD'), 500000), 2);
      expect(FxService.impliedRateE6(10000, Currencies.of('EUR'), 108000, Currencies.of('MAD')), 10800000);
    });
  });

  group('BalanceService', () {
    test('effects of each type, transfers in and out, pending ignored', () {
      expect(BalanceService.effectOn('a', type: 'income', amount: 100, sourceAccountId: 'a'), 100);
      expect(BalanceService.effectOn('a', type: 'expense', amount: 100, sourceAccountId: 'a'), -100);
      expect(BalanceService.effectOn('a', type: 'transfer', amount: 100, sourceAccountId: 'a', toAccountId: 'b'), -100);
      expect(BalanceService.effectOn('b', type: 'transfer', amount: 100, sourceAccountId: 'a', toAccountId: 'b', toAmount: 1080), 1080);
      expect(BalanceService.effectOn('b', type: 'transfer', amount: 100, sourceAccountId: 'a', toAccountId: 'b'), 100);
      expect(BalanceService.effectOn('a', type: 'expense', amount: 100, sourceAccountId: 'a', pending: true), 0);
      expect(BalanceService.effectOn('c', type: 'expense', amount: 100, sourceAccountId: 'a'), 0);
    });

    test('net worth converts and skips excluded/archived', () {
      final fx = FxService([FxRate(from: 'EUR', to: 'MAD', rateE6: 10000000, day: d(2026, 1, 1))]);
      final nw = BalanceService.netWorth(
        const [
          AccountBalanceInput(id: 'a', currency: 'MAD', initial: 1000, flow: 500),
          AccountBalanceInput(id: 'b', currency: 'EUR', initial: 100, flow: 0),
          AccountBalanceInput(id: 'c', currency: 'MAD', initial: 999, flow: 0, includeInTotal: false),
          AccountBalanceInput(id: 'd', currency: 'MAD', initial: 999, flow: 0, archived: true),
          AccountBalanceInput(id: 'e', currency: 'GBP', initial: 5, flow: 0),
        ],
        'MAD',
        fx,
        d(2026, 1, 2),
      );
      expect(nw.total, 1500 + 1000);
      expect(nw.missingRates, {'GBP'});
    });

    test('reconcile and running balance', () {
      expect(BalanceService.reconcile(100, 100), isNull);
      final up = BalanceService.reconcile(100, 250)!;
      expect(up.isIncome, isTrue);
      expect(up.amount, 150);
      final down = BalanceService.reconcile(100, 40)!;
      expect(down.isIncome, isFalse);
      expect(down.amount, 60);
      expect(BalanceService.running(100, const [BalanceLeg('t1', -30), BalanceLeg('t2', 50)]), {'t1': 70, 't2': 120});
    });
  });

  group('TotalsService', () {
    test('converts grouped sums and computes rates', () {
      final fx = FxService([FxRate(from: 'EUR', to: 'MAD', rateE6: 10000000, day: d(2026, 1, 1))]);
      final r = TotalsService.convert(
        [
          DaySum(key: 'food', currency: 'MAD', day: d(2026, 1, 2), sum: 100, count: 2),
          DaySum(key: 'food', currency: 'EUR', day: d(2026, 1, 2), sum: 10),
          DaySum(key: 'x', currency: 'GBP', day: d(2026, 1, 3), sum: 10),
        ],
        'MAD',
        fx,
      );
      expect(r.total, 200);
      expect(r.byKey['food'], 200);
      expect(r.byDay[d(2026, 1, 2)], 200);
      expect(r.count, 3);
      expect(r.missingRates, {'GBP'});
      expect(TotalsService.savingsRatePct(1000, 780), 22);
      expect(TotalsService.savingsRatePct(0, 5), isNull);
      expect(TotalsService.changePct(134, 100), 34);
      expect(TotalsService.changePct(1, 0), isNull);
    });
  });

  group('BudgetService', () {
    final def = BudgetDef(id: 'b', amount: 2000, period: 'monthly', createdDay: d(2026, 1, 1));

    test('levels by thresholds', () {
      expect(BudgetService.levelFor(699), BudgetLevel.ok);
      expect(BudgetService.levelFor(700), BudgetLevel.warning);
      expect(BudgetService.levelFor(1000), BudgetLevel.warning);
      expect(BudgetService.levelFor(1001), BudgetLevel.over);
    });

    test('evaluate: progress, per day, projection', () {
      final s = BudgetService.evaluate(def, d(2026, 1, 10), (_) => 1000);
      expect(s.available, 2000);
      expect(s.progressPermille, 500);
      expect(s.percent, 50);
      expect(s.level, BudgetLevel.ok);
      expect(s.daysLeft, 22);
      expect(s.remainingPerDay, 1000 ~/ 22);
      expect(s.projected, 3100);
      expect(s.projectedOver, isTrue);
      expect(s.projectedOverBy, 1100);
    });

    test('over budget shows >100 and 0 per day', () {
      final s = BudgetService.evaluate(def, d(2026, 1, 20), (_) => 2240);
      expect(s.percent, 112);
      expect(s.level, BudgetLevel.over);
      expect(s.remainingPerDay, 0);
    });

    test('rollover carries unused and overspent amounts recursively', () {
      final r = BudgetDef(id: 'b', amount: 1000, period: 'monthly', createdDay: d(2026, 1, 1), rollover: true);
      final spent = {
        d(2026, 1, 1): 800, // +200
        d(2026, 2, 1): 1500, // 1200 available -> -300
      };
      int spentIn(Period p) => spent[p.start] ?? 0;
      final march = BudgetService.evaluate(r, d(2026, 3, 5), spentIn);
      expect(march.rolloverIn, -300);
      expect(march.available, 700);
      final feb = BudgetService.evaluate(r, d(2026, 2, 5), spentIn);
      expect(feb.available, 1200);
    });

    test('rollover capped at 12 periods back', () {
      final r = BudgetDef(id: 'b', amount: 100, period: 'monthly', createdDay: d(2020, 1, 1), rollover: true);
      final s = BudgetService.evaluate(r, d(2026, 6, 5), (_) => 0);
      expect(s.rolloverIn, 1200);
    });

    test('weekly, yearly and custom periods', () {
      final w = BudgetDef(id: 'w', amount: 100, period: 'weekly', createdDay: d(2026, 1, 1));
      expect(BudgetService.periodFor(w, d(2026, 1, 14), weekStartDay: 1).start, d(2026, 1, 12));
      final y = BudgetDef(id: 'y', amount: 100, period: 'yearly', createdDay: d(2026, 1, 1));
      expect(BudgetService.periodFor(y, d(2026, 5, 1)).start, d(2026, 1, 1));
      final c = BudgetDef(
        id: 'c',
        amount: 100,
        period: 'custom',
        createdDay: d(2026, 1, 1),
        customStart: d(2026, 1, 5),
        customEnd: d(2026, 1, 20),
      );
      expect(BudgetService.periodFor(c, d(2026, 1, 10)).daysTotal, 16);
    });

    test('thresholds crossed once and parsing', () {
      final s = BudgetService.evaluate(def, d(2026, 1, 10), (_) => 1640);
      expect(BudgetService.crossedThresholds(def, s, {}), [80]);
      expect(BudgetService.crossedThresholds(def, s, {80}), isEmpty);
      expect(BudgetDef.parseThresholds('[100, 50, 80, 500]'), [50, 80, 100]);
      expect(BudgetDef.parseThresholds('oops'), [80, 100]);
      expect(BudgetService.cumulative(Period.month(d(2026, 1, 1), 1), {d(2026, 1, 1): 5, d(2026, 1, 3): 7}, d(2026, 1, 3)), [5, 5, 12]);
      final zero = BudgetService.evaluate(def, d(2026, 1, 1), (_) => 0);
      expect(zero.projected, 0);
    });

    test('zero or negative available', () {
      final r = BudgetDef(id: 'b', amount: 100, period: 'monthly', createdDay: d(2026, 1, 1), rollover: true);
      final s = BudgetService.evaluate(r, d(2026, 2, 5), (p) => p.start == d(2026, 1, 1) ? 300 : 10);
      expect(s.available, -100);
      expect(s.level, BudgetLevel.over);
    });
  });

  group('GoalService', () {
    test('behind schedule', () {
      final s = GoalService.evaluate(
        GoalInput(target: 1200, start: d(2026, 1, 1), deadline: d(2027, 1, 1), contributions: [GoalContributionInput(50, d(2026, 1, 5))]),
        d(2026, 7, 2),
      );
      expect(s.state, GoalState.behind);
      expect(s.expectedNow, 598); // 1200 × 182 / 365
      expect(s.behindPct, 92);
      expect(s.remaining, 1150);
      expect(s.neededPerMonth, 230); // ceil(1150 / 5 months left)
    });

    test('on track at 90% of expected', () {
      final s = GoalService.evaluate(
        GoalInput(target: 1200, start: d(2026, 1, 1), deadline: d(2027, 1, 1), contributions: [GoalContributionInput(540, d(2026, 1, 5))]),
        d(2026, 7, 2),
      );
      expect(s.state, GoalState.onTrack);
      expect(s.behindPct, isNull);
    });

    test('completed and progress beyond target', () {
      final s = GoalService.evaluate(
        GoalInput(target: 1000, start: d(2026, 1, 1), contributions: [GoalContributionInput(1200, d(2026, 1, 5))]),
        d(2026, 2, 1),
      );
      expect(s.state, GoalState.completed);
      expect(s.percent, 120);
      expect(s.barFraction, 1.0);
      expect(s.remaining, 0);
      expect(s.isCompleted, isTrue);
    });

    test('manual completion and linked balance', () {
      final s = GoalService.evaluate(
        GoalInput(target: 1000, start: d(2026, 1, 1), linkedBalance: 400, manuallyCompleted: true),
        d(2026, 2, 1),
      );
      expect(s.state, GoalState.completed);
      expect(s.saved, 400);
    });

    test('no deadline: average and ETA', () {
      final s = GoalService.evaluate(
        GoalInput(
          target: 1000,
          start: d(2026, 1, 1),
          contributions: [GoalContributionInput(100, d(2026, 1, 2)), GoalContributionInput(100, d(2026, 2, 2)), GoalContributionInput(-20, d(2026, 2, 3))],
        ),
        d(2026, 2, 15),
      );
      expect(s.state, GoalState.noDeadline);
      expect(s.avgMonthly, 90);
      expect(s.estimatedCompletion, d(2026, 12, 15));
      final none = GoalService.evaluate(GoalInput(target: 1000, start: d(2026, 1, 1)), d(2026, 2, 15));
      expect(none.estimatedCompletion, isNull);
    });

    test('months left at least 1, milestones, cumulative', () {
      expect(GoalService.monthsLeftUntil(d(2026, 1, 15), d(2026, 2, 10)), 1);
      expect(GoalService.monthsLeftUntil(d(2026, 1, 15), d(2026, 7, 15)), 6);
      expect(GoalService.newMilestones(510, {25}), [50]);
      expect(GoalService.newMilestones(1000, {}), [25, 50, 75, 100]);
      expect(
        GoalService.cumulative([GoalContributionInput(5, d(2026, 1, 3)), GoalContributionInput(10, d(2026, 1, 1))]).map((e) => e.$2),
        [10, 15],
      );
      final zeroTarget = GoalService.evaluate(GoalInput(target: 0, start: d(2026, 1, 1)), d(2026, 1, 2));
      expect(zeroTarget.progressPermille, 0);
    });
  });

  group('DebtService', () {
    test('remaining, percent, overdue, settle', () {
      final open = DebtService.evaluate(original: 500, payments: [200], today: d(2026, 1, 10), due: d(2026, 1, 5));
      expect(open.remaining, 300);
      expect(open.percentPaid, 40);
      expect(open.overdue, isTrue);
      expect(open.shouldSettle, isFalse);
      final done = DebtService.evaluate(original: 500, payments: [200, 300], today: d(2026, 1, 10), due: d(2026, 1, 5));
      expect(done.remaining, 0);
      expect(done.overdue, isFalse);
      expect(done.shouldSettle, isTrue);
      final over = DebtService.evaluate(original: 500, payments: [700], today: d(2026, 1, 10));
      expect(over.percentPaid, 100);
      expect(DebtService.reminderDays(d(2026, 3, 1)), [d(2026, 2, 28), d(2026, 3, 1)]);
      expect(DebtService.evaluate(original: 0, payments: [], today: d(2026, 1, 1)).percentPaid, 0);
    });
  });

  group('InsightEngine', () {
    test('each rule fires and ranking is by priority', () {
      final list = InsightEngine.compute(
        const InsightInputs(
          budgets: [
            BudgetInsightInput(id: 'b1', name: 'Food', percent: 112, spent: 2240, available: 2000, perDay: 0),
            BudgetInsightInput(id: 'b2', name: 'Cafes', percent: 86, spent: 860, available: 1000, perDay: 14),
            BudgetInsightInput(id: 'b3', name: 'Ok', percent: 20, spent: 20, available: 100, perDay: 5),
          ],
          goalsBehind: [GoalInsightInput(id: 'g', name: 'House', neededPerMonth: 210)],
          bills: [
            BillInsightInput(ruleId: 'r', name: 'Internet', amount: 299, currency: 'MAD', daysUntil: 2),
            BillInsightInput(ruleId: 'r2', name: 'Far', amount: 1, currency: 'MAD', daysUntil: 9),
          ],
          categoryTrends: [
            CategoryTrendInput(categoryId: 'c', name: 'Cafes', current: 134, previous: 100),
            CategoryTrendInput(categoryId: 'c2', name: 'Flat', current: 101, previous: 100),
            CategoryTrendInput(categoryId: 'c3', name: 'New', current: 101, previous: 0),
          ],
          unusual: [
            UnusualTxInput(txId: 't', categoryName: 'Food', amount: 400, currency: 'MAD', median: 100),
            UnusualTxInput(txId: 't2', categoryName: 'Food', amount: 200, currency: 'MAD', median: 100),
          ],
          income: 1000,
          expense: 780,
          daysSinceLastTx: 4,
          hasData: true,
        ),
      );
      expect(list.map((e) => e.kind), [
        InsightKind.budgetOver,
        InsightKind.budgetWarning,
        InsightKind.goalBehind,
        InsightKind.upcomingBill,
        InsightKind.categoryUp,
        InsightKind.unusualTransaction,
        InsightKind.savingsRate,
        InsightKind.backupOverdue,
        InsightKind.noRecentLogs,
      ]);
      expect(list.first.params['over'], 240);
      expect(list[4].params['percent'], 34);
      expect(list[6].params['percent'], 22);
    });

    test('dismissed insights are hidden; nothing when empty', () {
      final list = InsightEngine.compute(
        const InsightInputs(income: 100, expense: 50, dismissed: {'savingsRate'}),
      );
      expect(list, isEmpty);
      expect(InsightEngine.compute(const InsightInputs(income: 100, expense: 150)), isEmpty);
      expect(InsightEngine.compute(const InsightInputs(hasData: true, daysSinceBackup: 5, daysSinceLastTx: 1)), isEmpty);
    });

    test('median', () {
      expect(InsightEngine.median([]), 0);
      expect(InsightEngine.median([3, 1, 2]), 2);
      expect(InsightEngine.median([1, 2, 3, 4]), 2); // 2.5 -> 2
    });
  });

  group('ReportService', () {
    test('roll up subcategories to parent (edge case 14)', () {
      final items = ReportService.rollUp(
        {'food': 100, 'groceries': 300, 'cafes': 200, 'rent': 1000, null: 5},
        {'groceries': 'food', 'cafes': 'food', 'food': null, 'rent': null},
        previous: {'groceries': 100, 'rent': 900},
        counts: {'groceries': 3, 'cafes': 1, 'food': 1, 'rent': 1},
      );
      expect(items.first.key, 'rent');
      final food = items[1];
      expect(food.key, 'food');
      expect(food.total, 600);
      expect(food.previous, 100);
      expect(food.count, 5);
      expect(food.children.map((c) => c.key), ['groceries', 'cafes', 'food']);
      expect(food.sharePermille(1600), 375);
      expect(food.sharePermille(0), 0);
    });

    test('flat, bucket, daily, avg, argMax', () {
      expect(ReportService.flat({'a': 5, 'b': 9, null: 3, 'z': 0}).map((e) => e.key), ['b', 'a']);
      final months = [Period.month(d(2026, 1, 1), 1), Period.month(d(2026, 2, 1), 1)];
      expect(ReportService.bucket({d(2026, 1, 5): 10, d(2026, 2, 5): 20, d(2026, 2, 6): 1}, months), [10, 21]);
      final p = Period.custom(d(2026, 1, 1), d(2026, 1, 3));
      expect(ReportService.dailySeries(p, {d(2026, 1, 2): 4}), [0, 4, 0]);
      expect(ReportService.avgPerDay(10, p, d(2026, 1, 2)), 5);
      expect(ReportService.avgPerDay(10, p, d(2025, 1, 2)), 0);
      expect(ReportService.argMax({'a': 1, 'b': 3, null: 9}), 'b');
      expect(ReportService.argMax({}), isNull);
    });
  });

  group('PinHasher', () {
    test('hash, verify, validity, lockout', () {
      final h = PinHasher.hash('1234', rounds: 1000);
      expect(PinHasher.verify('1234', h), isTrue);
      expect(PinHasher.verify('4321', h), isFalse);
      expect(PinHasher.verify('1234', 'garbage'), isFalse);
      expect(PinHasher.hash('1234', rounds: 1000) == h, isFalse, reason: 'salted');
      expect(PinHasher.isValidPin('123'), isFalse);
      expect(PinHasher.isValidPin('123456'), isTrue);
      expect(PinHasher.isValidPin('12a4'), isFalse);
      expect(PinHasher.delayFor(4), Duration.zero);
      expect(PinHasher.delayFor(5), const Duration(seconds: 150));
      expect(PinHasher.delayFor(6), const Duration(seconds: 180));
    });

    test('pbkdf2 matches RFC 7914 test vector', () {
      final dk = PinHasher.pbkdf2('passwd'.codeUnits, 'salt'.codeUnits, 1, 64);
      expect(
        dk.map((b) => b.toRadixString(16).padLeft(2, '0')).join().substring(0, 32),
        '55ac046e56e3089fec1691c22544b605',
      );
    });
  });
}
