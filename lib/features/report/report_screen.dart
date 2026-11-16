import 'package:floos/app/providers.dart';
import 'package:floos/app/services_providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/utils/formatters.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/charts.dart';
import 'package:floos/core/widgets/donut_chart.dart';
import 'package:floos/core/widgets/money_text.dart';
import 'package:floos/core/widgets/states.dart';
import 'package:floos/core/widgets/toggles.dart';
import 'package:floos/core/widgets/transaction_tile.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/domain/services/report_service.dart';
import 'package:floos/features/common/insight_text.dart';
import 'package:floos/features/common/period_sheet.dart';
import 'package:floos/features/report/report_export.dart';
import 'package:floos/features/report/report_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Report tab (design.md §4.2).
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key, this.type});

  final String? type;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  int? _selected;

  @override
  void initState() {
    super.initState();
    final t = widget.type;
    if (t == 'income' || t == 'expense') {
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(reportTypeProvider.notifier).set(t!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final period = ref.watch(effectiveReportPeriodProvider);
    final type = ref.watch(reportTypeProvider);
    final donut = ref.watch(uiPrefsProvider).getBool(UiKeys.reportDonut) ?? true;
    final data = ref.watch(reportDataProvider);
    final base = ref.watch(baseCurrencyProvider);
    final insights = ref.watch(insightsProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: Text(l.reportTitle),
        actions: [
          PopupMenuButton<String>(
            tooltip: l.export,
            icon: const Icon(Icons.ios_share_rounded),
            onSelected: (v) => v == 'csv' ? exportReportCsv(context, ref, period) : exportReportPdf(context, ref),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'csv', child: Text(l.reportExportCsv)),
              PopupMenuItem(value: 'pdf', child: Text(l.reportExportPdf)),
            ],
          ),
        ],
      ),
      body: AsyncValueView<ReportData>(
        value: data,
        onRetry: () => ref.invalidate(reportDataProvider),
        data: (d) {
          final total = type == 'expense' ? d.current.expense : d.current.income;
          final prevTotal = type == 'expense' ? d.previous.expense : d.previous.income;
          final cats = ref.watch(categoriesMapProvider);
          final colors = [
            for (final i in d.items) CategoryColor.byName(cats[i.key]?.color).strong,
          ];
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSizes.scrollBottomPadding),
            children: [
              Center(
                child: PeriodNavigator(
                  period: period,
                  onChanged: (p) => ref.read(reportPeriodProvider.notifier).set(p),
                  onPick: () async {
                    final p = await pickPeriod(context, current: period);
                    if (p != null) ref.read(reportPeriodProvider.notifier).set(p);
                  },
                ),
              ),
              const SizedBox(height: AppSpace.md),
              SegmentedToggle<String>(
                options: const ['expense', 'income'],
                value: type,
                labelOf: (v) => v == 'expense' ? l.expenses : l.incomes,
                onChanged: (v) {
                  _selected = null;
                  ref.read(reportTypeProvider.notifier).set(v);
                },
              ),
              const SizedBox(height: AppSpace.lg),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(type == 'expense' ? l.reportExpensesTotal : l.reportIncomeTotal, style: context.text.caption),
                        MoneyText(total, base, style: context.text.displayM),
                      ],
                    ),
                  ),
                  if (prevTotal > 0)
                    TrendChip(
                      percent: (((total - prevTotal) * 100) / prevTotal).round(),
                      increaseIsBad: type == 'expense',
                      label: l.vsLastPeriod,
                    ),
                  ChartTypeToggle(
                    donut: donut,
                    onChanged: (v) async {
                      await ref.read(uiPrefsProvider).setBool(UiKeys.reportDonut, v);
                      setState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              if (d.items.isEmpty)
                EmptyState(illustration: Illustration.chart, message: l.reportNoData)
              else ...[
                if (donut)
                  Center(
                    child: DonutChart(
                      segments: [
                        for (var i = 0; i < d.items.length; i++)
                          DonutSegment(value: d.items[i].total, color: colors[i], semanticLabel: _name(l, cats, d.items[i].key)),
                      ],
                      selected: _selected,
                      onSelect: (v) => setState(() => _selected = v),
                      center: MoneyText(
                        _selected == null ? total : d.items[_selected!].total,
                        base,
                        style: context.text.titleL,
                      ),
                    ),
                  )
                else
                  ChartOrTable(
                    chart: BarsChart(
                      groups: [for (final i in d.items.take(8)) BarGroup(label: _name(l, cats, i.key), values: [i.total])],
                      colors: colors.take(8).toList(),
                    ),
                    rows: [for (final i in d.items) (_name(l, cats, i.key), '${i.total}')],
                  ),
                const SizedBox(height: AppSpace.lg),
                for (var i = 0; i < d.items.length; i++)
                  _CategoryRow(item: d.items[i], total: total, cats: cats, period: period.key, type: type),
              ],
              const SizedBox(height: AppSpace.lg),
              Text(l.reportCashFlow, style: context.text.titleM),
              const SizedBox(height: AppSpace.sm),
              AppCard(
                child: BarsChart(
                  groups: [
                    for (final e in d.cashFlow)
                      BarGroup(label: Fmt.monthShort(e.$1.start), values: [e.$2, e.$3], highlight: e.$1 == period),
                  ],
                  colors: [context.colors.income, context.colors.expense],
                  line: [for (final e in d.cashFlow) e.$2 - e.$3],
                  lineColor: context.colors.primary,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(l.reportStats, style: context.text.titleM),
              const SizedBox(height: AppSpace.sm),
              _Stats(d: d, cats: cats),
              if (d.byAccount.isNotEmpty) ...[
                const SizedBox(height: AppSpace.lg),
                Text(l.reportByAccount, style: context.text.titleM),
                const SizedBox(height: AppSpace.sm),
                _Breakdown(items: d.byAccount, nameOf: (k) => ref.watch(accountsStreamProvider).value?.where((a) => a.id == k).firstOrNull?.name ?? ''),
              ],
              if (d.byTag.isNotEmpty) ...[
                const SizedBox(height: AppSpace.lg),
                Text(l.reportByTag, style: context.text.titleM),
                const SizedBox(height: AppSpace.sm),
                _Breakdown(items: d.byTag, nameOf: (k) => '#${ref.watch(tagsStreamProvider).value?.where((t) => t.id == k).firstOrNull?.name ?? ''}'),
              ],
              if (insights.isNotEmpty) ...[
                const SizedBox(height: AppSpace.lg),
                SectionHeader(title: l.insightsTitle, actionLabel: l.insightsAll, onAction: () => context.push('/insights')),
                InsightPill(text: insightText(context, ref, insights.first), onTap: () => context.push('/insights')),
              ],
            ],
          );
        },
      ),
    );
  }
}

