import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/amount_input_parser.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/money/money_formatter.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/utils/formatters.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/money_text.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/data/repositories/transactions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "Needs confirmation" card for pending recurring items (APP_PROMPT §5.7).
class PendingCard extends ConsumerWidget {
  const PendingCard({required this.items, super.key});

  final List<TxView> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return AppCard(
      color: context.colors.warningTint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.homeNeedsConfirmation, style: context.text.titleM),
          for (final v in items) ...[
            const SizedBox(height: AppSpace.md),
            Row(
              children: [
                IconTile.keyed(v.categoryIcon, v.categoryColor),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.tx.payee ?? v.categoryName ?? l.typeTransfer, style: context.text.bodyM, overflow: TextOverflow.ellipsis),
                      Text(Fmt.mediumDay(LocalDay.fromStorage(v.tx.date)), style: context.text.caption),
                    ],
                  ),
                ),
                TxAmountText(type: v.tx.type, amount: v.tx.amount, currency: Currencies.of(v.accountCurrency)),
              ],
            ),
            Wrap(
              spacing: AppSpace.sm,
              children: [
                TextButton(onPressed: () => _confirm(context, ref, v), child: Text(l.homeConfirm)),
                TextButton(
                  onPressed: () async {
                    await ref.read(transactionsRepoProvider).skipPending(v.tx.id);
                    await Haptics.light();
                  },
                  child: Text(l.homeSkip),
                ),
                if (v.tx.recurringRuleId != null)
                  TextButton(
                    onPressed: () => context.push('/recurring/${v.tx.recurringRuleId}/edit'),
                    child: Text(l.homeEditRule),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref, TxView v) async {
    final l = context.l10n;
    final c = Currencies.of(v.accountCurrency);
    final ctrl = TextEditingController(text: MoneyFormatter.plain(v.tx.amount, c).replaceAll('.', ','));
    String? error;
    final amount = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l.homeConfirm),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: '${l.homeConfirmAmount} (${c.code})', errorText: error),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            TextButton(
              onPressed: () {
                final r = AmountInputParser.parse(ctrl.text, c);
                r.fold(
                  (v) => v <= 0 ? setState(() => error = l.errAmountZero) : Navigator.pop(ctx, v),
                  (f) => setState(() => error = failureMessage(l, f)),
                );
              },
              child: Text(l.confirm),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    if (amount == null) return;
    await ref.read(transactionsRepoProvider).confirmPending(v.tx.id, amount: amount);
    await Haptics.light();
    if (context.mounted) Snack.show(context, l.saved);
  }
}
