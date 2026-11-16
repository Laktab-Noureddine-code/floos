import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/amount_input_parser.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/time/period.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/core/widgets/toggles.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/repositories/transactions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filter sheet: date presets, types, accounts, categories, tags, amount
/// range, attachments and pending only. Returns the new filter or null.
Future<TxFilter?> showFilterSheet(BuildContext context, TxFilter current) =>
    showAppSheet<TxFilter>(context, expand: true, builder: (_) => _FilterSheet(current: current));

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.current});

  final TxFilter current;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late TxFilter f = widget.current;
  late final TextEditingController _min = TextEditingController(text: _fmt(widget.current.minAmount));
  late final TextEditingController _max = TextEditingController(text: _fmt(widget.current.maxAmount));

  String _fmt(int? minor) {
    if (minor == null) return '';
    final cur = ref.read(baseCurrencyProvider);
    return (minor / cur.factor).toStringAsFixed(cur.digits);
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  Set<String> _toggle(Set<String> s, String v) => s.contains(v) ? ({...s}..remove(v)) : {...s, v};

  int? _parse(String t) {
    if (t.trim().isEmpty) return null;
    return AmountInputParser.parse(t, ref.read(baseCurrencyProvider)).valueOrNull;
  }

  void _preset(Period? p) => setState(() {
    f = p == null ? f.copyWith(clearRange: true) : f.copyWith(startMs: p.startMs, endExclusiveMs: p.endExclusiveMs);
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final calc = ref.watch(periodCalculatorProvider);
    final today = ref.watch(todayProvider);
    final accounts = ref.watch(accountsStreamProvider).value ?? const <AccountRow>[];
    final cats = (ref.watch(categoriesStreamProvider).value ?? const <CategoryRow>[]).where((c) => !c.archived).toList();
    final tags = ref.watch(tagsStreamProvider).value ?? const <TagRow>[];
    final thisMonth = calc.monthPeriodFor(today);
    final presets = <(String, Period?)>[
      (l.periodThis, thisMonth),
      (l.periodLast, thisMonth.previous()),
      (l.periodLast3Months, Period.custom(thisMonth.start.addMonths(-2), thisMonth.end)),
      (l.periodThisYear, calc.yearPeriodFor(today)),
      (l.periodAllTime, null),
    ];
    Widget section(String title, List<Widget> chips) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.titleM),
          const SizedBox(height: AppSpace.sm),
          Wrap(spacing: AppSpace.sm, runSpacing: AppSpace.xs, children: chips),
        ],
      ),
    );
    return Column(
      children: [
        SheetTitle(
          l.filterTitle,
          trailing: TextButton(
            onPressed: () => setState(() {
              f = const TxFilter();
              _min.clear();
              _max.clear();
            }),
            child: Text(l.filterClearAll),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            children: [
              section(l.filterDateRange, [
                for (final (label, p) in presets)
                  ChoicePill(
                    label: label,
                    selected: p == null ? f.startMs == null : f.startMs == p.startMs && f.endExclusiveMs == p.endExclusiveMs,
                    onTap: () => _preset(p),
                  ),
              ]),
              section(l.filterTypes, [
                for (final (t, label) in [('expense', l.typeExpense), ('income', l.typeIncome), ('transfer', l.typeTransfer)])
                  ChoicePill(
                    label: label,
                    selected: f.types.contains(t),
                    onTap: () => setState(() => f = f.copyWith(types: _toggle(f.types, t))),
                  ),
              ]),
              section(l.filterAccounts, [
                for (final a in accounts)
                  ChoicePill(
                    label: a.name,
                    selected: f.accountIds.contains(a.id),
                    onTap: () => setState(() => f = f.copyWith(accountIds: _toggle(f.accountIds, a.id))),
                  ),
              ]),
              section(l.filterCategories, [
                for (final c in cats)
                  ChoicePill(
                    label: c.name,
                    selected: f.categoryIds.contains(c.id),
                    onTap: () => setState(() => f = f.copyWith(categoryIds: _toggle(f.categoryIds, c.id))),
                  ),
              ]),
              if (tags.isNotEmpty)
                section(l.filterTags, [
                  for (final t in tags)
                    ChoicePill(
                      label: '#${t.name}',
                      selected: f.tagIds.contains(t.id),
                      onTap: () => setState(() => f = f.copyWith(tagIds: _toggle(f.tagIds, t.id))),
                    ),
                ]),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _min,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: l.filterAmountMin),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: TextField(
                      controller: _max,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: l.filterAmountMax),
                    ),
                  ),
                ],
              ),
              SwitchRow(
                label: l.filterHasAttachment,
                value: f.hasAttachment,
                onChanged: (v) => setState(() => f = f.copyWith(hasAttachment: v)),
              ),
              SwitchRow(
                label: l.filterPendingOnly,
                value: f.pendingOnly,
                onChanged: (v) => setState(() => f = f.copyWith(pendingOnly: v)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: PrimaryButton(
            label: l.apply,
            onPressed: () => Navigator.pop(
              context,
              f.copyWith(minAmount: () => _parse(_min.text), maxAmount: () => _parse(_max.text)),
            ),
          ),
        ),
      ],
    );
  }
}
