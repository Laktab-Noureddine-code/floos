import 'package:floos/core/money/amount_input_parser.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/money/money.dart';
import 'package:floos/core/utils/result.dart';

/// Exact rational number used by [Calculator] (no `double`).
class _Rational {
  _Rational(BigInt n, BigInt d) : num = d.isNegative ? -n : n, den = d.abs();

  final BigInt num;
  final BigInt den;

  _Rational operator +(_Rational o) =>
      _Rational(num * o.den + o.num * den, den * o.den);
  _Rational operator -(_Rational o) =>
      _Rational(num * o.den - o.num * den, den * o.den);
  _Rational operator *(_Rational o) => _Rational(num * o.num, den * o.den);
  _Rational operator /(_Rational o) => _Rational(num * o.den, den * o.num);
}

/// Keypad calculator: evaluates `45+12.5`, `100÷3`, `2×7−1` into minor units.
///
/// Operators: `+ − × ÷` (and ASCII `- * /`), standard precedence. The result
/// is rounded half-even to the currency's minor unit.
abstract final class Calculator {
  static const operators = ['+', '−', '×', '÷'];

  static bool isOperator(String ch) =>
      operators.contains(ch) || ch == '-' || ch == '*' || ch == '/';

  /// True when [expr] contains at least one binary operator.
  static bool hasOperator(String expr) =>
      expr.length > 1 && expr.substring(1).split('').any(isOperator);

  static Result<int> evaluate(String expr, Currency currency) {
    final normalized = AmountInputParser.normalizeDigits(expr)
        .replaceAll('−', '-')
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll(RegExp(r'\s'), '');
    if (normalized.isEmpty) {
      return const Err(AppFailure.validation('amount_empty'));
    }
    final tokens = <Object>[];
    final buf = StringBuffer();
    for (var i = 0; i < normalized.length; i++) {
      final ch = normalized[i];
      if ('+-*/'.contains(ch)) {
        if (buf.isEmpty) {
          // Unary minus/plus at start or after an operator.
          if ((ch == '-' || ch == '+') && (tokens.isEmpty || tokens.last is String)) {
            buf.write(ch);
            continue;
          }
          return const Err(AppFailure.validation('amount_invalid'));
        }
        final r = _number(buf.toString(), currency);
        if (r == null) return const Err(AppFailure.validation('amount_invalid'));
        tokens
          ..add(r)
          ..add(ch);
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    if (buf.isEmpty) {
      // Trailing operator: ignore it (e.g. "45+").
      if (tokens.isNotEmpty) tokens.removeLast();
    } else {
      final r = _number(buf.toString(), currency);
      if (r == null) return const Err(AppFailure.validation('amount_invalid'));
      tokens.add(r);
    }
    if (tokens.isEmpty) return const Err(AppFailure.validation('amount_empty'));
    // Precedence: fold * and / first.
    final pass = <Object>[tokens.first];
    for (var i = 1; i < tokens.length; i += 2) {
      final op = tokens[i] as String;
      final rhs = tokens[i + 1] as _Rational;
      if (op == '*' || op == '/') {
        final lhs = pass.removeLast() as _Rational;
        if (op == '/' && rhs.num == BigInt.zero) {
          return const Err(AppFailure.validation('amount_division_zero'));
        }
        pass.add(op == '*' ? lhs * rhs : lhs / rhs);
      } else {
        pass
          ..add(op)
          ..add(rhs);
      }
    }
    var acc = pass.first as _Rational;
    for (var i = 1; i < pass.length; i += 2) {
      final op = pass[i] as String;
      final rhs = pass[i + 1] as _Rational;
      acc = op == '+' ? acc + rhs : acc - rhs;
    }
    final minor = divideHalfEven(
      acc.num * BigInt.from(currency.factor),
      acc.den,
    );
    if (minor.abs() >= BigInt.from(kMaxMinorUnits)) {
      return const Err(AppFailure.validation('amount_too_large'));
    }
    return Ok(minor.toInt());
  }

  static _Rational? _number(String raw, Currency currency) {
    var s = raw;
    var neg = false;
    if (s.startsWith('-')) {
      neg = true;
      s = s.substring(1);
    } else if (s.startsWith('+')) {
      s = s.substring(1);
    }
    s = s.replaceAll(',', '.');
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(s) || s == '.' || s.isEmpty) {
      return null;
    }
    final parts = s.split('.');
    final intPart = parts[0].isEmpty ? '0' : parts[0];
    final frac = parts.length > 1 ? parts[1] : '';
    if (frac.length > 6 || intPart.length > 15) return null;
    final den = BigInt.from(10).pow(frac.length);
    var n = BigInt.parse(intPart) * den + (frac.isEmpty ? BigInt.zero : BigInt.parse(frac));
    if (neg) n = -n;
    return _Rational(n, den);
  }
}
