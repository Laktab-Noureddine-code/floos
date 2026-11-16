import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/utils/formatters.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/data/repositories/recurring_repository.dart';
import 'package:floos/features/budgets/budgets_screen.dart';
import 'package:floos/features/debts/debts_screen.dart';
import 'package:floos/features/goals/goals_screen.dart';
import 'package:floos/features/plan/plan_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// "My Plan" tab (design.md §4.3): goals, budgets, recurring, debts.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  Future<void> _chooser(BuildContext context) async {
    final l = context.l10n;
    final route = await showAppSheet<String>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetTitle(l.planAddTitle),
          for (final (label, path, icon) in [
            (l.planNewBudget, '/budgets/new', PhosphorIconsRegular.chartPieSlice),
            (l.planNewGoal, '/goals/new', PhosphorIconsRegular.target),
            (l.planNewRecurring, '/recurring/new', PhosphorIconsRegular.arrowsClockwise),
            (l.planNewDebt, '/debts/new', PhosphorIconsRegular.handCoins),
          ])
            ListTile(leading: Icon(icon), title: Text(label), onTap: () => Navigator.pop(ctx, path)),
          const SizedBox(height: AppSpace.lg),
        ],
      ),
    );
    if (route != null && context.mounted) await context.push(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final goals = (ref.watch(goalViewsProvider).value ?? const []).where((g) => g.row.status == 'active').toList();
    final budgets = (ref.watch(budgetViewsProvider).value ?? const []).where((b) => !b.row.archived).toList();
    final rules = (ref.watch(recurringStreamProvider).value ?? const []).where((r) => r.active).toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    final debts = (ref.watch(debtViewsProvider).value ?? const []).where((d) => d.row.status == 'open').toList();
    final cats = ref.watch(categoriesMapProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.planTitle),
        actions: [IconButton(tooltip: l.add, icon: const Icon(Icons.add_circle_outline_rounded), onPressed: () => _chooser(context))],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSizes.scrollBottomPadding),
        children: [
          SectionHeader(title: l.planGoals, actionLabel: l.viewAll, onAction: () => context.push('/goals')),
          if (goals.isEmpty)
            _empty(context, l.goalsEmpty, () => context.push('/goals/new'))
          else
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: goals.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpace.sm),
                itemBuilder: (_, i) => GoalCard(view: goals[i], width: 240),
              ),
            ),
          const SizedBox(height: AppSpace.lg),
          SectionHeader(title: l.planBudgets, actionLabel: l.viewAll, onAction: () => context.push('/budgets')),
          if (budgets.isEmpty)
            _empty(context, l.budgetsEmpty, () => context.push('/budgets/new'))
          else
            for (final b in budgets.take(3)) Padding(padding: const EdgeInsets.only(bottom: AppSpace.sm), child: BudgetCard(view: b)),
          const SizedBox(height: AppSpace.lg),
          SectionHeader(title: l.planRecurring, actionLabel: l.viewAll, onAction: () => context.push('/recurring')),
          if (rules.isEmpty)
            _empty(context, l.recurringEmpty, () => context.push('/recurring/new'))
          else
            for (final r in rules.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: AppCard(
                  onTap: () => context.push('/recurring/${r.id}/edit'),
                  child: Row(
                    children: [
                      IconTile.keyed(cats[r.templateCategoryId]?.icon, cats[r.templateCategoryId]?.color, small: true),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Text(
                          RecurringRepository.displayName(r).isEmpty ? (cats[r.templateCategoryId]?.name ?? '') : RecurringRepository.displayName(r),
                          style: context.text.bodyM,
                        ),
                      ),
                      Text(Fmt.shortDay(LocalDay.fromStorage(r.nextDueDate)), style: context.text.caption),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: AppSpace.lg),
          SectionHeader(title: l.planDebts, actionLabel: l.viewAll, onAction: () => context.push('/debts')),
          if (debts.isEmpty)
            _empty(context, l.debtsEmpty, () => context.push('/debts/new'))
          else
            for (final d in debts.take(3)) Padding(padding: const EdgeInsets.only(bottom: AppSpace.sm), child: DebtCard(view: d)),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context, String text, VoidCallback onTap) => AppCard(
    onTap: onTap,
    child: Row(
      children: [
        Expanded(child: Text(text, style: context.text.bodyS)),
        const Icon(Icons.add_rounded),
      ],
    ),
  );
}
