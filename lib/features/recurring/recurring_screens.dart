import 'dart:convert';

import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/amount_input_parser.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/utils/formatters.dart';
import 'package:floos/core/utils/result.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/money_text.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/core/widgets/states.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/repositories/recurring_repository.dart';
import 'package:floos/data/repositories/transactions_repository.dart';
import 'package:floos/domain/services/recurring_engine.dart';
import 'package:floos/features/common/form_fields.dart';
import 'package:floos/features/common/pickers.dart';
import 'package:floos/features/recurring/recurring_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Recurring rules & bills list.
class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cats = ref.watch(categoriesMapProvider);
    final repo = ref.read(recurringRepoProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.planRecurring),
        actions: [IconButton(tooltip: l.add, icon: const Icon(Icons.add_rounded), onPressed: () => context.push('/recurring/new'))],
      ),
      body: AsyncValueView<List<RecurringRuleRow>>(
        value: ref.watch(recurringStreamProvider),
        data: (rules) {
          if (rules.isEmpty) {
            return EmptyState(illustration: Illustration.recurring, message: l.recurringEmpty, actionLabel: l.planNewRecurring, onAction: () => context.push('/recurring/new'));
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpace.screen),
            children: [
              for (final r in rules)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
                  child: AppCard(
                    onTap: () => context.push('/recurring/${r.id}/edit'),
                    child: Row(
                      children: [
                        IconTile.keyed(cats[r.templateCategoryId]?.icon, cats[r.templateCategoryId]?.color),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                RecurringRepository.displayName(r).isEmpty ? (cats[r.templateCategoryId]?.name ?? l.typeTransfer) : RecurringRepository.displayName(r),
                                style: context.text.bodyM,
                              ),
                              Text(
                                r.active ? l.recurringNext(Fmt.mediumDay(LocalDay.fromStorage(r.nextDueDate))) : l.recurringPaused,
                                style: context.text.caption,
                              ),
                            ],
                          ),
                        ),
                        _Amount(rule: r),
                        PopupMenuButton<String>(
                          tooltip: l.a11yMoreActions,
                          onSelected: (v) async {
                            switch (v) {
                              case 'toggle':
                                await repo.setActive(r.id, active: !r.active);
                              case 'skip':
                                await repo.skipNext(r.id);
                              case 'delete':
                                final past = await showAppSheet<bool>(
                                  context,
                                  builder: (ctx) => Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SheetTitle(l.recurringDeleteTitle),
                                      ListTile(title: Text(l.recurringKeepPast), onTap: () => Navigator.pop(ctx, false)),
                                      ListTile(title: Text(l.recurringDeletePast, style: TextStyle(color: ctx.colors.expense)), onTap: () => Navigator.pop(ctx, true)),
                                      const SizedBox(height: AppSpace.lg),
                                    ],
                                  ),
                                );
                                if (past != null) await repo.delete(r.id, deletePast: past);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(value: 'toggle', child: Text(r.active ? l.pause : l.resume)),
                            PopupMenuItem(value: 'skip', child: Text(l.recurringSkipNext)),
                            PopupMenuItem(value: 'delete', child: Text(l.delete)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Amount extends ConsumerWidget {
  const _Amount({required this.rule});

  final RecurringRuleRow rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acc = ref.watch(accountsStreamProvider).value?.where((a) => a.id == rule.templateAccountId).firstOrNull;
    final cur = Currencies.of(acc?.currencyCode ?? ref.watch(prefsProvider).baseCurrency);
    return TxAmountText(type: rule.templateType, amount: rule.templateAmount, currency: cur, style: context.text.bodyM);
  }
}

/// Create / edit a recurring rule.
class RecurringFormScreen extends ConsumerStatefulWidget {
  const RecurringFormScreen({super.key, this.ruleId});

  final String? ruleId;

  @override
  ConsumerState<RecurringFormScreen> createState() => _RecurringFormScreenState();
}

class _RecurringFormScreenState extends ConsumerState<RecurringFormScreen> {
  final _amount = TextEditingController();
  final _payee = TextEditingController();
  final _note = TextEditingController();
  final _nameCtl = TextEditingController();
  String _type = 'expense';
  String? _account;
  String? _category;
  late LocalDay _start = ref.read(todayProvider);
  RecurringConfig _config = const RecurringConfig();
  List<String> _tagIds = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.ruleId == null) {
      _loaded = true;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final r = await ref.read(recurringRepoProvider).byId(widget.ruleId!);
    if (r == null || !mounted) return;
    final acc = await ref.read(accountsRepoProvider).byId(r.templateAccountId);
    final cur = Currencies.of(acc?.currencyCode ?? ref.read(prefsProvider).baseCurrency);
    setState(() {
      _type = r.templateType;
      _amount.text = editableAmount(r.templateAmount, cur.digits, cur.factor);
      _account = r.templateAccountId;
      _category = r.templateCategoryId;
      _payee.text = r.templatePayee ?? '';
      _note.text = r.templateNote ?? '';
      _tagIds = (jsonDecode(r.templateTagIds) as List).cast<String>();
      _start = LocalDay.fromStorage(r.startDate);
      _config = RecurringConfig(
        frequency: Frequency.values.byName(r.frequency),
        interval: r.interval,
        byWeekday: r.byWeekday,
        byMonthDay: r.byMonthDay,
        end: r.endDate == null ? null : LocalDay.fromStorage(r.endDate!),
        maxOccurrences: r.maxOccurrences,
        mode: r.mode,
        remindDaysBefore: r.remindDaysBefore,
        remindTimeMinutes: r.remindTimeMinutes,
        name: r.name,
      );
      _nameCtl.text = r.name ?? '';
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _amount.dispose();
    _payee.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final accounts = ref.read(accountsStreamProvider).value ?? const [];
    final accountId = _account ?? (accounts.isEmpty ? null : accounts.first.id);
    if (accountId == null) return showFailure(context, const AppFailure.validation('account_required'));
    final acc = accounts.firstWhere((a) => a.id == accountId);
    final amt = AmountInputParser.parse(_amount.text, Currencies.of(acc.currencyCode));
    if (amt.isErr) return showFailure(context, amt.failureOrNull);
    final c = _config;
    final r = await ref
        .read(recurringRepoProvider)
        .save(
          RecurringDraft(
            id: widget.ruleId,
            name: c.name,
            template: TxDraft(
              type: _type,
              amount: amt.valueOrNull!,
              accountId: accountId,
              categoryId: _category,
              day: _start,
              payee: _payee.text.trim().isEmpty ? null : _payee.text.trim(),
              note: _note.text.trim().isEmpty ? null : _note.text.trim(),
              tagIds: _tagIds,
            ),
            frequency: c.frequency,
            interval: c.interval,
            byWeekday: c.byWeekday,
            byMonthDay: c.byMonthDay,
            start: _start,
            end: c.end,
            maxOccurrences: c.maxOccurrences,
            mode: c.mode,
            remindDaysBefore: c.remindDaysBefore,
            remindTimeMinutes: c.remindTimeMinutes,
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
    final accounts = ref.watch(accountsStreamProvider).value ?? const <AccountRow>[];
    final cats = ref.watch(categoriesMapProvider);
    final accountId = _account ?? (accounts.isEmpty ? null : accounts.first.id);
    return Scaffold(
      appBar: AppBar(title: Text(widget.ruleId == null ? l.recurringNew : l.recurringEdit)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: [
          SegmentedButton<String>(
            segments: [ButtonSegment(value: 'expense', label: Text(l.typeExpense)), ButtonSegment(value: 'income', label: Text(l.typeIncome))],
            selected: {_type == 'transfer' ? 'expense' : _type},
            onSelectionChanged: (s) => setState(() {
              _type = s.first;
              _category = null;
            }),
          ),
          const SizedBox(height: AppSpace.md),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l.amount),
          ),
          const SizedBox(height: AppSpace.sm),
          AppCard(
            onTap: () async {
              final id = await pickAccount(context, selectedId: accountId);
              if (id != null) setState(() => _account = id);
            },
            child: Text('${l.account} · ${accounts.where((a) => a.id == accountId).firstOrNull?.name ?? l.none}', style: context.text.bodyM),
          ),
          const SizedBox(height: AppSpace.sm),
          AppCard(
            onTap: () async {
              final id = await pickCategory(context, kind: _type, selectedId: _category);
              if (id != null) setState(() => _category = id);
            },
            child: Text('${l.category} · ${cats[_category]?.name ?? l.none}', style: context.text.bodyM),
          ),
          TextField(controller: _payee, decoration: InputDecoration(labelText: l.payee)),
          TextField(controller: _note, decoration: InputDecoration(labelText: l.note)),
          const SizedBox(height: AppSpace.sm),
          TextField(
            controller: _nameCtl,
            onChanged: (v) => _config = _config.copyWith(name: v),
            decoration: InputDecoration(labelText: l.recName),
          ),
          const SizedBox(height: AppSpace.sm),
          DateField(label: l.recStart, day: _start, onChanged: (d) => setState(() => _start = d)),
          const SizedBox(height: AppSpace.md),
          RecurringFields(start: _start, value: _config, onChanged: (v) => setState(() => _config = v)),
          const SizedBox(height: AppSpace.x2),
          PrimaryButton(label: l.save, onPressed: _save),
        ],
      ),
    );
  }
}
