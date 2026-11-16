import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/money_text.dart';
import 'package:floos/core/widgets/progress.dart';
import 'package:floos/core/widgets/states.dart';
import 'package:floos/data/repositories/budgets_repository.dart';
import 'package:floos/features/common/budget_style.dart';
import 'package:floos/features/plan/plan_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

String budgetTitle(AppLocalizations l, BudgetView v) =>
    v.row.name.isNotEmpty ? v.row.name : (v.category?.name ?? l.budgetOverall);

/// One budget card (list + plan tab).
class BudgetCard extends ConsumerWidget {
  const BudgetCard({required this.view, super.key});

  final BudgetView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = view.status;
    final base = ref.watch(baseCurrencyProvider);
    final color = budgetColor(context, s.level);
    return AppCard(
      onTap: () => context.push('/budgets/${view.row.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (view.category != null) ...[IconTile.keyed(view.category!.icon, view.category!.color, small: true), const SizedBox(width: AppSpace.sm)],
              Expanded(child: Text(budgetTitle(l, view), style: context.text.bodyM)),
              Text('${s.percent} %', style: context.text.bodyM.copyWith(color: color, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          LinearProgress(value: s.progressPermille / 1000, color: color, semanticPercent: s.percent),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              MoneyText(s.spent, base, style: context.text.caption),
              Text(' / ', style: context.text.caption),
              MoneyText(s.available, base, style: context.text.caption),
              const Spacer(),
              if (s.remaining >= 0) Text('${l.budgetLeft} ', style: context.text.caption) else Text('${l.budgetOverBy} ', style: context.text.caption),
              MoneyText(s.remaining.abs(), base, style: context.text.caption.copyWith(color: s.remaining < 0 ? context.colors.danger : null)),
            ],
          ),
        ],
      ),
    );
  }
}

/// All budgets.
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.planBudgets),
        actions: [IconButton(tooltip: l.add, icon: const Icon(Icons.add_rounded), onPressed: () => context.push('/budgets/new'))],
      ),
      body: AsyncValueView<List<BudgetView>>(
        value: ref.watch(budgetViewsProvider),
        data: (list) {
          final active = list.where((v) => !v.row.archived).toList();
          if (active.isEmpty) {
            return EmptyState(illustration: Illustration.budgets, message: l.budgetsEmpty, actionLabel: l.planNewBudget, onAction: () => context.push('/budgets/new'));
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpace.screen),
            children: [
              for (final v in active) Padding(padding: const EdgeInsets.only(bottom: AppSpace.sm), child: BudgetCard(view: v)),
            ],
          );
        },
      ),
    );
  }
}
