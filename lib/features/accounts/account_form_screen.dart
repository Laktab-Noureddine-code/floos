import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/amount_input_parser.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/data/repositories/accounts_repository.dart';
import 'package:floos/features/accounts/accounts_screen.dart';
import 'package:floos/features/common/form_fields.dart';
import 'package:floos/features/common/pickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Create / edit an account.
class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key, this.accountId});

  final String? accountId;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _name = TextEditingController();
  final _balance = TextEditingController(text: '0');
  String _type = 'bank';
  late String _currency = ref.read(prefsProvider).baseCurrency;
  String _icon = 'bank';
  String _color = 'purple';
  bool _include = true;
  bool _loaded = false;
  bool _currencyLocked = false;

  @override
  void initState() {
    super.initState();
    if (widget.accountId == null) {
      _loaded = true;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final repo = ref.read(accountsRepoProvider);
    final a = await repo.byId(widget.accountId!);
    if (a == null || !mounted) return;
    final n = await repo.transactionCount(a.id);
    setState(() {
      _name.text = a.name;
      _type = a.type;
      _currency = a.currencyCode;
      _icon = a.icon;
      _color = a.color;
      _include = a.includeInTotal;
      _balance.text = (a.initialBalance / Currencies.of(a.currencyCode).factor).toStringAsFixed(Currencies.of(a.currencyCode).digits);
      _currencyLocked = n > 0;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final bal = AmountInputParser.parse(_balance.text.isEmpty ? '0' : _balance.text, Currencies.of(_currency), allowNegative: true);
    if (bal.isErr) return showFailure(context, bal.failureOrNull);
    final r = await ref
        .read(accountsRepoProvider)
        .save(
          AccountDraft(
            id: widget.accountId,
            name: _name.text.trim(),
            type: _type,
            currencyCode: _currency,
            initialBalance: bal.valueOrNull ?? 0,
            color: _color,
            icon: _icon,
            includeInTotal: _include,
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
      appBar: AppBar(title: Text(widget.accountId == null ? l.accountNew : l.accountEdit)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: [
          TextField(controller: _name, maxLength: 40, decoration: InputDecoration(labelText: l.name)),
          const SizedBox(height: AppSpace.md),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: InputDecoration(labelText: l.type),
            items: [for (final t in accountTypes) DropdownMenuItem(value: t, child: Text(accountTypeLabel(l, t)))],
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: AppSpace.md),
          AppCard(
            onTap: _currencyLocked
                ? null
                : () async {
                    final c = await pickCurrency(context, selected: _currency);
                    if (c != null) setState(() => _currency = c);
                  },
            child: Row(
              children: [
                Expanded(child: Text('${l.currency} · $_currency', style: context.text.bodyM)),
                if (!_currencyLocked) const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          TextField(
            controller: _balance,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: InputDecoration(labelText: l.accountInitialBalance, suffixText: _currency),
          ),
          const SizedBox(height: AppSpace.lg),
          IconColorField(icon: _icon, color: _color, onIcon: (v) => setState(() => _icon = v), onColor: (v) => setState(() => _color = v)),
          SwitchRow(label: l.accountIncludeTotal, value: _include, onChanged: (v) => setState(() => _include = v)),
          const SizedBox(height: AppSpace.lg),
          PrimaryButton(label: l.save, onPressed: _save),
        ],
      ),
    );
  }
}
