import 'package:floos/core/money/currency.dart';
import 'package:floos/core/money/money.dart';
import 'package:floos/core/utils/result.dart';

/// Parses user-typed amounts into minor units without using `double`.
///
/// Accepts `1234.5`, `1 234,50`, `1,234.50`, `1.234,50`, Arabic-Indic digits
/// (`١٢٣`) and the Arabic decimal separator `٫`. Rejects more decimals than
/// the currency allows.
abstract final class AmountInputParser {
  static const _arabicIndic = '٠١٢٣٤٥٦٧٨٩';
  static const _easternArabic = '۰۱۲۳۴۵۶۷۸۹';

  /// Converts Arabic-Indic / Persian digits and separators to ASCII.
  static String normalizeDigits(String input) {
    final b = StringBuffer();
    for (final ch in input.runes.map(String.fromCharCode)) {
      final i = _arabicIndic.indexOf(ch);
      final j = _easternArabic.indexOf(ch);
      if (i >= 0) {
        b.write(i);
      } else if (j >= 0) {
        b.write(j);
      } else if (ch == '٫') {
        b.write('.');
      } else if (ch == '٬') {
        b.write(',');
      } else {
        b.write(ch);
      }
    }
    return b.toString();
  }

  /// Parses [input] for [currency]. Negative values allowed if [allowNegative].
  static Result<int> parse(
    String input,
    Currency currency, {
    bool allowNegative = false,
  }) {
    var s = normalizeDigits(input.trim())
        .replaceAll(RegExp(r'[\s   ' "']"), '')
        .replaceAll('−', '-');
    if (s.isEmpty) return const Err(AppFailure.validation('amount_empty'));
    var negative = false;
    if (s.startsWith('-')) {
      negative = true;
      s = s.substring(1);
    } else if (s.startsWith('+')) {
      s = s.substring(1);
    }
    if (negative && !allowNegative) {
      return const Err(AppFailure.validation('amount_negative'));
    }
    if (!RegExp(r'^[0-9.,]+$').hasMatch(s)) {
      return const Err(AppFailure.validation('amount_invalid'));
    }
    final lastDot = s.lastIndexOf('.');
    final lastComma = s.lastIndexOf(',');
    String intPart;
    var fracPart = '';
    if (lastDot >= 0 && lastComma >= 0) {
      // Both present: the last one is the decimal separator.
      final decIdx = lastDot > lastComma ? lastDot : lastComma;
      final group = lastDot > lastComma ? ',' : '.';
      intPart = s.substring(0, decIdx).replaceAll(group, '');
      fracPart = s.substring(decIdx + 1);
      if (intPart.contains(RegExp('[.,]')) || fracPart.contains(RegExp('[.,]'))) {
        return const Err(AppFailure.validation('amount_invalid'));
      }
    } else if (lastDot >= 0 || lastComma >= 0) {
      final sep = lastDot >= 0 ? '.' : ',';
      final count = sep.allMatches(s).length;
      final idx = s.lastIndexOf(sep);
      final after = s.length - idx - 1;
      if (count > 1) {
        // Repeated separator = grouping (e.g. 1,234,567).
        if (!_validGrouping(s, sep)) {
          return const Err(AppFailure.validation('amount_invalid'));
        }
        intPart = s.replaceAll(sep, '');
      } else if (after == 3 && currency.digits != 3 && idx > 0 && idx <= 3) {
        // Single separator followed by exactly 3 digits → grouping.
        intPart = s.replaceAll(sep, '');
      } else {
        intPart = s.substring(0, idx);
        fracPart = s.substring(idx + 1);
      }
    } else {
      intPart = s;
    }
    if (intPart.isEmpty) intPart = '0';
    if (fracPart.length > currency.digits) {
      return Err(
        AppFailure.validation('amount_too_many_decimals', args: {'digits': currency.digits}),
      );
    }
    if (intPart.length > 15) {
      return const Err(AppFailure.validation('amount_too_large'));
    }
    final major = int.parse(intPart);
    final frac = fracPart.isEmpty ? 0 : int.parse(fracPart.padRight(currency.digits, '0'));
    final minor = major * currency.factor + frac;
    if (minor >= kMaxMinorUnits) {
      return const Err(AppFailure.validation('amount_too_large'));
    }
    return Ok(negative ? -minor : minor);
  }

  static bool _validGrouping(String s, String sep) {
    final parts = s.split(sep);
    if (parts.first.isEmpty || parts.first.length > 3) return false;
    return parts.skip(1).every((p) => p.length == 3);
  }
}
