import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/money/money_formatter.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Formats money respecting `hide_amounts` (as plain strings).
extension MoneyRefX on WidgetRef {
  String money(int minor, Currency currency, {bool showPlus = false, bool decimals = true}) {
    if (watch(hideAmountsProvider)) return kMask;
    return watch(formatterProvider).format(minor, currency, showPlus: showPlus, showDecimals: decimals);
  }
}

/// Spoken label for screen readers, e.g. "moins 354 dirhams 25".
String spokenAmount(AppLocalizations l, int minor, Currency c) {
  final (major, cents) = MoneyFormatter.spoken(minor, c);
  final sign = minor < 0 ? '${l.a11yMinus} ' : '';
  return c.digits == 0 || cents == 0
      ? '$sign$major ${c.code}'
      : '$sign$major ${c.code} $cents';
}

/// Amount with decimals at 50 % opacity (design.md §7.4), tabular figures,
/// real minus sign, masked when amounts are hidden.
class MoneyText extends ConsumerWidget {
  const MoneyText(
    this.minor,
    this.currency, {
    super.key,
    this.style,
    this.showPlus = false,
    this.dimDecimals = true,
    this.colorBySign = false,
    this.textAlign,
    this.forceShow = false,
  });

  final int minor;
  final Currency currency;
  final TextStyle? style;
  final bool showPlus;
  final bool dimDecimals;

  /// Use income/expense colours for positive/negative amounts.
  final bool colorBySign;
  final TextAlign? textAlign;
  final bool forceShow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = style ?? context.text.bodyM;
    final color = colorBySign
        ? (minor < 0 ? context.colors.expense : (minor > 0 && showPlus ? context.colors.income : base.color))
        : base.color;
    final s = base.copyWith(color: color);
    final hidden = ref.watch(hideAmountsProvider) && !forceShow;
    final label = hidden ? context.l10n.a11yHiddenAmount : spokenAmount(context.l10n, minor, currency);
    if (hidden) {
      return Semantics(
        label: label,
        excludeSemantics: true,
        child: Text(kMask, style: s, textAlign: textAlign, maxLines: 1),
      );
    }
    final parts = ref.watch(formatterProvider).split(minor, currency, showPlus: showPlus);
    final dim = s.copyWith(color: (s.color ?? context.colors.textPrimary).withValues(alpha: AppOpacity.decimals));
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: parts.leading),
            TextSpan(text: parts.decimals, style: dimDecimals ? dim : null),
            TextSpan(text: parts.trailing),
          ],
        ),
        style: s,
        textAlign: textAlign,
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
      ),
    );
  }
}

/// Signed transaction amount: −354,25 (expense), +12 (income), transfer neutral.
class TxAmountText extends StatelessWidget {
  const TxAmountText({required this.type, required this.amount, required this.currency, super.key, this.style});

  final String type;
  final int amount;
  final Currency currency;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final s = (style ?? context.text.bodyM).copyWith(
      fontWeight: FontWeight.w700,
      color: switch (type) {
        'expense' => context.colors.expense,
        'income' => context.colors.income,
        _ => context.colors.textPrimary,
      },
    );
    return MoneyText(
      type == 'expense' ? -amount : amount,
      currency,
      showPlus: type == 'income',
      style: s,
      dimDecimals: false,
    );
  }
}
