import 'package:floos/core/time/local_day.dart';
import 'package:floos/domain/services/fx_service.dart';

/// Minimal account input for balance computations.
class AccountBalanceInput {
  const AccountBalanceInput({
    required this.id,
    required this.currency,
    required this.initial,
    required this.flow,
    this.includeInTotal = true,
    this.archived = false,
  });

  final String id;
  final String currency;
  final int initial;

  /// Σ of transaction effects (income − expense − transfer out + transfer in).
  final int flow;
  final bool includeInTotal;
  final bool archived;

  int get balance => initial + flow;
}

/// Net worth result; [missingRates] lists currencies without a rate.
class NetWorth {
  const NetWorth(this.total, this.missingRates);
  final int total;
  final Set<String> missingRates;
}

/// Reconcile outcome: an adjustment transaction to create.
class Adjustment {
  const Adjustment({required this.isIncome, required this.amount});
  final bool isIncome;
  final int amount;
}

/// One leg of a transaction affecting an account (for running balances).
class BalanceLeg {
  const BalanceLeg(this.txId, this.delta);
  final String txId;
  final int delta;
}

/// Derived balances (APP_PROMPT §5.3). Balances are never stored.
abstract final class BalanceService {
  /// Effect of a single transaction on [accountId].
  static int effectOn(
    String accountId, {
    required String type,
    required int amount,
    required String sourceAccountId,
    String? toAccountId,
    int? toAmount,
    bool pending = false,
  }) {
    if (pending) return 0;
    var d = 0;
    if (sourceAccountId == accountId) {
      d += type == 'income' ? amount : -amount;
    }
    if (type == 'transfer' && toAccountId == accountId) {
      d += toAmount ?? amount;
    }
    return d;
  }

  /// Σ balances of included, non-archived accounts converted to [base].
  static NetWorth netWorth(
    Iterable<AccountBalanceInput> accounts,
    String base,
    FxService fx,
    LocalDay day,
  ) {
    var total = 0;
    final missing = <String>{};
    for (final a in accounts) {
      if (!a.includeInTotal || a.archived) continue;
      final r = fx.convertMinor(a.balance, a.currency, base, day);
      final v = r.valueOrNull;
      if (v == null) {
        missing.add(a.currency);
      } else {
        total += v;
      }
    }
    return NetWorth(total, missing);
  }

  /// Adjustment needed to move [current] to [real]; null if equal.
  static Adjustment? reconcile(int current, int real) {
    final diff = real - current;
    if (diff == 0) return null;
    return Adjustment(isIncome: diff > 0, amount: diff.abs());
  }

  /// Running balance after each leg, starting from [initial] (legs must be
  /// in chronological order).
  static Map<String, int> running(int initial, Iterable<BalanceLeg> legs) {
    var acc = initial;
    final out = <String, int>{};
    for (final l in legs) {
      acc += l.delta;
      out[l.txId] = acc;
    }
    return out;
  }
}
