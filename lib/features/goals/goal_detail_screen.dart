import 'dart:math' as math;

import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/amount_input_parser.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/utils/formatters.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/money_text.dart';
import 'package:floos/core/widgets/progress.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/core/widgets/states.dart';
import 'package:floos/data/repositories/goals_repository.dart';
import 'package:floos/features/common/form_fields.dart';
import 'package:floos/features/common/pickers.dart';
import 'package:floos/features/goals/goals_screen.dart';
import 'package:floos/features/plan/plan_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Goal detail: progress, stats, contributions, contribute/withdraw, status.
class GoalDetailScreen extends ConsumerStatefulWidget {
  const GoalDetailScreen({required this.goalId, super.key});

  final String goalId;

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _confetti = AnimationController(vsync: this, duration: const Duration(seconds: 2));
  bool _celebrated = false;

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _contribute(GoalView v, {required bool withdraw}) async {
    final l = context.l10n;
    final base = ref.read(baseCurrencyProvider);
    final c = TextEditingController();
    String? fromAccount;
    final ok = await showAppSheet<bool>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(withdraw ? l.goalWithdraw : l.goalContribute, style: ctx.text.titleM),
              TextField(
                controller: c,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l.goalAmountField, suffixText: base.code),
              ),
              if (!withdraw && v.row.linkedAccountId != null && v.row.trackingMode == 'linked')
                ListTile(
                  title: Text(fromAccount == null ? l.goalFromAccount : '${l.goalFromAccount} ✓'),
                  onTap: () async {
                    final id = await pickAccount(ctx);
                    if (id != null) set(() => fromAccount = id);
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
    if (ok != true || !mounted) return;
    final amt = AmountInputParser.parse(text, base);
    if (amt.isErr) return showFailure(context, amt.failureOrNull);
    final r = await ref
        .read(goalsRepoProvider)
        .contribute(v.id, withdraw ? -amt.valueOrNull! : amt.valueOrNull!, ref.read(todayProvider), fromAccountId: fromAccount);
    if (mounted && r.isErr) showFailure(context, r.failureOrNull);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final base = ref.watch(baseCurrencyProvider);
    final fmt = ref.watch(formatterProvider);
    final views = ref.watch(goalViewsProvider).value;
    final v = views?.where((g) => g.id == widget.goalId).firstOrNull;
    if (v == null) return Scaffold(appBar: AppBar(), body: const LoadingView());
    final s = v.status;
    final repo = ref.read(goalsRepoProvider);
    final color = goalColor(context, s.state);
    if (s.isCompleted && !v.row.celebrated && !_celebrated) {
      _celebrated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confetti.forward(from: 0);
        repo.markCelebrated(v.id);
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(v.row.name),
        actions: [
          IconButton(tooltip: l.edit, icon: const Icon(Icons.edit_outlined), onPressed: () => context.push('/goals/${v.id}/edit')),
          PopupMenuButton<String>(
            onSelected: (a) async {
              switch (a) {
                case 'complete':
                  await repo.setStatus(v.id, 'completed');
                case 'reactivate':
                  await repo.setStatus(v.id, 'active');
                case 'archive':
                  await repo.setStatus(v.id, v.row.status == 'archived' ? 'active' : 'archived');
                case 'delete':
                  if (await confirmDialog(context, title: l.delete, message: l.goalDeleteConfirm, danger: true, confirmLabel: l.delete)) {
                    await repo.delete(v.id);
                    if (mounted) context.pop();
                  }
              }
            },
            itemBuilder: (_) => [
              if (s.isCompleted) PopupMenuItem(value: 'reactivate', child: Text(l.goalReactivate)) else PopupMenuItem(value: 'complete', child: Text(l.goalMarkComplete)),
              PopupMenuItem(value: 'archive', child: Text(v.row.status == 'archived' ? l.unarchive : l.archive)),
              PopupMenuItem(value: 'delete', child: Text(l.delete)),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(AppSpace.screen),
            children: [
              if (s.isCompleted)
                Container(
                  padding: const EdgeInsets.all(AppSpace.md),
                  decoration: BoxDecoration(color: context.colors.successTint, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Text(l.goalCelebrate, style: context.text.bodyM, textAlign: TextAlign.center),
                ),
              const SizedBox(height: AppSpace.md),
              Center(child: RingProgress(percent: s.percent.clamp(0, 100), color: color, size: 140)),
              const SizedBox(height: AppSpace.lg),
              AppCard(
                child: Column(
                  children: [
                    _kv(context, l.goalSaved, MoneyText(s.saved, base, style: context.text.bodyM)),
                    _kv(context, l.goalTarget, MoneyText(v.row.targetAmount, base, style: context.text.bodyM)),
                    _kv(context, l.goalRemaining, MoneyText(s.remaining, base, style: context.text.bodyM)),
                    if (v.row.deadline != null) _kv(context, l.goalDeadline, Text(Fmt.mediumDay(LocalDay.fromStorage(v.row.deadline!)), style: context.text.bodyM)),
                    if (s.neededPerMonth != null && !s.isCompleted)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpace.sm),
                        child: Text(l.goalNeeded(fmt.format(s.neededPerMonth!, base)), style: context.text.caption),
                      ),
                    if (s.estimatedCompletion != null && !s.isCompleted)
                      Text(l.goalEstimated(Fmt.monthYear(s.estimatedCompletion!)), style: context.text.caption),
                    Text(goalStateLabel(l, s), style: context.text.caption.copyWith(color: color)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.md),
              if (v.row.status != 'archived')
                Row(
                  children: [
                    Expanded(child: PrimaryButton(label: l.goalContribute, onPressed: () => _contribute(v, withdraw: false))),
                    const SizedBox(width: AppSpace.md),
                    Expanded(child: PrimaryButton(label: l.goalWithdraw, secondary: true, onPressed: () => _contribute(v, withdraw: true))),
                  ],
                ),
              const SizedBox(height: AppSpace.lg),
              Text(l.goalContributions, style: context.text.titleM),
              for (final c in v.contributions)
                Dismissible(
                  key: ValueKey(c.id),
                  background: Container(color: context.colors.expense),
                  onDismissed: (_) => repo.deleteContribution(c.id),
                  child: ListTile(
                    title: MoneyText(c.amount, base, showPlus: true, colorBySign: true, style: context.text.bodyM),
                    subtitle: Text(Fmt.mediumDay(LocalDay.fromStorage(c.date))),
                    trailing: c.note == null ? null : Text(c.note!, style: context.text.caption),
                  ),
                ),
            ],
          ),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _confetti,
              builder: (_, _) => CustomPaint(painter: _ConfettiPainter(_confetti.value), size: Size.infinite),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, Widget v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
    child: Row(children: [Expanded(child: Text(k, style: context.text.bodyS)), v]),
  );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);

  final double t;
  static const _colors = [Color(0xFF9C6CF6), Color(0xFF38C775), Color(0xFFFE7503), Color(0xFF229FFC), Color(0xFFF0384D)];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final rnd = math.Random(7);
    for (var i = 0; i < 60; i++) {
      final x = rnd.nextDouble() * size.width;
      final speed = 0.6 + rnd.nextDouble() * 0.8;
      final y = (t * speed * size.height * 1.2) - 40;
      final p = Paint()..color = _colors[i % _colors.length].withValues(alpha: 1 - t);
      canvas
        ..save()
        ..translate(x + math.sin(t * 8 + i) * 12, y)
        ..rotate(t * 10 + i)
        ..drawRect(const Rect.fromLTWH(-4, -2, 8, 4), p)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
