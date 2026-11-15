import 'dart:io';

import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/money/money_formatter.dart';
import 'package:floos/core/utils/logger.dart';
import 'package:home_widget/home_widget.dart';

/// Values pushed to the home screen widgets (APP_PROMPT §6.12).
class WidgetSnapshot {
  const WidgetSnapshot({
    required this.spent,
    required this.income,
    required this.balance,
    required this.currency,
    required this.hidden,
    this.topBudget,
  });

  final int spent;
  final int income;
  final int balance;
  final Currency currency;
  final bool hidden;

  /// e.g. "Alimentation 72 %".
  final String? topBudget;
}

/// Writes widget data via `home_widget` and refreshes both widgets.
abstract class HomeWidgetSync {
  Future<void> push(WidgetSnapshot s);
}

class NoopHomeWidgetSync implements HomeWidgetSync {
  const NoopHomeWidgetSync();

  @override
  Future<void> push(WidgetSnapshot s) async {}
}

class PlatformHomeWidgetSync implements HomeWidgetSync {
  static const appGroup = 'group.com.floos.app';
  static const androidSmall = 'FloosSmallWidgetProvider';
  static const androidMedium = 'FloosMediumWidgetProvider';
  static const iosName = 'FloosWidget';

  @override
  Future<void> push(WidgetSnapshot s) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      const fmt = MoneyFormatter(locale: appLocaleName);
      final l = lookupAppLocalizations(appLocale);
      String v(int minor) => s.hidden ? kMask : fmt.format(minor, s.currency, showDecimals: false);
      if (Platform.isIOS) await HomeWidget.setAppGroupId(appGroup);
      await Future.wait([
        HomeWidget.saveWidgetData<String>('label_spent', l.widgetSpent),
        HomeWidget.saveWidgetData<String>('label_income', l.widgetIncome),
        HomeWidget.saveWidgetData<String>('label_balance', l.widgetBalance),
        HomeWidget.saveWidgetData<String>('spent_month', v(s.spent)),
        HomeWidget.saveWidgetData<String>('income_month', v(s.income)),
        HomeWidget.saveWidgetData<String>('balance', v(s.balance)),
        HomeWidget.saveWidgetData<String>('top_budget', s.hidden ? '' : (s.topBudget ?? '')),
        HomeWidget.saveWidgetData<bool>('hidden', s.hidden),
      ]);
      await HomeWidget.updateWidget(androidName: androidSmall, iOSName: iosName);
      await HomeWidget.updateWidget(androidName: androidMedium, iOSName: iosName);
    } on Object catch (e, st) {
      AppLogger.error('home_widget', e, st);
    }
  }
}
