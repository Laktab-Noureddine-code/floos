import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/amount_input_parser.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/utils/formatters.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/charts.dart';
import 'package:floos/core/widgets/money_text.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/core/widgets/states.dart';
import 'package:floos/data/repositories/accounts_repository.dart';
import 'package:floos/data/repositories/transactions_repository.dart';
import 'package:floos/features/accounts/accounts_screen.dart';
import 'package:floos/features/common/form_fields.dart';
import 'package:floos/features/common/pickers.dart';
import 'package:floos/features/transactions/tx_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Account detail: balance, 6-month chart, reconcile, archive, delete.
class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({required this.accountId, super.key});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final list = ref.watch(accountsWithBalanceProvider).value ?? const <AccountWithBalance>[];
    final matches = list.where((a) => a.account.id == accountId);
    if (matches.isEmpty) return Scaffold(appBar: AppBar(), body: const LoadingView());
    final a = matches.first;
    final acc = a.account;
    return Scaffold(
      appBar: AppBar(
        title: Text(acc.name),
        actions: [
          IconButton(tooltip: l.edit, icon: const Icon(Icons.edit_outlined), onPressed: () => context.push('/accounts/$accountId/edit')),
          PopupMenuButton<String>(
            onSelected: (v) => _action(context, ref, v, a),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'reconcile', child: Text(l.accountReconcile)),
              PopupMenuItem(value: 'archive', child: Text(acc.archived ? l.unarchive : l.archive)),
              PopupMenuItem(value: 'delete', child: Text(l.delete)),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: [
          AppCard(
            child: Row(
              children: [
                IconTile.keyed(acc.icon, acc.color),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(accountTypeLabel(l, acc.type), style: context.text.caption),
                      MoneyText(a.balance, a.currency, style: context.text.displayM),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(l.accountBalanceHistory, style: context.text.titleM),
          const SizedBox(height: AppSpace.sm),
          _History(account: a),
          const SizedBox(height: AppSpace.lg),
          Text(l.accountTransactions, style: context.text.titleM),
          const SizedBox(height: AppSpace.sm),
          StreamBuilder<List<TxView>>(
            stream: ref.watch(transactionsRepoProvider).watch(TxFilter(accountIds: {accountId}), limit: 30),
            builder: (context, snap) => GroupedTxList(items: snap.data ?? const []),
          ),
        ],
      ),
    );
  }

  Future<void> _action(BuildContext context, WidgetRef ref, String v, AccountWithBalance a) async {
    final l = context.l10n;
    final repo = ref.read(accountsRepoProvider);
    switch (v) {
      case 'archive':
        await repo.setArchived(a.account.id, archived: !a.account.archived);
      case 'reconcile':
        final c = TextEditingController();
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l.accountReconcile),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.accountReconcileBody),
                TextField(
                  controller: c,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: InputDecoration(labelText: l.accountRealBalance, suffixText: a.account.currencyCode),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.confirm)),
            ],
          ),
        );
        if (ok != true || !context.mounted) return;
        final real = AmountInputParser.parse(c.text, a.currency, allowNegative: true);
        c.dispose();
        if (real.isErr) return showFailure(context, real.failureOrNull);
        final r = await ref
            .read(transactionsRepoProvider)
            .reconcile(a.account.id, a.balance, real.valueOrNull!, ref.read(todayProvider));
        if (!context.mounted) return;
        if (r.isErr) return showFailure(context, r.failureOrNull);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.accountReconciled)));
      case 'delete':
        final n = await repo.transactionCount(a.account.id);
        if (!context.mounted) return;
        if (n == 0) {
          if (!await confirmDialog(context, title: l.accountDeleteTitle, message: a.account.name, danger: true, confirmLabel: l.delete)) return;
          final r = await repo.delete(a.account.id);
          if (!context.mounted) return;
          if (r.isErr) return showFailure(context, r.failureOrNull);
          context.pop();
          return;
        }
        final choice = await showAppSheet<String>(
          context,
          builder: (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetTitle(l.accountDeleteTitle),
              Padding(padding: const EdgeInsets.all(AppSpace.lg), child: Text(l.accountDeleteBody(n))),
              ListTile(title: Text(l.accountMoveTo), onTap: () => Navigator.pop(ctx, 'move')),
              ListTile(
                title: Text(l.accountDeleteAll, style: TextStyle(color: ctx.colors.expense)),
                onTap: () => Navigator.pop(ctx, 'all'),
              ),
              const SizedBox(height: AppSpace.lg),
            ],
          ),
        );
        if (choice == null || !context.mounted) return;
        AccountDeletion? d;
        if (choice == 'move') {
          final id = await pickAccount(context, excludeId: a.account.id);
          if (id == null) return;
          d = MoveTransactionsTo(id);
        } else {
          d = const DeleteTransactions();
        }
        final r = await repo.delete(a.account.id, deletion: d);
        if (!context.mounted) return;
        if (r.isErr) return showFailure(context, r.failureOrNull);
        context.pop();
    }
  }
}

class _History extends ConsumerWidget {
  const _History({required this.account});

  final AccountWithBalance account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final repo = ref.watch(accountsRepoProvider);
    final months = [for (var i = 5; i >= 0; i--) LocalDay(today.year, today.month, 1).addMonths(-i)];
    return FutureBuilder<List<int>>(
      future: Future.wait([
        for (final m in months) repo.balanceOf(account.account.id, m.addMonths(1).addDays(-1) > today ? today : m.addMonths(1).addDays(-1)),
      ]),
      builder: (context, snap) {
        final v = snap.data;
        if (v == null) return const SizedBox(height: AppSizes.chartHeight);
        return AppCard(
          child: LinesChart(
            series: [
              LineSeries(points: [for (var i = 0; i < v.length; i++) (i.toDouble(), v[i])], color: context.colors.primary, filled: true),
            ],
            bottomLabel: (x) => Fmt.monthShort(months[x.round().clamp(0, 5)]),
            maxX: 5,
          ),
        );
      },
    );
  }
}
