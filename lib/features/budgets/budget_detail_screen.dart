import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/utils/formatters.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/charts.dart';
import 'package:floos/core/widgets/money_text.dart';
import 'package:floos/core/widgets/progress.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/core/widgets/states.dart';
import 'package:floos/domain/services/budget_service.dart';
import 'package:floos/features/budgets/budgets_screen.dart';
import 'package:floos/features/common/budget_style.dart';
import 'package:floos/features/plan/plan_providers.dart';
import 'package:floos/features/transactions/tx_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Budget detail: ring status, projection, cumulative line, history, list.
class BudgetDetailScreen extends ConsumerWidget {
  const BudgetDetailScreen({required this.budgetId, super.key});

  final String budgetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final base = ref.watch(baseCurrencyProvider);
    final today = ref.watch(todayProvider);
    final views = ref.watch(budgetViewsProvider).value;
    if (views == null) return Scaffold(appBar: AppBar(), body: const LoadingView());
    final v = views.where((v) => v.row.id == budgetId).firstOrNull;
    if (v == null) return Scaffold(appBar: AppBar(), body: const LoadingView());
    final s = v.status;
    final color = budgetColor(context, s.level);
    final fmt = ref.watch(formatterProvider);
    final cum = BudgetService.cumulative(s.period, v.daily, today);
    return Scaffold(
      appBar: AppBar(
        title: Text(budgetTitle(l, v)),
        actions: [
          IconButton(tooltip: l.edit, icon: const Icon(Icons.edit_outlined), onPressed: () => context.push('/budgets/$budgetId/edit')),
          IconButton(
            tooltip: l.delete,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              if (!await confirmDialog(context, title: l.delete, message: l.budgetDeleteConfirm, danger: true, confirmLabel: l.delete)) return;
              await ref.read(budgetsRepoProvider).delete(budgetId);
              if (context.mounted) context.pop();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: [
          Center(child: RingProgress(percent: s.percent, color: color, size: 140)),
          const SizedBox(height: AppSpace.md),
          Center(child: Text(Fmt.period(s.period), style: context.text.caption)),
          const SizedBox(height: AppSpace.lg),
          AppCard(
            child: Column(
              children: [
                _row(context, l.budgetSpent, MoneyText(s.spent, base, style: context.text.bodyM)),
                _row(context, s.remaining >= 0 ? l.budgetLeft : l.budgetOverBy, MoneyText(s.remaining.abs(), base, style: context.text.bodyM.copyWith(color: s.remaining < 0 ? context.colors.danger : null))),
                if (s.rolloverIn != 0) _row(context, l.budgetRollover, Text(fmt.format(s.rolloverIn, base), style: context.text.bodyM)),
                _row(context, l.budgetPerDay(fmt.format(s.remainingPerDay, base)), const SizedBox.shrink()),
                _row(context, l.budgetProjected(fmt.format(s.projected, base)), const SizedBox.shrink()),
                _row(context, l.budgetDaysLeft(s.daysLeft), const SizedBox.shrink()),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          AppCard(
            child: LinesChart(
              series: [
                LineSeries(points: [for (var i = 0; i < cum.length; i++) (i.toDouble(), cum[i])], color: color, filled: true),
                LineSeries(points: [(0, s.available), ((cum.length - 1).clamp(0, 1 << 20).toDouble(), s.available)], color: context.colors.textTertiary, dashed: true),
              ],
              bottomLabel: (x) => '${x.round() + 1}',
              maxX: (cum.length - 1).clamp(1, 1 << 20).toDouble(),
            ),
          ),
          if (v.history.isNotEmpty) ...[
            const SizedBox(height: AppSpace.lg),
            Text(l.budgetHistory, style: context.text.titleM),
            const SizedBox(height: AppSpace.sm),
            AppCard(
              child: BarsChart(
                groups: [for (final h in v.history) BarGroup(label: Fmt.monthShort(h.$1.start), values: [h.$2])],
                colors: [color],
                limits: [for (final h in v.history) h.$3],
                limitColor: context.colors.textTertiary,
              ),
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          Text(l.budgetTransactions, style: context.text.titleM),
          const SizedBox(height: AppSpace.sm),
          FutureBuilder(
            future: ref.read(budgetsRepoProvider).filterFor(v),
            builder: (context, snap) => snap.data == null
                ? const SizedBox.shrink()
                : StreamBuilder(
                    stream: ref.watch(transactionsRepoProvider).watch(snap.data!, limit: 50),
                    builder: (context, s2) => GroupedTxList(items: s2.data ?? const []),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, Widget value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
    child: Row(children: [Expanded(child: Text(label, style: context.text.bodyS)), value]),
  );
}
