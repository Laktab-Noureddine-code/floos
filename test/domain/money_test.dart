import 'package:floos/core/money/amount_input_parser.dart';
import 'package:floos/core/money/calculator.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/money/money.dart';
import 'package:floos/core/money/money_formatter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  final mad = Currencies.of('MAD');
  final usd = Currencies.of('USD');
  final jpy = Currencies.of('JPY');
  final kwd = Currencies.of('KWD');

  setUpAll(() async => initializeDateFormatting());

  group('Money', () {
    test('adds and subtracts same currency', () {
      expect(const Money(150, Currency(code: 'MAD', symbol: 'MAD', digits: 2, name: 'x')) + Money(50, mad), Money(200, mad));
      expect(Money(150, mad) - Money(200, mad), Money(-50, mad));
      expect(Money(0, mad).isZero, isTrue);
      expect(Money(-1, mad).isNegative, isTrue);
      expect(-Money(5, mad), Money(-5, mad));
      expect(Money(-5, mad).abs(), Money(5, mad));
    });

    test('mixing currencies throws', () {
      expect(() => Money(1, mad) + Money(1, usd), throwsA(isA<CurrencyMismatchError>()));
      expect(() => Money(1, mad).compareTo(Money(1, usd)), throwsA(isA<CurrencyMismatchError>()));
    });

    test('comparisons', () {
      expect(Money(1, mad) < Money(2, mad), isTrue);
      expect(Money(2, mad) >= Money(2, mad), isTrue);
      expect(Money(3, mad) > Money(2, mad), isTrue);
      expect(Money(2, mad) <= Money(1, mad), isFalse);
    });

    test('ratio multiplication uses banker rounding', () {
      expect(Money(5, mad).timesRatio(1, 2), Money(2, mad)); // 2.5 -> 2
      expect(Money(15, mad).timesRatio(1, 10), Money(2, mad)); // 1.5 -> 2
      expect(Money(25, mad).timesRatio(1, 10), Money(2, mad)); // 2.5 -> 2
      expect(Money(-25, mad).timesRatio(1, 10), Money(-2, mad));
      expect(Money(26, mad).timesRatio(1, 10), Money(3, mad));
    });

    test('divideHalfEven edge cases', () {
      expect(divideHalfEvenInt(7, 2), 4);
      expect(divideHalfEvenInt(5, 2), 2);
      expect(divideHalfEvenInt(-7, 2), -4);
      expect(divideHalfEvenInt(7, -2), -4);
      expect(() => divideHalfEven(BigInt.one, BigInt.zero), throwsArgumentError);
    });
  });

  group('Currencies', () {
    test('digits table', () {
      expect(jpy.digits, 0);
      expect(kwd.digits, 3);
      expect(mad.digits, 2);
      expect(Currencies.of('XXX').digits, 2);
      expect(Currencies.isKnown('XXX'), isFalse);
    });

    test('ordered pins common currencies first and filters', () {
      final list = Currencies.ordered();
      expect(list.take(8).map((c) => c.code), Currencies.pinned);
      expect(Currencies.ordered(query: 'yen').single.code, 'JPY');
      expect(Currencies.ordered(query: 'zzz'), isEmpty);
    });
  });

  group('MoneyFormatter', () {
    const en = MoneyFormatter(locale: 'en');
    const fr = MoneyFormatter(locale: 'fr');
    const ar = MoneyFormatter(locale: 'ar');
    const arIndic = MoneyFormatter(locale: 'ar', westernDigits: false);

    test('en uses prefix symbol, grouping and real minus', () {
      expect(en.format(-35425, usd), '−\$354.25');
      expect(en.format(8745785, usd), '\$87,457.85');
      expect(en.format(1200, usd, showPlus: true), '+\$12.00');
      expect(en.format(0, usd), '\$0.00');
    });

    test('fr uses comma decimals and suffix symbol', () {
      final s = fr.format(-123456, mad);
      expect(s.startsWith('−'), isTrue);
      expect(s.contains(',56'), isTrue);
      expect(s.endsWith('MAD'), isTrue);
    });

    test('ar formats with western digits by default and arabic-indic when off', () {
      expect(ar.format(12345, mad).contains('123'), isTrue);
      expect(arIndic.format(12345, mad).contains('١٢٣'), isTrue);
    });

    test('split exposes decimals separately', () {
      final parts = en.split(8745785, usd);
      expect(parts.leading, '\$87,457');
      expect(parts.decimals, '.85');
      expect(parts.trailing, '');
      final jp = en.split(1500, jpy);
      expect(jp.decimals, '');
      final m = en.split(100, mad);
      expect(m.trailing.trim(), 'MAD');
    });

    test('plain export format', () {
      expect(MoneyFormatter.plain(35425, usd), '354.25');
      expect(MoneyFormatter.plain(-5, usd), '-0.05');
      expect(MoneyFormatter.plain(1200, jpy), '1200');
      expect(MoneyFormatter.plain(1234, kwd), '1.234');
    });

    test('percent and compact', () {
      expect(en.percent(12, signed: true), '+12%');
      expect(en.percent(-6), '−6%');
      expect(en.compact(164000, usd), '\$1,640');
      expect(MoneyFormatter.spoken(-35425, usd), (354, 25));
    });
  });

  group('AmountInputParser', () {
    test('accepts common formats', () {
      expect(AmountInputParser.parse('1234.5', usd).requireValue, 123450);
      expect(AmountInputParser.parse('1 234,50', usd).requireValue, 123450);
      expect(AmountInputParser.parse('1,234.50', usd).requireValue, 123450);
      expect(AmountInputParser.parse('1.234,50', usd).requireValue, 123450);
      expect(AmountInputParser.parse('1,234,567', usd).requireValue, 123456700);
      expect(AmountInputParser.parse('12,5', usd).requireValue, 1250);
      expect(AmountInputParser.parse('١٢٣', usd).requireValue, 12300);
      expect(AmountInputParser.parse('١٢٣٫٥', usd).requireValue, 12350);
      expect(AmountInputParser.parse('.5', usd).requireValue, 50);
      expect(AmountInputParser.parse('+3', usd).requireValue, 300);
    });

    test('rejects invalid input', () {
      expect(AmountInputParser.parse('', usd).failureOrNull?.code, 'amount_empty');
      expect(AmountInputParser.parse('1.234', usd).requireValue, 123400);
      expect(AmountInputParser.parse('1.2345', usd).failureOrNull?.code, 'amount_too_many_decimals');
      expect(AmountInputParser.parse('12.5', jpy).failureOrNull?.code, 'amount_too_many_decimals');
      expect(AmountInputParser.parse('abc', usd).failureOrNull?.code, 'amount_invalid');
      expect(AmountInputParser.parse('-5', usd).failureOrNull?.code, 'amount_negative');
      expect(AmountInputParser.parse('-5', usd, allowNegative: true).requireValue, -500);
      expect(AmountInputParser.parse('1,2,3', usd).failureOrNull?.code, 'amount_invalid');
      expect(AmountInputParser.parse('1.2,3.4', usd).failureOrNull?.code, 'amount_invalid');
      expect(AmountInputParser.parse('100000000000', usd).failureOrNull?.code, 'amount_too_large');
      expect(AmountInputParser.parse('9999999999999999', usd).failureOrNull?.code, 'amount_too_large');
    });

    test('three-decimal currency keeps 3 digits', () {
      expect(AmountInputParser.parse('1.234', kwd).requireValue, 1234);
    });
  });

  group('Calculator', () {
    test('evaluates with precedence', () {
      expect(Calculator.evaluate('45+12.5', usd).requireValue, 5750);
      expect(Calculator.evaluate('2×7−1', usd).requireValue, 1300);
      expect(Calculator.evaluate('100÷3', usd).requireValue, 3333);
      expect(Calculator.evaluate('10-2*3', usd).requireValue, 400);
      expect(Calculator.evaluate('1/8', usd).requireValue, 12); // 12.5 -> 12
      expect(Calculator.evaluate('3/8', usd).requireValue, 38); // 37.5 -> 38
      expect(Calculator.evaluate('45+', usd).requireValue, 4500);
      expect(Calculator.evaluate('١٠+٥', usd).requireValue, 1500);
    });

    test('zero, negative, invalid and huge (edge cases 9 and 10)', () {
      expect(Calculator.evaluate('5-5', usd).requireValue, 0);
      expect(Calculator.evaluate('5-10', usd).requireValue, -500);
      expect(Calculator.evaluate('1/0', usd).failureOrNull?.code, 'amount_division_zero');
      expect(Calculator.evaluate('', usd).failureOrNull?.code, 'amount_empty');
      expect(Calculator.evaluate('*5', usd).failureOrNull?.code, 'amount_invalid');
      expect(Calculator.evaluate('1..2', usd).failureOrNull?.code, 'amount_invalid');
      expect(Calculator.evaluate('99999999999*99', usd).failureOrNull?.code, 'amount_too_large');
      expect(Calculator.hasOperator('45+1'), isTrue);
      expect(Calculator.hasOperator('-45'), isFalse);
    });
  });
}
