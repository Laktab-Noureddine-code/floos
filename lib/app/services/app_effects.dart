import 'dart:async';

import 'package:floos/app/services/alert_service.dart';
import 'package:floos/app/services/home_widget_sync.dart';
import 'package:floos/app/services/notification_gateway.dart';
import 'package:floos/app/services/notification_scheduler.dart';
import 'package:floos/app/services/summary_service.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/money/money_formatter.dart';
import 'package:floos/core/time/clock.dart';
import 'package:floos/core/time/period.dart';
import 'package:floos/core/utils/logger.dart';
import 'package:floos/data/repositories/budgets_repository.dart';
import 'package:floos/data/repositories/debts_repository.dart';
import 'package:floos/data/repositories/goals_repository.dart';
import 'package:floos/data/repositories/notifications_repository.dart';
import 'package:floos/data/repositories/repo_base.dart';
import 'package:floos/data/repositories/settings_repository.dart';
import 'package:floos/data/repositories/tags_rates_repositories.dart';
import 'package:floos/domain/services/goal_service.dart';

/// Side effects after data writes: budget alerts (§5.5), goal milestones and
/// completion (§5.6), debt auto-settle (§5.8), reminders (§5.7) and home
/// widget refresh (§6.12).
class AppEffects implements WriteHooks {
  AppEffects({
    required this.settings,
    required this.rates,
    required this.budgets,
    required this.goals,
    required this.debts,
    required this.summary,
    required this.alerts,
    required this.scheduler,
    required this.widgets,
    this.clock = const Clock(),
  });

  final SettingsRepository settings;
  final RatesRepository rates;
  final BudgetsRepository budgets;
  final GoalsRepository goals;
  final DebtsRepository debts;
  final SummaryService summary;
  final AlertService alerts;
  final NotificationScheduler scheduler;
  final HomeWidgetSync widgets;
  final Clock clock;

  /// Goals that just reached 100 % (UI shows confetti once).
  final _completed = StreamController<String>.broadcast();
  Stream<String> get goalCompleted => _completed.stream;

  Timer? _rescheduleTimer;
  Timer? _widgetTimer;
  bool suspended = false;

  AppLocalizations get _l => lookupAppLocalizations(appLocale);

  @override
  Future<void> onTransactionsChanged(Set<int> days) async {
    if (suspended) return;
    await _guard(() => _budgetAlerts(days));
    await onDataChanged();
  }

  @override
  Future<void> onDataChanged() async {
    if (suspended) return;
    await _guard(_goals);
    await _guard(() async => debts.autoSettle(await rates.fx()));
    _rescheduleTimer?.cancel();
    _rescheduleTimer = Timer(const Duration(milliseconds: 500), () => _guard(scheduler.rescheduleAll));
    _widgetTimer?.cancel();
    _widgetTimer = Timer(const Duration(seconds: 1), () => _guard(refreshWidgets));
  }

  Future<void> _guard(Future<void> Function() f) async {
    try {
      await f();
    } on Object catch (e, st) {
      AppLogger.error('effects', e, st);
    }
  }

  Future<void> _budgetAlerts(Set<int> days) async {
    final prefs = await settings.load();
    final fx = await rates.fx();
    const fmt = MoneyFormatter(locale: appLocaleName);
    final base = Currencies.of(prefs.baseCurrency);
    for (final (view, threshold) in await budgets.newAlerts(prefs, fx, days)) {
      final name = view.row.name.isEmpty ? _l.budgetOverall : view.row.name;
      final pct = view.status.percent;
      await alerts.emit(
        type: NotifType.budget,
        channel: NotifChannel.budgetAlerts,
        key: 'budget:${view.id}:${view.status.period.key}:$threshold',
        title: _l.notifBudgetTitle(name),
        body: prefs.hideAmounts
            ? _l.notifBudgetBodyHidden(name, pct)
            : _l.notifBudgetBody(name, pct, fmt.format(view.status.available, base, showDecimals: false)),
        route: '/budgets/${view.id}',
        enabled: (p) => p.notifBudget,
      );
    }
  }

  Future<void> _goals() async {
    final prefs = await settings.load();
    final fx = await rates.fx();
    final balances = {
      for (final a in await summary.accounts.withBalances(clock.today()))
        a.account.id: (a.balance, a.account.currencyCode),
    };
    final contributions = await goals.db.goalsDao.allContributions();
    final views = [
      for (final g in await goals.db.goalsDao.getAll())
        if (g.status != 'archived') goals.evaluate(g, contributions, balances, prefs, fx),
    ];
    for (final v in views) {
      final fresh = GoalService.newMilestones(v.status.progressPermille, v.notifiedMilestones);
      if (fresh.isEmpty) continue;
      await goals.markMilestones(v.id, {...v.notifiedMilestones, ...fresh});
      final top = fresh.last;
      await alerts.emit(
        type: NotifType.goal,
        channel: NotifChannel.goalMilestones,
        key: 'goal:${v.id}:$top',
        title: _l.notifGoalTitle,
        body: top >= 100 ? _l.notifGoalDoneBody(v.row.name) : _l.notifGoalBody(top, v.row.name),
        route: '/goals/${v.id}',
        enabled: (p) => p.notifGoals,
      );
    }
    for (final id in await goals.autoComplete(views)) {
      _completed.add(id);
    }
  }

  /// Recomputes and pushes the home widget snapshot.
  Future<void> refreshWidgets() async {
    final prefs = await settings.load();
    final fx = await rates.fx();
    final today = clock.today();
    final period = Period.month(today, prefs.monthStartDay);
    final totals = await summary.totals(period, prefs.baseCurrency, fx, capAt: today);
    final nw = await summary.netWorth(today, prefs.baseCurrency, fx);
    final views = await budgets.evaluateActive(prefs, fx);
    views.sort((a, b) => b.status.progressPermille.compareTo(a.status.progressPermille));
    final top = views.isEmpty ? null : views.first;
    await widgets.push(
      WidgetSnapshot(
        spent: totals.expense,
        income: totals.income,
        balance: nw.total,
        currency: Currencies.of(prefs.baseCurrency),
        hidden: prefs.hideAmounts,
        topBudget: top == null
            ? null
            : '${top.row.name.isEmpty ? _l.budgetOverall : top.row.name} ${top.status.percent} %',
      ),
    );
  }

  void dispose() {
    _rescheduleTimer?.cancel();
    _widgetTimer?.cancel();
    _completed.close();
  }
}
