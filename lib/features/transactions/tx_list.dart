import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/core/widgets/transaction_tile.dart';
import 'package:floos/data/repositories/transactions_repository.dart';
import 'package:floos/features/transaction_form/transaction_form_sheet.dart';
import 'package:floos/features/transaction_form/tx_form_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Running balance (account currency, incl. initial) per transaction id.
final runningBalancesProvider = FutureProvider.family<Map<String, int>, String>((ref, key) async {
  ref.watch(txTickProvider);
  final ids = key.split(',').where((s) => s.isNotEmpty).toSet();
  if (ids.isEmpty) return const {};
  final repo = ref.watch(transactionsRepoProvider);
  final views = await repo.get(TxFilter(ids: ids, includePending: true));
  final accounts = {for (final v in views) v.tx.accountId};
  final flows = await repo.runningFlows(accounts, ids);
  final initial = {for (final a in await ref.watch(accountsRepoProvider).getAll()) a.id: a.initialBalance};
  return {
    for (final v in views)
      if (flows[v.tx.id] != null) v.tx.id: (initial[v.tx.accountId] ?? 0) + flows[v.tx.id]!,
  };
});

/// Deletes a transaction with an Undo SnackBar (UX law 6.2).
Future<void> deleteWithUndo(BuildContext context, WidgetRef ref, List<String> ids) async {
  final l = context.l10n;
  final repo = ref.read(transactionsRepoProvider);
  final snaps = (await repo.deleteMany(ids)).valueOrNull ?? const <TxSnapshot>[];
  await Haptics.light();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(ids.length == 1 ? l.deleted : l.deletedCount(ids.length)),
      duration: AppMotion.undo,
      action: SnackBarAction(label: l.undo, onPressed: () => repo.restore(snaps)),
    )).closed.then((r) {
      if (r != SnackBarClosedReason.action) repo.finalizeDelete(snaps);
    });
}

/// Groups [items] by local day with day headers and tiles (non-scrolling).
class GroupedTxList extends ConsumerWidget {
  const GroupedTxList({
    required this.items,
    super.key,
    this.showRunningBalance = true,
    this.selection,
    this.onToggleSelect,
  });

  final List<TxView> items;
  final bool showRunningBalance;
  final Set<String>? selection;
  final ValueChanged<String>? onToggleSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final base = ref.watch(baseCurrencyProvider);
    final fx = ref.watch(fxProvider);
    final balances = showRunningBalance
        ? ref.watch(runningBalancesProvider(items.map((e) => e.tx.id).join(','))).value ?? const {}
        : const <String, int>{};
    final groups = <LocalDay, List<TxView>>{};
    for (final v in items) {
      groups.putIfAbsent(LocalDay.fromStorage(v.tx.date), () => []).add(v);
    }
    final selecting = selection != null && selection!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final e in groups.entries) ...[
          DateGroupHeader(
            day: e.key,
            currency: base,
            total: e.value.fold<int>(0, (a, v) {
              if (v.tx.type == 'transfer' || v.tx.isPending) return a;
              final conv = fx.convertMinor(v.tx.amount, v.accountCurrency, base.code, e.key).valueOrNull ?? 0;
              return a + (v.tx.type == 'income' ? conv : -conv);
            }),
          ),
          for (final v in e.value)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.cardGap),
              child: TransactionTile(
                view: v,
                today: today,
                runningBalance: balances[v.tx.id],
                selectionMode: selecting,
                selected: selection?.contains(v.tx.id) ?? false,
                onTap: selecting
                    ? () => onToggleSelect?.call(v.tx.id)
                    : () => openTransactionForm(context, args: TxFormArgs(editId: v.tx.id)),
                onLongPress: onToggleSelect == null ? null : () => onToggleSelect!(v.tx.id),
                onEdit: () => openTransactionForm(context, args: TxFormArgs(editId: v.tx.id)),
                onDelete: () => deleteWithUndo(context, ref, [v.tx.id]),
              ),
            ),
        ],
      ],
    );
  }
}

/// Currency helper for views.
Currency currencyOfView(TxView v) => Currencies.of(v.accountCurrency);
