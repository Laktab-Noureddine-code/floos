import 'package:floos/core/money/currency.dart';
import 'package:meta/meta.dart';

/// Thrown when arithmetic mixes two currencies.
class CurrencyMismatchError extends Error {
  CurrencyMismatchError(this.a, this.b);

  final String a;
  final String b;

  @override
  String toString() => 'CurrencyMismatchError($a, $b)';
}

/// Maximum absolute amount accepted (10^13 minor units, APP_PROMPT §13.10).
const int kMaxMinorUnits = 10000000000000;

/// Divides [numerator] by [denominator] rounding half to even (banker's).
BigInt divideHalfEven(BigInt numerator, BigInt denominator) {
  if (denominator == BigInt.zero) {
    throw ArgumentError('division by zero');
  }
  var n = numerator;
  var d = denominator;
  if (d.isNegative) {
    n = -n;
    d = -d;
  }
  final negative = n.isNegative;
  final absN = n.abs();
  var q = absN ~/ d;
  final r = absN - q * d;
  final twice = r * BigInt.two;
  if (twice > d || (twice == d && q.isOdd)) {
    q += BigInt.one;
  }
  return negative ? -q : q;
}

/// Integer helper for [divideHalfEven].
int divideHalfEvenInt(int numerator, int denominator) =>
    divideHalfEven(BigInt.from(numerator), BigInt.from(denominator)).toInt();

/// Immutable money value stored as integer minor units (Constitution III).
@immutable
class Money implements Comparable<Money> {
  const Money(this.minor, this.currency);

  const Money.zero(this.currency) : minor = 0;

  /// Amount in minor units (cents, centimes…).
  final int minor;
  final Currency currency;

  String get code => currency.code;
  bool get isZero => minor == 0;
  bool get isNegative => minor < 0;
  bool get isPositive => minor > 0;

  Money abs() => Money(minor.abs(), currency);

  Money operator -() => Money(-minor, currency);

  Money operator +(Money other) {
    _check(other);
    return Money(minor + other.minor, currency);
  }

  Money operator -(Money other) {
    _check(other);
    return Money(minor - other.minor, currency);
  }

  /// Multiplies by the ratio [numerator]/[denominator] with banker's rounding.
  Money timesRatio(int numerator, int denominator) => Money(
    divideHalfEven(
      BigInt.from(minor) * BigInt.from(numerator),
      BigInt.from(denominator),
    ).toInt(),
    currency,
  );

  bool operator <(Money other) => compareTo(other) < 0;
  bool operator >(Money other) => compareTo(other) > 0;
  bool operator <=(Money other) => compareTo(other) <= 0;
  bool operator >=(Money other) => compareTo(other) >= 0;

  @override
  int compareTo(Money other) {
    _check(other);
    return minor.compareTo(other.minor);
  }

  void _check(Money other) {
    if (other.currency.code != currency.code) {
      throw CurrencyMismatchError(currency.code, other.currency.code);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Money && other.minor == minor && other.currency == currency;

  @override
  int get hashCode => Object.hash(minor, currency.code);

  @override
  String toString() => 'Money($minor ${currency.code})';
}
