import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/amount_input_parser.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/data/repositories/debts_repository.dart';
import 'package:floos/features/common/form_fields.dart';
import 'package:floos/features/common/pickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Create / edit a debt or loan.
class DebtFormScreen extends ConsumerStatefulWidget {
  const DebtFormScreen({super.key, this.debtId});

  final String? debtId;

  @override
  ConsumerState<DebtFormScreen> createState() => _DebtFormScreenState();
}

class _DebtFormScreenState extends ConsumerState<DebtFormScreen> {
  final _person = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _direction = 'i_owe';
  late String _currency = ref.read(prefsProvider).baseCurrency;
  late LocalDay _start = ref.read(todayProvider);
  LocalDay? _due;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.debtId == null) {
      _loaded = true;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final d = await ref.read(debtsRepoProvider).byId(widget.debtId!);
    if (d == null || !mounted) return;
    final cur = Currencies.of(d.currencyCode);
    setState(() {
      _person.text = d.personName;
      _amount.text = editableAmount(d.originalAmount, cur.digits, cur.factor);
      _note.text = d.note ?? '';
      _direction = d.direction;
      _currency = d.currencyCode;
      _start = LocalDay.fromStorage(d.startDate);
      _due = d.dueDate == null ? null : LocalDay.fromStorage(d.dueDate!);
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _person.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amt = AmountInputParser.parse(_amount.text, Currencies.of(_currency));
    if (amt.isErr) return showFailure(context, amt.failureOrNull);
    final r = await ref
        .read(debtsRepoProvider)
        .save(
          DebtDraft(
            id: widget.debtId,
            direction: _direction,
            personName: _person.text.trim(),
            amount: amt.valueOrNull!,
            currencyCode: _currency,
            start: _start,
            due: _due,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.debtId == null ? l.debtNew : l.debtEdit)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: [
          SegmentedButton<String>(
            segments: [ButtonSegment(value: 'i_owe', label: Text(l.debtIOwe)), ButtonSegment(value: 'owed_to_me', label: Text(l.debtOwedToMe))],
            selected: {_direction},
            onSelectionChanged: (s) => setState(() => _direction = s.first),
          ),
          const SizedBox(height: AppSpace.md),
          TextField(controller: _person, maxLength: 40, decoration: InputDecoration(labelText: l.debtPerson)),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l.debtAmountField, suffixText: _currency),
          ),
          const SizedBox(height: AppSpace.sm),
          AppCard(
            onTap: widget.debtId != null
                ? null
                : () async {
                    final c = await pickCurrency(context, selected: _currency);
                    if (c != null) setState(() => _currency = c);
                  },
            child: Text('${l.currency} · $_currency', style: context.text.bodyM),
          ),
          const SizedBox(height: AppSpace.sm),
          DateField(label: l.debtStart, day: _start, onChanged: (d) => setState(() => _start = d)),
          const SizedBox(height: AppSpace.sm),
          DateField(label: l.debtDue, day: _due, onChanged: (d) => setState(() => _due = d), onClear: () => setState(() => _due = null)),
          TextField(controller: _note, maxLength: 200, decoration: InputDecoration(labelText: l.note)),
          const SizedBox(height: AppSpace.lg),
          PrimaryButton(label: l.save, onPressed: _save),
        ],
      ),
    );
  }
}
