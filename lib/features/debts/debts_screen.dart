import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/utils/formatters.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/money_text.dart';
import 'package:floos/core/widgets/progress.dart';
import 'package:floos/core/widgets/states.dart';
import 'package:floos/data/repositories/debts_repository.dart';
import 'package:floos/features/plan/plan_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Debt card (list + plan tab).
class DebtCard extends StatelessWidget {
  const DebtCard({required this.view, super.key});

  final DebtView view;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = view.status;
    final owe = view.row.direction == 'i_owe';
    final color = s.overdue ? context.colors.danger : (owe ? context.colors.expense : context.colors.income);
    return AppCard(
      onTap: () => context.push('/debts/${view.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(view.row.personName, style: context.text.bodyM)),
              if (s.overdue) Text(l.debtOverdue, style: context.text.caption.copyWith(color: context.colors.danger)),
              const SizedBox(width: AppSpace.sm),
              MoneyText(s.remaining, view.currency, style: context.text.bodyM.copyWith(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          LinearProgress(value: s.percentPaid / 100, color: color, semanticPercent: s.percentPaid),
          if (view.row.dueDate != null)
            Text('${l.debtDue} · ${Fmt.mediumDay(LocalDay.fromStorage(view.row.dueDate!))}', style: context.text.caption),
        ],
      ),
    );
  }
}

/// Debts & loans: tabs "I owe" / "Owed to me", open vs settled.
class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  bool _settled = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.planDebts),
          bottom: TabBar(tabs: [Tab(text: l.debtIOwe), Tab(text: l.debtOwedToMe)]),
          actions: [IconButton(tooltip: l.add, icon: const Icon(Icons.add_rounded), onPressed: () => context.push('/debts/new'))],
        ),
        body: AsyncValueView<List<DebtView>>(
          value: ref.watch(debtViewsProvider),
          data: (all) {
            if (all.isEmpty) {
              return EmptyState(illustration: Illustration.debts, message: l.debtsEmpty, actionLabel: l.planNewDebt, onAction: () => context.push('/debts/new'));
            }
            Widget list(String dir) {
              final items = all.where((d) => d.row.direction == dir && (d.row.status == 'settled') == _settled).toList();
              return ListView(
                padding: const EdgeInsets.all(AppSpace.screen),
                children: [
                  SegmentedButton<bool>(
                    segments: [ButtonSegment(value: false, label: Text(l.debtOpenTab)), ButtonSegment(value: true, label: Text(l.debtSettledTab))],
                    selected: {_settled},
                    onSelectionChanged: (s) => setState(() => _settled = s.first),
                  ),
                  const SizedBox(height: AppSpace.md),
                  for (final d in items) Padding(padding: const EdgeInsets.only(bottom: AppSpace.sm), child: DebtCard(view: d)),
                ],
              );
            }

            return TabBarView(children: [list('i_owe'), list('owed_to_me')]);
          },
        ),
      ),
    );
  }
}
