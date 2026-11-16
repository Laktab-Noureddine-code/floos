import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/money_text.dart';
import 'package:floos/core/widgets/states.dart';
import 'package:floos/data/repositories/accounts_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

String accountTypeLabel(AppLocalizations l, String t) => switch (t) {
  'cash' => l.accountTypeCash,
  'bank' => l.accountTypeBank,
  'card' => l.accountTypeCard,
  'savings' => l.accountTypeSavings,
  'ewallet' => l.accountTypeEwallet,
  _ => l.accountTypeOther,
};

/// Accounts list: reorder, archived section, total per currency.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(accountsWithBalanceProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.accounts),
        actions: [IconButton(tooltip: l.add, icon: const Icon(Icons.add_rounded), onPressed: () => context.push('/accounts/new'))],
      ),
      body: AsyncValueView<List<AccountWithBalance>>(
        value: async,
        data: (all) {
          if (all.isEmpty) {
            return EmptyState(
              illustration: Illustration.wallet,
              message: l.accountsEmpty,
              actionLabel: l.accountNew,
              onAction: () => context.push('/accounts/new'),
            );
          }
          final active = all.where((a) => !a.account.archived).toList();
          final archived = all.where((a) => a.account.archived).toList();
          final totals = <String, int>{};
          for (final a in active.where((a) => a.account.includeInTotal)) {
            totals[a.account.currencyCode] = (totals[a.account.currencyCode] ?? 0) + a.balance;
          }
          Widget tile(AccountWithBalance a, {Key? key}) => Padding(
            key: key,
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: AppCard(
              onTap: () => context.push('/accounts/${a.account.id}'),
              child: Row(
                children: [
                  IconTile.keyed(a.account.icon, a.account.color),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.account.name, style: context.text.bodyM),
                        Text(accountTypeLabel(l, a.account.type), style: context.text.caption),
                      ],
                    ),
                  ),
                  MoneyText(a.balance, a.currency, style: context.text.bodyM.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSpace.x4),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.accountTotalBalance, style: context.text.caption),
                    for (final e in totals.entries)
                      MoneyText(e.value, Currencies.of(e.key), style: context.text.titleL),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: true,
                onReorder: (o, n) async {
                  final ids = active.map((a) => a.account.id).toList();
                  final id = ids.removeAt(o);
                  ids.insert(n > o ? n - 1 : n, id);
                  await ref.read(accountsRepoProvider).reorder([...ids, ...archived.map((a) => a.account.id)]);
                },
                children: [for (final a in active) tile(a, key: ValueKey(a.account.id))],
              ),
              if (archived.isNotEmpty) ...[
                const SizedBox(height: AppSpace.lg),
                Text(l.accountArchivedSection, style: context.text.caption),
                const SizedBox(height: AppSpace.sm),
                for (final a in archived) tile(a),
              ],
            ],
          );
        },
      ),
    );
  }
}
