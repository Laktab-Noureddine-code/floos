import 'package:floos/core/money/currency.dart';
import 'package:floos/core/money/money.dart';
import 'package:intl/intl.dart';

/// Real minus sign (U+2212) used for negative amounts (design.md §0 #13).
const String kMinus = '−';

/// Mask shown when amounts are hidden.
const String kMask = '•••••';

/// Formatted amount split into display parts (for 50 %-opacity decimals).
class MoneyParts {
  const MoneyParts({
    required this.leading,
    required this.decimals,
    required this.trailing,
  });

  /// Sign + prefix symbol + integer part, e.g. `−$87,457`.
  final String leading;

  /// Decimal separator + fraction, e.g. `.85` (empty for 0-digit currencies).
  final String decimals;

  /// Suffix symbol, e.g. ` MAD` (empty if symbol is a prefix).
  final String trailing;

  String get full => '$leading$decimals$trailing';

  @override
  String toString() => full;
}

/// Locale-aware money formatting without ever converting to `double`.
class MoneyFormatter {
  const MoneyFormatter({required this.locale, this.westernDigits = true});

  final String locale;

  /// When false and locale is Arabic, digits are rendered as Arabic-Indic.
  final bool westernDigits;

  static const _arabicIndic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  String get _lang => locale.split(RegExp('[_-]')).first;

  bool get _symbolAlwaysAfter => _lang == 'fr' || _lang == 'ar';

  /// Splits a formatted amount into parts.
  MoneyParts split(
    int minor,
    Currency currency, {
    bool showPlus = false,
    bool showSymbol = true,
    bool showDecimals = true,
  }) {
    final symbols = NumberFormat.decimalPattern(locale).symbols;
    final negative = minor < 0;
    final abs = minor.abs();
    final factor = currency.factor;
    final intPart = abs ~/ factor;
    final fracPart = abs % factor;
    final grouped = NumberFormat('#,##0', locale).format(intPart);
    var decimals = '';
    if (currency.digits > 0 && showDecimals) {
      decimals =
          '${symbols.DECIMAL_SEP}${fracPart.toString().padLeft(currency.digits, '0')}';
    }
    final sign = negative ? kMinus : (showPlus && minor > 0 ? '+' : '');
    final before = showSymbol && currency.symbolBefore && !_symbolAlwaysAfter;
    final after = showSymbol && !before;
    final leading = '$sign${before ? currency.symbol : ''}$grouped';
    final trailing = after ? ' ${currency.symbol}' : '';
    return MoneyParts(
      leading: _digits(leading),
      decimals: _digits(decimals),
      trailing: trailing,
    );
  }

  /// Full formatted string, e.g. `−$354.25` or `−354,25 MAD`.
  String format(
    int minor,
    Currency currency, {
    bool showPlus = false,
    bool showSymbol = true,
    bool showDecimals = true,
  }) => split(
    minor,
    currency,
    showPlus: showPlus,
    showSymbol: showSymbol,
    showDecimals: showDecimals,
  ).full;

  String formatMoney(Money m, {bool showPlus = false}) =>
      format(m.minor, m.currency, showPlus: showPlus);

  /// Compact form without decimals, for chart axes and chips (e.g. `1,640`).
  String compact(int minor, Currency currency) =>
      format(minor, currency, showDecimals: false);

  /// Percent formatting with sign option, e.g. `+12%` / `−6%`.
  String percent(int value, {bool signed = false}) {
    final sign = value < 0 ? kMinus : (signed && value > 0 ? '+' : '');
    return _digits('$sign${value.abs()}%');
  }

  /// Plain decimal for CSV/export: point separator, no grouping.
  static String plain(int minor, Currency currency) {
    final negative = minor < 0;
    final abs = minor.abs();
    if (currency.digits == 0) return '${negative ? '-' : ''}$abs';
    final f = currency.factor;
    final s =
        '${abs ~/ f}.${(abs % f).toString().padLeft(currency.digits, '0')}';
    return negative ? '-$s' : s;
  }

  /// Integer + minor parts for screen-reader labels.
  static (int major, int minor) spoken(int minor, Currency currency) {
    final abs = minor.abs();
    return (abs ~/ currency.factor, abs % currency.factor);
  }

  String _digits(String s) {
    if (_lang != 'ar' || westernDigits) {
      return s.replaceAllMapped(
        RegExp('[٠-٩]'),
        (m) => '${_arabicIndic.indexOf(m[0]!)}',
      );
    }
    return s.replaceAllMapped(
      RegExp('[0-9]'),
      (m) => _arabicIndic[int.parse(m[0]!)],
    );
  }
}
