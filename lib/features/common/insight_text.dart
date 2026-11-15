import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/money/money_formatter.dart';
import 'package:floos/domain/services/insight_engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Localized sentence for an insight (amounts masked when hidden).
String insightText(BuildContext context, WidgetRef ref, Insight i) {
  final l = context.l10n;
  final hide = ref.watch(hideAmountsProvider);
  final fmt = ref.watch(formatterProvider);
  final base = ref.watch(baseCurrencyProvider);
  String money(Object? v, [Object? code]) =>
      hide ? kMask : fmt.format(v as int? ?? 0, code == null ? base : Currencies.of(code as String), showDecimals: false);
  final p = i.params;
  String name() => (p['name'] as String?)?.isNotEmpty ?? false ? p['name']! as String : l.budgetOverall;
  return switch (i.kind) {
    InsightKind.budgetOver => l.insightBudgetOver(name(), money(p['over'])),
    InsightKind.budgetWarning => l.insightBudgetWarning(name(), p['percent']! as int, money(p['perDay'])),
    InsightKind.goalBehind => l.insightGoalBehind(name(), money(p['needed'])),
    InsightKind.upcomingBill => l.insightBill(name(), money(p['amount'], p['currency']), l.insightBillWhen(p['days']! as int)),
    InsightKind.categoryUp => l.insightCategoryUp(name(), p['percent']! as int),
    InsightKind.unusualTransaction => l.insightUnusual(name(), money(p['amount'], p['currency'])),
    InsightKind.savingsRate => l.insightSavings(p['percent']! as int),
    InsightKind.noRecentLogs => l.insightNoLogs,
    InsightKind.backupOverdue => l.insightBackup,
  };
}
