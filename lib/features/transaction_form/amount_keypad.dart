import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/calculator.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// In-app calculator keypad: digits, `,`, `+ − × ÷`, backspace
/// (APP_PROMPT §6.4). Edits an expression string; evaluated on save.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({required this.onKey, required this.onBackspace, super.key, this.onClear});

  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback? onClear;

  static const decimal = ',';

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['7', '8', '9', '÷'],
      ['4', '5', '6', '×'],
      ['1', '2', '3', '−'],
      [decimal, '0', '⌫', '+'],
    ];
    return Container(
      color: context.colors.background,
      padding: const EdgeInsets.all(AppSpace.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final r in rows)
            Row(
              children: [
                for (final k in r)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpace.xs),
                      child: _Key(
                        label: k,
                        isOperator: Calculator.operators.contains(k),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          k == '⌫' ? onBackspace() : onKey(k);
                        },
                        onLongPress: k == '⌫' ? onClear : null,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.isOperator, required this.onTap, this.onLongPress});

  final String label;
  final bool isOperator;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final back = label == '⌫';
    return Semantics(
      button: true,
      label: back ? context.l10n.a11yBackspace : label,
      excludeSemantics: true,
      child: Material(
        color: isOperator ? c.primaryTint : c.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          onLongPress: onLongPress,
          child: SizedBox(
            height: AppSizes.keypadKeyHeight,
            child: Center(
              child: back
                  ? Icon(PhosphorIconsRegular.backspace, color: c.textPrimary)
                  : Text(
                      label,
                      style: context.text.amountM.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isOperator ? c.primary : c.textPrimary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Applies a keypad key to an expression with sane rules (one decimal per
/// operand, no double operators, max decimals per currency).
String applyKey(String expr, String key, {required int maxDecimals}) {
  final isOp = Calculator.operators.contains(key);
  if (isOp) {
    if (expr.isEmpty) return key == '−' ? key : expr;
    final last = expr[expr.length - 1];
    if (Calculator.operators.contains(last) || last == AmountKeypad.decimal) {
      return expr.substring(0, expr.length - 1) + key;
    }
    return expr + key;
  }
  final operand = expr.split(RegExp('[+−×÷]')).last;
  if (key == AmountKeypad.decimal) {
    if (maxDecimals == 0 || operand.contains(AmountKeypad.decimal)) return expr;
    return expr + (operand.isEmpty ? '0$key' : key);
  }
  if (operand.contains(AmountKeypad.decimal) && operand.split(AmountKeypad.decimal).last.length >= maxDecimals) {
    return expr;
  }
  if (operand == '0') return expr.substring(0, expr.length - 1) + key;
  if (operand.replaceAll(AmountKeypad.decimal, '').length >= 13) return expr;
  return expr + key;
}
