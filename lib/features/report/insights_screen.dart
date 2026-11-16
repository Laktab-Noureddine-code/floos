import 'package:floos/app/providers.dart';
import 'package:floos/app/services_providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/widgets/states.dart';
import 'package:floos/core/widgets/transaction_tile.dart';
import 'package:floos/features/common/insight_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Full insights list (`/insights`).
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final list = ref.watch(insightsProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(l.insightsTitle)),
      body: list.isEmpty
          ? EmptyState(illustration: Illustration.chart, message: l.insightsEmpty)
          : ListView(
              padding: const EdgeInsets.all(AppSpace.screen),
              children: [
                for (final i in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.sm),
                    child: InsightPill(
                      text: insightText(context, ref, i),
                      onTap: () => context.push(i.route == '/report' ? '/report' : i.route),
                      onDismiss: () async {
                        final key = ref.read(periodCalculatorProvider).monthPeriodFor(ref.read(todayProvider)).key;
                        await ref.read(settingsRepoProvider).dismissInsight(key, i.id);
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}
