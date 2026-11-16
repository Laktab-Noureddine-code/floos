import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/amount_input_parser.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/data/repositories/goals_repository.dart';
import 'package:floos/features/common/form_fields.dart';
import 'package:floos/features/common/pickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Create / edit a goal.
class GoalFormScreen extends ConsumerStatefulWidget {
  const GoalFormScreen({super.key, this.goalId});

  final String? goalId;

  @override
  ConsumerState<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends ConsumerState<GoalFormScreen> {
  final _name = TextEditingController();
  final _target = TextEditingController();
  late LocalDay _start = ref.read(todayProvider);
  LocalDay? _deadline;
  String _mode = 'manual';
  String? _account;
  String _icon = 'target';
  String _color = 'purple';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.goalId == null) {
      _loaded = true;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final g = await ref.read(goalsRepoProvider).byId(widget.goalId!);
    if (g == null || !mounted) return;
    final cur = ref.read(baseCurrencyProvider);
    setState(() {
      _name.text = g.name;
      _target.text = editableAmount(g.targetAmount, cur.digits, cur.factor);
      _start = LocalDay.fromStorage(g.startDate);
      _deadline = g.deadline == null ? null : LocalDay.fromStorage(g.deadline!);
      _mode = g.trackingMode;
      _account = g.linkedAccountId;
      _icon = g.icon;
      _color = g.color;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amt = AmountInputParser.parse(_target.text, ref.read(baseCurrencyProvider));
    if (amt.isErr) return showFailure(context, amt.failureOrNull);
    final r = await ref
        .read(goalsRepoProvider)
        .save(
          GoalDraft(
            id: widget.goalId,
            name: _name.text.trim(),
            target: amt.valueOrNull!,
            start: _start,
            deadline: _deadline,
            trackingMode: _mode,
            linkedAccountId: _mode == 'linked' ? _account : null,
            icon: _icon,
            color: _color,
          ),
        );
    if (!mounted) return;
    if (r.isErr) return showFailure(context, r.failureOrNull);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (!_loaded) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    final accounts = {for (final a in ref.watch(accountsStreamProvider).value ?? const []) a.id: a.name};
    return Scaffold(
      appBar: AppBar(title: Text(widget.goalId == null ? l.goalNew : l.goalEdit)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: [
          TextField(controller: _name, maxLength: 40, decoration: InputDecoration(labelText: l.name)),
          TextField(
            controller: _target,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l.goalTarget, suffixText: ref.watch(baseCurrencyProvider).code),
          ),
          const SizedBox(height: AppSpace.md),
          DateField(label: l.goalStart, day: _start, onChanged: (d) => setState(() => _start = d)),
          const SizedBox(height: AppSpace.sm),
          DateField(label: l.goalDeadline, day: _deadline, onChanged: (d) => setState(() => _deadline = d), onClear: () => setState(() => _deadline = null)),
          const SizedBox(height: AppSpace.md),
          SegmentedButton<String>(
            segments: [ButtonSegment(value: 'manual', label: Text(l.goalTrackManual)), ButtonSegment(value: 'linked', label: Text(l.goalTrackLinked))],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          if (_mode == 'linked') ...[
            const SizedBox(height: AppSpace.sm),
            AppCard(
              onTap: () async {
                final id = await pickAccount(context, selectedId: _account);
                if (id != null) setState(() => _account = id);
              },
              child: Text('${l.goalLinkedAccount} · ${accounts[_account] ?? l.none}', style: context.text.bodyM),
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          IconColorField(icon: _icon, color: _color, onIcon: (v) => setState(() => _icon = v), onColor: (v) => setState(() => _color = v)),
          const SizedBox(height: AppSpace.x2),
          PrimaryButton(label: l.save, onPressed: _save),
        ],
      ),
    );
  }
}
