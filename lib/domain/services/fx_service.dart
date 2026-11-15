import 'package:floos/core/money/currency.dart';
import 'package:floos/core/money/money.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/utils/result.dart';

/// A manually entered exchange rate: 1 [from] = rateE6 / 10^6 [to].
class FxRate {
  const FxRate({
    required this.from,
    required this.to,
    required this.rateE6,
    required this.day,
  });

  final String from;
  final String to;
  final int rateE6;
  final LocalDay day;
}

/// Currency conversion with explicit stored rates and banker's rounding
/// (APP_PROMPT §3.4, §4.12).
class FxService {
  FxService(Iterable<FxRate> rates) {
    for (final r in rates) {
      (_byPair['${r.from}>${r.to}'] ??= []).add(r);
    }
    for (final list in _byPair.values) {
      list.sort((a, b) => a.day.compareTo(b.day));
    }
  }

  static const int scale = 1000000;

  final Map<String, List<FxRate>> _byPair = {};

  /// Latest rate (×10^6) on or before [day] for from→to; tries the inverse
  /// pair; falls back to the earliest rate after [day] if none before.
  int? rateE6(String from, String to, LocalDay day) {
    if (from == to) return scale;
    final direct = _pick(_byPair['$from>$to'], day);
    if (direct != null) return direct.rateE6;
    final inverse = _pick(_byPair['$to>$from'], day);
    if (inverse != null) {
      return divideHalfEvenInt(scale * scale, inverse.rateE6);
    }
    return null;
  }

  /// True when a rate exists on or before [day] (strict lookup, no fallback).
  bool hasRateOnOrBefore(String from, String to, LocalDay day) {
    if (from == to) return true;
    bool has(List<FxRate>? l) => l != null && l.any((r) => r.day <= day);
    return has(_byPair['$from>$to']) || has(_byPair['$to>$from']);
  }

  bool hasAnyRate(String from, String to) =>
      from == to || _byPair.containsKey('$from>$to') || _byPair.containsKey('$to>$from');

  FxRate? _pick(List<FxRate>? list, LocalDay day) {
    if (list == null || list.isEmpty) return null;
    FxRate? best;
    for (final r in list) {
      if (r.day <= day) best = r;
    }
    return best ?? list.first;
  }

  /// Converts [minor] in [from] to [to] using the rate for [day].
  Result<int> convertMinor(int minor, String from, String to, LocalDay day) {
    if (from == to) return Ok(minor);
    final rate = rateE6(from, to, day);
    if (rate == null) {
      return Err(AppFailure.validation('rate_missing', args: {'from': from, 'to': to}));
    }
    return Ok(convertWithRate(minor, Currencies.of(from), Currencies.of(to), rate));
  }

  Result<Money> convert(Money m, Currency to, LocalDay day) =>
      convertMinor(m.minor, m.code, to.code, day).map((v) => Money(v, to));

  /// Pure conversion: minor × rate × 10^dTo / (10^6 × 10^dFrom), half-even.
  static int convertWithRate(int minor, Currency from, Currency to, int rateE6) =>
      divideHalfEven(
        BigInt.from(minor) * BigInt.from(rateE6) * BigInt.from(to.factor),
        BigInt.from(scale) * BigInt.from(from.factor),
      ).toInt();

  /// Implied rate (×10^6) from two amounts, e.g. a transfer's to_amount.
  static int impliedRateE6(int fromMinor, Currency from, int toMinor, Currency to) =>
      divideHalfEven(
        BigInt.from(toMinor) * BigInt.from(scale) * BigInt.from(from.factor),
        BigInt.from(fromMinor) * BigInt.from(to.factor),
      ).toInt();
}
