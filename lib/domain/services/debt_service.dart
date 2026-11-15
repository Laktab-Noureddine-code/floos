import 'package:floos/core/money/money.dart';
import 'package:floos/core/time/local_day.dart';

/// Computed debt status (APP_PROMPT §5.8).
class DebtStatus {
  const DebtStatus({
    required this.paid,
    required this.remaining,
    required this.percentPaid,
    required this.overdue,
    required this.shouldSettle,
  });

  final int paid;
  final int remaining;
  final int percentPaid;
  final bool overdue;
  final bool shouldSettle;
}

/// Debt math: remaining, % paid, overdue flag, auto-settle.
abstract final class DebtService {
  /// [payments] are amounts in the debt currency.
  static DebtStatus evaluate({
    required int original,
    required Iterable<int> payments,
    required LocalDay today,
    LocalDay? due,
  }) {
    final paid = payments.fold<int>(0, (a, b) => a + b);
    final remaining = original - paid < 0 ? 0 : original - paid;
    final pct = original <= 0 ? 0 : divideHalfEvenInt(paid.clamp(0, original) * 100, original);
    return DebtStatus(
      paid: paid,
      remaining: remaining,
      percentPaid: pct,
      overdue: due != null && due < today && remaining > 0,
      shouldSettle: remaining <= 0,
    );
  }

  /// Days on which a "debt due" notification fires (1 day before + due day).
  static List<LocalDay> reminderDays(LocalDay due) => [due.addDays(-1), due];
}
