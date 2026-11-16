import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/utils/formatters.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/charts.dart';
import 'package:floos/core/widgets/money_text.dart';
import 'package:floos/core/widgets/states.dart';
import 'package:floos/data/repositories/transactions_repository.dart';
import 'package:floos/features/report/report_providers.dart';
import 'package:floos/features/transactions/tx_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Category detail: total, 6-period trend, subcategories, transactions.
class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({required this.categoryId, super.key});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cats = ref.watch(categoriesMapProvider);
    final cat = cats[categoryId];
    final period = ref.watch(effectiveReportPeriodProvider);
    final base = ref.watch(baseCurrencyProvider);
    final fx = ref.watch(fxProvider);
    final today = ref.watch(todayProvider);
    final repo = ref.watch(transactionsRepoProvider);
    if (cat == null) return Scaffold(appBar: AppBar(), body: const LoadingView());
    final ids = {categoryId, ...cats.values.where((c) => c.parentId == categoryId).map((c) => c.id)};
    final filter = TxFilter(startMs: period.startMs, endExclusiveMs: period.endExclusiveMs, categoryIds: ids);
    return Scaffold(
      appBar: AppBar(title: Text(cat.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSizes.scrollBottomPadding),
        children: [
          Text(Fmt.period(period), style: context.text.caption),
          FutureBuilder<List<int>>(
            future: () async {
              final out = <int>[];
              var p = period;
              for (var i = 0; i < 6; i++) {
                final rows = await repo.aggregate(type: cat.kind, period: p, key: AggKey.category, categoryIds: ids, capAt: today);
                var sum = 0;
                for (final r in rows) {
                  sum += fx.convertMinor(r.sum, r.currency, base.code, today).valueOrNull ?? 0;
                }
                out.insert(0, sum);
                p = p.previous();
              }
              return out;
            }(),
            builder: (context, snap) {
              final v = snap.data ?? const <int>[];
              if (v.isEmpty) return const SizedBox(height: AppSizes.chartHeight);
              final periods = [
                for (var i = 5, p = period; i >= 0; i--, p = p.previous()) p,
              ].reversed.toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MoneyText(v.last, base, style: context.text.displayM),
                  const SizedBox(height: AppSpace.md),
                  Text(l.categoryDetailTrend, style: context.text.titleM),
                  const SizedBox(height: AppSpace.sm),
                  AppCard(
                    child: BarsChart(
                      groups: [
                        for (var i = 0; i < v.length; i++)
                          BarGroup(label: Fmt.monthShort(periods[i].start), values: [v[i]], highlight: i == v.length - 1),
                      ],
                      colors: [CategoryColor.byName(cat.color).strong],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpace.lg),
          Text(l.categoryDetailTx, style: context.text.titleM),
          const SizedBox(height: AppSpace.sm),
          StreamBuilder(
            stream: repo.watch(filter, limit: 100),
            builder: (context, snap) => GroupedTxList(items: snap.data ?? const []),
          ),
        ],
      ),
    );
  }
}
