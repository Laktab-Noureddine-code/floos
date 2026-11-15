import 'dart:async';

import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/amount_input_parser.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/time/period.dart';
import 'package:floos/core/utils/formatters.dart';
import 'package:floos/core/widgets/money_text.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/core/widgets/states.dart';
import 'package:floos/core/widgets/toggles.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/repositories/transactions_repository.dart';
import 'package:floos/features/backup/exporters.dart';
import 'package:floos/features/common/pickers.dart';
import 'package:floos/features/transactions/filter_sheet.dart';
import 'package:floos/features/transactions/tx_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// All transactions: FTS + amount search, filters, chips, totals footer,
/// infinite scroll by 50, multi-select bulk actions (APP_PROMPT §6.5).
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key, this.initial = const TxFilter()});

  final TxFilter initial;

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  static const pageSize = 50;
  late TxFilter _filter = widget.initial;
  String _query = '';
  int _limit = pageSize;
  Timer? _debounce;
  final _selection = <String>{};
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) {
        setState(() => _limit += pageSize);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  /// Parses `=45`, `>100`, `<20`, `>=`, `<=` amount operators.
  TxFilter _effective() {
    final q = _query.trim();
    final m = RegExp(r'^(>=|<=|=|>|<)\s*(.+)$').firstMatch(q);
    if (m != null) {
      final cur = ref.read(baseCurrencyProvider);
      final v = AmountInputParser.parse(m[2]!, Currencies.of(cur.code)).valueOrNull;
      if (v != null) {
        final op = switch (m[1]) {
          '=' => AmountOp.eq,
          '>' => AmountOp.gt,
          '<' => AmountOp.lt,
          '>=' => AmountOp.gte,
          _ => AmountOp.lte,
        };
        return _filter.copyWith(text: () => null, amountOp: () => op, amountValue: () => v);
      }
    }
    return _filter.copyWith(text: () => q.isEmpty ? null : q, amountOp: () => null, amountValue: () => null);
  }

  void _toggle(String id) => setState(() => _selection.contains(id) ? _selection.remove(id) : _selection.add(id));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = _effective();
    final repo = ref.watch(transactionsRepoProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_selection.isEmpty ? l.txListTitle : l.selectedCount(_selection.length)),
        leading: _selection.isEmpty
            ? null
            : IconButton(tooltip: l.close, icon: const Icon(Icons.close_rounded), onPressed: () => setState(_selection.clear)),
        actions: _selection.isEmpty ? [_filterButton()] : _bulkActions(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, 0),
            child: TextField(
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(AppMotion.searchDebounce, () => setState(() {
                  _query = v;
                  _limit = pageSize;
                }));
              },
              decoration: InputDecoration(hintText: l.txSearchHint, prefixIcon: const Icon(Icons.search_rounded)),
            ),
          ),
          _chips(),
          Expanded(
            child: StreamBuilder<List<TxView>>(
              stream: repo.watch(f, limit: _limit),
              builder: (context, snap) {
                if (snap.hasError) return ErrorView(onRetry: () => setState(() {}));
                if (!snap.hasData) return const LoadingView();
                final items = snap.data!;
                if (items.isEmpty) {
                  return ListView(
                    children: [
                      EmptyState(
                        illustration: Illustration.search,
                        message: l.searchNoResults,
                        actionLabel: f.isEmpty ? null : l.filterClearAll,
                        onAction: () => setState(() {
                          _filter = const TxFilter();
                          _query = '';
                        }),
                      ),
                    ],
                  );
                }
                return ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.x4),
                  children: [
                    GroupedTxList(items: items, selection: _selection, onToggleSelect: _toggle),
                  ],
                );
              },
            ),
          ),
          _Footer(filter: f),
        ],
      ),
    );
  }

  Widget _filterButton() {
    final l = context.l10n;
    final n = _activeCount(_filter);
    return IconButton(
      tooltip: n == 0 ? l.filterTitle : l.filterCount(n),
      icon: Badge(
        isLabelVisible: n > 0,
        label: Text('$n'),
        child: const Icon(PhosphorIconsRegular.funnel),
      ),
      onPressed: () async {
        final r = await showFilterSheet(context, _filter);
        if (r != null) setState(() => _filter = r);
      },
    );
  }

  static int _activeCount(TxFilter f) =>
      (f.startMs != null ? 1 : 0) +
      f.types.length +
      f.accountIds.length +
      f.categoryIds.length +
      f.tagIds.length +
      (f.minAmount != null ? 1 : 0) +
      (f.maxAmount != null ? 1 : 0) +
      (f.hasAttachment ? 1 : 0) +
      (f.pendingOnly ? 1 : 0);

  Widget _chips() {
    final l = context.l10n;
    final f = _filter;
    final accounts = {for (final a in ref.watch(accountsStreamProvider).value ?? const <AccountRow>[]) a.id: a.name};
    final cats = ref.watch(categoriesMapProvider);
    final tags = {for (final t in ref.watch(tagsStreamProvider).value ?? const <TagRow>[]) t.id: t.name};
    final base = ref.watch(baseCurrencyProvider);
    final fmt = ref.watch(formatterProvider);
    final chips = <Widget>[
      if (f.startMs != null)
        ChoicePill(
          label: Fmt.period(Period.custom(LocalDay.fromStorage(f.startMs!), LocalDay.fromStorage(f.endExclusiveMs!).addDays(-1))),
          selected: true,
          onTap: null,
          onRemove: () => setState(() => _filter = f.copyWith(clearRange: true)),
        ),
      for (final t in f.types)
        ChoicePill(
          label: switch (t) {
            'expense' => l.typeExpense,
            'income' => l.typeIncome,
            _ => l.typeTransfer,
          },
          selected: true,
          onTap: null,
          onRemove: () => setState(() => _filter = f.copyWith(types: {...f.types}..remove(t))),
        ),
      for (final a in f.accountIds)
        ChoicePill(
          label: accounts[a] ?? '',
          selected: true,
          onTap: null,
          onRemove: () => setState(() => _filter = f.copyWith(accountIds: {...f.accountIds}..remove(a))),
        ),
      for (final c in f.categoryIds)
        ChoicePill(
          label: cats[c]?.name ?? '',
          selected: true,
          onTap: null,
          onRemove: () => setState(() => _filter = f.copyWith(categoryIds: {...f.categoryIds}..remove(c))),
        ),
      for (final t in f.tagIds)
        ChoicePill(
          label: '#${tags[t] ?? ''}',
          selected: true,
          onTap: null,
          onRemove: () => setState(() => _filter = f.copyWith(tagIds: {...f.tagIds}..remove(t))),
        ),
      if (f.minAmount != null)
        ChoicePill(
          label: '≥ ${fmt.format(f.minAmount!, base)}',
          selected: true,
          onTap: null,
          onRemove: () => setState(() => _filter = f.copyWith(minAmount: () => null)),
        ),
      if (f.maxAmount != null)
        ChoicePill(
          label: '≤ ${fmt.format(f.maxAmount!, base)}',
          selected: true,
          onTap: null,
          onRemove: () => setState(() => _filter = f.copyWith(maxAmount: () => null)),
        ),
      if (f.hasAttachment)
        ChoicePill(
          label: l.filterHasAttachment,
          selected: true,
          onTap: null,
          onRemove: () => setState(() => _filter = f.copyWith(hasAttachment: false)),
        ),
      if (f.pendingOnly)
        ChoicePill(
          label: l.filterPendingOnly,
          selected: true,
          onTap: null,
          onRemove: () => setState(() => _filter = f.copyWith(pendingOnly: false)),
        ),
    ];
    if (chips.isEmpty) return const SizedBox(height: AppSpace.sm);
    return SizedBox(
      height: AppSizes.minTouch + AppSpace.sm,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
        children: [for (final c in chips) Padding(padding: const EdgeInsetsDirectional.only(end: AppSpace.xs), child: c)],
      ),
    );
  }

  List<Widget> _bulkActions() {
    final l = context.l10n;
    final repo = ref.read(transactionsRepoProvider);
    Future<void> done() async {
      await Haptics.light();
      if (!mounted) return;
      Snack.show(context, l.bulkDone);
      setState(_selection.clear);
    }

    return [
      IconButton(
        tooltip: l.bulkDelete,
        icon: const Icon(PhosphorIconsRegular.trash),
        onPressed: () async {
          final ids = _selection.toList();
          setState(_selection.clear);
          await deleteWithUndo(context, ref, ids);
        },
      ),
      PopupMenuButton<String>(
        tooltip: l.a11yMoreActions,
        onSelected: (v) async {
          switch (v) {
            case 'category':
              final views = await repo.get(TxFilter(ids: _selection, includePending: true));
              final kind = views.map((e) => e.tx.type).firstWhere((t) => t != 'transfer', orElse: () => 'expense');
              if (!mounted) return;
              final id = await pickCategory(context, kind: kind);
              if (id != null) {
                await repo.changeCategory(_selection, id);
                await done();
              }
            case 'account':
              final id = await pickAccount(context);
              if (id != null) {
                await repo.changeAccount(_selection, id);
                await done();
              }
            case 'tag':
              final tags = ref.read(tagsStreamProvider).value ?? const <TagRow>[];
              final id = await showAppSheet<String>(
                context,
                builder: (ctx) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SheetTitle(l.chooseTag),
                    for (final t in tags) ListTile(title: Text('#${t.name}'), onTap: () => Navigator.pop(ctx, t.id)),
                  ],
                ),
              );
              if (id != null) {
                await repo.addTag(_selection, id);
                await done();
              }
            case 'export':
              final views = await repo.get(TxFilter(ids: _selection, includePending: true));
              if (!mounted) return;
              await exportTransactionsCsv(context, ref, views: views);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'category', child: Text(l.bulkCategory)),
          PopupMenuItem(value: 'account', child: Text(l.bulkAccount)),
          PopupMenuItem(value: 'tag', child: Text(l.bulkTag)),
          PopupMenuItem(value: 'export', child: Text(l.bulkExport)),
        ],
      ),
    ];
  }
}

