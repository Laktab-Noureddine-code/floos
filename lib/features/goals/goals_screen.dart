import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/money_text.dart';
import 'package:floos/core/widgets/progress.dart';
import 'package:floos/core/widgets/states.dart';
import 'package:floos/data/repositories/goals_repository.dart';
import 'package:floos/domain/services/goal_service.dart';
import 'package:floos/features/plan/plan_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Color goalColor(BuildContext context, GoalState s) => switch (s) {
  GoalState.completed => context.colors.income,
  GoalState.behind => context.colors.warning,
  _ => context.colors.primary,
};

String goalStateLabel(AppLocalizations l, GoalStatus s) => switch (s.state) {
  GoalState.completed => l.goalCompletedLabel,
  GoalState.behind => l.goalBehind(s.behindPct ?? 0),
  GoalState.onTrack => l.goalOnTrack,
  GoalState.noDeadline => l.goalNoDeadline,
};

/// Goal card (carousel + list).
class GoalCard extends ConsumerWidget {
  const GoalCard({required this.view, super.key, this.width});

  final GoalView view;
  final double? width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final base = ref.watch(baseCurrencyProvider);
    final s = view.status;
    final color = goalColor(context, s.state);
    return SizedBox(
      width: width,
      child: AppCard(
        onTap: () => context.push('/goals/${view.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTile.keyed(view.row.icon, view.row.color, small: true),
                const SizedBox(width: AppSpace.sm),
                Expanded(child: Text(view.row.name, style: context.text.bodyM, overflow: TextOverflow.ellipsis)),
                Text('${s.percent} %', style: context.text.bodyM.copyWith(color: color, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            LinearProgress(value: s.barFraction, color: color, semanticPercent: s.percent),
            const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                MoneyText(s.saved, base, style: context.text.caption),
                Text(' / ', style: context.text.caption),
                MoneyText(view.row.targetAmount, base, style: context.text.caption),
              ],
            ),
            Text(goalStateLabel(l, s), style: context.text.caption.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

/// Goals list (active, completed, archived).
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.planGoals),
        actions: [IconButton(tooltip: l.add, icon: const Icon(Icons.add_rounded), onPressed: () => context.push('/goals/new'))],
      ),
      body: AsyncValueView<List<GoalView>>(
        value: ref.watch(goalViewsProvider),
        data: (all) {
          final shown = all.where((g) => g.row.status != 'archived').toList()
            ..sort((a, b) => a.row.priority.compareTo(b.row.priority));
          if (shown.isEmpty) {
            return EmptyState(illustration: Illustration.goals, message: l.goalsEmpty, actionLabel: l.planNewGoal, onAction: () => context.push('/goals/new'));
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpace.screen),
            children: [for (final g in shown) Padding(padding: const EdgeInsets.only(bottom: AppSpace.sm), child: GoalCard(view: g))],
          );
        },
      ),
    );
  }
}
