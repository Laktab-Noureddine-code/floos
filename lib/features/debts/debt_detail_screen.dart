import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/amount_input_parser.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/utils/formatters.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/money_text.dart';
import 'package:floos/core/widgets/progress.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/core/widgets/states.dart';
import 'package:floos/data/repositories/debts_repository.dart';
import 'package:floos/features/common/form_fields.dart';
import 'package:floos/features/common/pickers.dart';
import 'package:floos/features/plan/plan_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Debt detail: remaining, payments, add payment, settle, delete.
class DebtDetailScreen extends ConsumerWidget {
  const DebtDetailScreen({required this.debtId, super.key});

  final String debtId;

  Future<void> _addPayment(BuildContext context, WidgetRef ref, DebtView v) async {
    final l = context.l10n;
    final c = TextEditingController();
    String? account;
    var recordOnly = false;
    final ok = await showAppSheet<bool>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.debtAddPayment, style: ctx.text.titleM),
              TextField(
                controller: c,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l.amount, suffixText: v.row.currencyCode),
              ),
              SwitchRow(label: l.debtRecordOnly, value: recordOnly, onChanged: (x) => set(() => recordOnly = x)),
              if (!recordOnly)
                ListTile(
                  title: Text(account == null ? l.txChooseAccount : '${l.account} ✓'),
                  onTap: () async {
                    final id = await pickAccount(ctx);
                    if (id != null) set(() => account = id);
                  },
                ),
              const SizedBox(height: AppSpace.md),
              PrimaryButton(label: l.confirm, onPressed: () => Navigator.pop(ctx, true)),
            ],
          ),
        ),
      ),
    );
    final text = c.text;
    c.dispose();
    if (ok != true || !context.mounted) return;
    final amt = AmountInputParser.parse(text, v.currency);
    if (amt.isErr) return showFailure(context, amt.failureOrNull);
    final r = await ref
        .read(debtsRepoProvider)
        .addPayment(v.id, amt.valueOrNull!, ref.read(todayProvider), accountId: recordOnly ? null : account, fx: ref.read(fxProvider));
    if (context.mounted && r.isErr) showFailure(context, r.failureOrNull);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final v = ref.watch(debtViewsProvider).value?.where((d) => d.id == debtId).firstOrNull;
    if (v == null) return Scaffold(appBar: AppBar(), body: const LoadingView());
    final repo = ref.read(debtsRepoProvider);
    final s = v.status;
    final settled = v.row.status == 'settled';
    return Scaffold(
      appBar: AppBar(
        title: Text(v.row.personName),
        actions: [
          IconButton(tooltip: l.edit, icon: const Icon(Icons.edit_outlined), onPressed: () => context.push('/debts/$debtId/edit')),
          IconButton(
            tooltip: l.delete,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              if (!await confirmDialog(context, title: l.delete, message: l.debtDeleteConfirm, danger: true, confirmLabel: l.delete)) return;
              await repo.delete(debtId);
              if (context.mounted) context.pop();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.row.direction == 'i_owe' ? l.debtIOwe : l.debtOwedToMe, style: context.text.caption),
                MoneyText(s.remaining, v.currency, style: context.text.displayM),
                const SizedBox(height: AppSpace.sm),
                LinearProgress(value: s.percentPaid / 100, color: context.colors.primary, semanticPercent: s.percentPaid),
                const SizedBox(height: AppSpace.sm),
                Row(
                  children: [
                    Text('${l.debtPaid} ', style: context.text.caption),
                    MoneyText(s.paid, v.currency, style: context.text.caption),
                    Text(' / ', style: context.text.caption),
                    MoneyText(v.row.originalAmount, v.currency, style: context.text.caption),
                  ],
                ),
                if (settled) Text(l.debtSettled, style: context.text.caption.copyWith(color: context.colors.income)),
                if (s.overdue) Text(l.debtOverdue, style: context.text.caption.copyWith(color: context.colors.danger)),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              if (!settled) Expanded(child: PrimaryButton(label: l.debtAddPayment, onPressed: () => _addPayment(context, ref, v))),
              if (!settled) const SizedBox(width: AppSpace.md),
              Expanded(
                child: PrimaryButton(
                  label: settled ? l.debtReopen : l.debtSettle,
                  secondary: true,
                  onPressed: () => repo.setSettled(v.id, settled: !settled),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Text(l.debtPayments, style: context.text.titleM),
          for (final p in v.payments)
            ListTile(
              title: MoneyText(p.amount, v.currency, style: context.text.bodyM),
              subtitle: Text(Fmt.mediumDay(p.day)),
              trailing: p.recordOnly
                  ? IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: () => repo.deleteRecordOnlyPayment(p.id))
                  : null,
            ),
        ],
      ),
    );
  }
}