/// Sticky footer: In · Out · Net of the filtered set (base currency).
class _Footer extends ConsumerWidget {
  const _Footer({required this.filter});

  final TxFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final base = ref.watch(baseCurrencyProvider);
    final fx = ref.watch(fxProvider);
    final today = ref.watch(todayProvider);
    return StreamBuilder(
      stream: ref.watch(transactionsRepoProvider).watchTotals(filter),
      builder: (context, snap) {
        var inc = 0;
        var out = 0;
        for (final (cur, type, sum, _) in snap.data ?? const <(String, String, int, int)>[]) {
          final v = fx.convertMinor(sum, cur, base.code, today).valueOrNull ?? 0;
          if (type == 'income') inc += v;
          if (type == 'expense') out += v;
        }
        Widget cell(String label, int v, Color color) => Expanded(
          child: Column(
            children: [
              Text(label, style: context.text.caption),
              MoneyText(v, base, style: context.text.bodyS.copyWith(fontWeight: FontWeight.w700, color: color), dimDecimals: false),
            ],
          ),
        );
        return Container(
          decoration: BoxDecoration(color: context.colors.surface, boxShadow: context.shadows.nav),
          padding: EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.md,
            AppSpace.lg,
            AppSpace.md + MediaQuery.paddingOf(context).bottom,
          ),
          child: Row(
            children: [
              cell(l.footerIn, inc, context.colors.income),
              cell(l.footerOut, -out, context.colors.expense),
              cell(l.footerNet, inc - out, context.colors.textPrimary),
            ],
          ),
        );
      },
    );
  }
}