String _name(AppLocalizations l, Map<String, CategoryRow> cats, String? id) => id == null ? l.reportUncategorized : cats[id]?.name ?? l.reportUncategorized;

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({required this.item, required this.total, required this.cats, required this.period, required this.type});

  final BreakdownItem item;
  final int total;
  final Map<String, CategoryRow> cats;
  final String period;
  final String type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = cats[item.key];
    final base = ref.watch(baseCurrencyProvider);
    final pct = total <= 0 ? 0 : (item.total * 100 / total).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: AppCard(
        onTap: () => context.push('/report/category/${item.key}'),
        child: Row(
          children: [
            IconTile.keyed(c?.icon, c?.color),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_name(l, cats, item.key), style: context.text.bodyM),
                  Text('$pct %', style: context.text.caption),
                ],
              ),
            ),
            if (item.previous > 0) ...[
              TrendChip(percent: (((item.total - item.previous) * 100) / item.previous).round(), increaseIsBad: type == 'expense'),
              const SizedBox(width: AppSpace.sm),
            ],
            MoneyText(item.total, base, style: context.text.bodyM.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _Stats extends ConsumerWidget {
  const _Stats({required this.d, required this.cats});

  final ReportData d;
  final Map<String, CategoryRow> cats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final base = ref.watch(baseCurrencyProvider);
    final s = d.stats;
    Widget row(String label, Widget value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(children: [Expanded(child: Text(label, style: context.text.bodyS)), value]),
    );
    return AppCard(
      child: Column(
        children: [
          if (s.savingsRatePct != null) row(l.reportSavingsRate, Text('${s.savingsRatePct} %', style: context.text.bodyM)),
          row(l.reportAvgPerDay, MoneyText(s.avgPerDay, base, style: context.text.bodyM)),
          row(l.reportTxCount, Text('${s.transactionCount}', style: context.text.bodyM)),
          if (s.biggestExpenseTxId != null) row(l.reportBiggest, MoneyText(s.biggestExpense, base, style: context.text.bodyM)),
          if (s.mostFrequentCategoryId != null) row(l.reportMostFrequent, Text(cats[s.mostFrequentCategoryId]?.name ?? '', style: context.text.bodyM)),
          if (s.topPayee != null) row(l.reportTopPayee, Text(s.topPayee!, style: context.text.bodyM)),
        ],
      ),
    );
  }
}

class _Breakdown extends ConsumerWidget {
  const _Breakdown({required this.items, required this.nameOf});

  final List<BreakdownItem> items;
  final String Function(String key) nameOf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = ref.watch(baseCurrencyProvider);
    return AppCard(
      child: Column(
        children: [
          for (final i in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
              child: Row(
                children: [
                  Expanded(child: Text(nameOf(i.key), style: context.text.bodyS)),
                  MoneyText(i.total, base, style: context.text.bodyM),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
