import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/amount_input_parser.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/data/repositories/budgets_repository.dart';
import 'package:floos/features/common/form_fields.dart';
import 'package:floos/features/common/pickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Create / edit a budget.
class BudgetFormScreen extends ConsumerStatefulWidget {
  const BudgetFormScreen({super.key, this.budgetId});

  final String? budgetId;

  @override
  ConsumerState<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends ConsumerState<BudgetFormScreen> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  String? _categoryId;
  bool _includeSub = true;
  String _period = 'monthly';
  bool _rollover = false;
  bool _alerts = true;
  LocalDay? _start;
  LocalDay? _end;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.budgetId == null) {
      _loaded = true;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final b = await ref.read(budgetsRepoProvider).byId(widget.budgetId!);
    if (b == null || !mounted) return;
    final cur = ref.read(baseCurrencyProvider);
    setState(() {
      _name.text = b.name;
      _amount.text = editableAmount(b.amount, cur.digits, cur.factor);
      _categoryId = b.categoryId;
      _includeSub = b.includeSubcategories;
      _period = b.period;
      _rollover = b.rollover;
      _alerts = b.alertThresholds != '[]';
      _start = b.customStart == null ? null : LocalDay.fromStorage(b.customStart!);
      _end = b.customEnd == null ? null : LocalDay.fromStorage(b.customEnd!);
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amt = AmountInputParser.parse(_amount.text, ref.read(baseCurrencyProvider));
    if (amt.isErr) return showFailure(context, amt.failureOrNull);
    final r = await ref
        .read(budgetsRepoProvider)
        .save(
          BudgetDraft(
            id: widget.budgetId,
            name: _name.text,
            categoryId: _categoryId,
            includeSubcategories: _includeSub,
            amount: amt.valueOrNull!,
            period: _period,
            customStart: _period == 'custom' ? _start : null,
            customEnd: _period == 'custom' ? _end : null,
            rollover: _rollover && _period != 'custom',
            thresholds: _alerts ? const [80, 100] : const [],
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
    final cats = ref.watch(categoriesMapProvider);
    final base = ref.watch(baseCurrencyProvider);
    final labels = {'weekly': l.periodWeek, 'monthly': l.periodMonth, 'yearly': l.periodYear, 'custom': l.periodCustom};
    return Scaffold(
      appBar: AppBar(title: Text(widget.budgetId == null ? l.planNewBudget : l.budgetEdit)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: [
          TextField(controller: _name, maxLength: 40, decoration: InputDecoration(labelText: l.budgetName)),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l.amount, suffixText: base.code),
          ),
          const SizedBox(height: AppSpace.md),
          AppCard(
            onTap: () async {
              final id = await pickCategory(context, kind: 'expense', parentsOnly: false);
              if (id != null) setState(() => _categoryId = id);
            },
            child: Row(
              children: [
                Expanded(child: Text('${l.budgetCategory} · ${_categoryId == null ? l.budgetAllCategories : cats[_categoryId]?.name ?? ''}', style: context.text.bodyM)),
                if (_categoryId != null) IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(() => _categoryId = null)),
              ],
            ),
          ),
          if (_categoryId != null)
            SwitchRow(label: l.budgetIncludeSub, value: _includeSub, onChanged: (v) => setState(() => _includeSub = v)),
          const SizedBox(height: AppSpace.md),
          SegmentedButton<String>(
            segments: [for (final e in labels.entries) ButtonSegment(value: e.key, label: Text(e.value))],
            selected: {_period},
            onSelectionChanged: (s) => setState(() => _period = s.first),
          ),
          if (_period == 'custom') ...[
            const SizedBox(height: AppSpace.md),
            DateField(label: l.start, day: _start, onChanged: (d) => setState(() => _start = d)),
            const SizedBox(height: AppSpace.sm),
            DateField(label: l.end, day: _end, onChanged: (d) => setState(() => _end = d)),
          ] else
            SwitchRow(label: l.budgetRollover, value: _rollover, onChanged: (v) => setState(() => _rollover = v)),
          SwitchRow(label: l.budgetThresholds, value: _alerts, onChanged: (v) => setState(() => _alerts = v)),
          const SizedBox(height: AppSpace.lg),
          PrimaryButton(label: l.save, onPressed: _save),
        ],
      ),
    );
  }
}
