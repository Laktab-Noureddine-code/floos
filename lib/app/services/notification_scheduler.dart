import 'package:floos/app/services/notification_gateway.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/money/money_formatter.dart';
import 'package:floos/core/time/clock.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/utils/formatters.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/repositories/categories_repository.dart';
import 'package:floos/data/repositories/debts_repository.dart';
import 'package:floos/data/repositories/recurring_repository.dart';
import 'package:floos/data/repositories/settings_repository.dart';
import 'package:floos/domain/services/debt_service.dart';
import 'package:floos/domain/services/recurring_engine.dart';

/// Re-schedules every future reminder (bills, debts, daily) after rule
/// changes and on app start. iOS allows 64 pending: keep the nearest
/// (APP_PROMPT §5.7).
class NotificationScheduler {
  NotificationScheduler({
    required this.gateway,
    required this.settings,
    required this.recurring,
    required this.debts,
    required this.categories,
    this.clock = const Clock(),
  });

  final NotificationGateway gateway;
  final SettingsRepository settings;
  final RecurringRepository recurring;
  final DebtsRepository debts;
  final CategoriesRepository categories;
  final Clock clock;

  static const maxPending = 64;
  static const horizonDays = 120;
  static const debtHourMinutes = 9 * 60;

  AppLocalizations get _l => lookupAppLocalizations(appLocale);

  Future<List<ScheduledNotif>> build() async {
    final prefs = await settings.load();
    final now = clock.now();
    final today = LocalDay.fromDateTime(now);
    const fmt = MoneyFormatter(locale: appLocaleName);
    final hide = prefs.hideAmounts;
    final out = <ScheduledNotif>[];
    if (!prefs.notifMaster) return out;
    final cats = {for (final c in await categories.getAll()) c.id: c};
    if (prefs.notifBills) {
      for (final r in await recurring.getAll()) {
        if (!r.active || r.remindDaysBefore == null) continue;
        final account = await recurring.db.accountsDao.byId(r.templateAccountId);
        final currency = Currencies.of(account?.currencyCode ?? prefs.baseCurrency);
        final name = _ruleName(r, cats);
        final days = RecurringEngine.between(
          RecurringRepository.scheduleOf(r),
          LocalDay.fromStorage(r.nextDueDate),
          r.occurrencesCount,
          today,
          today.addDays(horizonDays),
        );
        for (final due in days) {
          final remind = RecurringEngine.reminderDay(due, r.remindDaysBefore)!;
          final when = remind.at(r.remindTimeMinutes);
          if (!when.isAfter(now)) continue;
          out.add(ScheduledNotif(
            id: notifId('bill:${r.id}:${due.toIso()}'),
            channel: NotifChannel.billReminders,
            title: _l.notifBillTitle,
            body: hide
                ? _l.notifBillBodyHidden(name, Fmt.weekday(due))
                : _l.notifBillBody(name, fmt.format(r.templateAmount, currency), Fmt.weekday(due)),
            when: when,
            route: '/recurring/${r.id}/edit',
          ));
        }
      }
    }
    if (prefs.notifDebts) {
      for (final d in await debts.getAll()) {
        if (d.status != 'open' || d.dueDate == null) continue;
        final due = LocalDay.fromStorage(d.dueDate!);
        final amount = fmt.format(d.originalAmount, Currencies.of(d.currencyCode));
        final iOwe = d.direction == 'i_owe';
        for (final day in DebtService.reminderDays(due)) {
          final when = day.at(debtHourMinutes);
          if (!when.isAfter(now)) continue;
          final tomorrow = day != due;
          final body = hide
              ? (tomorrow ? _l.notifDebtHiddenTomorrow(d.personName) : _l.notifDebtHiddenToday(d.personName))
              : iOwe
                  ? (tomorrow ? _l.notifDebtOweTomorrow(amount, d.personName) : _l.notifDebtOweToday(amount, d.personName))
                  : (tomorrow ? _l.notifDebtOwedTomorrow(amount, d.personName) : _l.notifDebtOwedToday(amount, d.personName));
          out.add(ScheduledNotif(
            id: notifId('debt:${d.id}:${day.toIso()}'),
            channel: NotifChannel.debtDue,
            title: _l.notifDebtTitle,
            body: body,
            when: when,
            route: '/debts/${d.id}',
          ));
        }
      }
    }
    out.sort((a, b) => a.when.compareTo(b.when));
    final limited = out.take(maxPending - 1).toList();
    if (prefs.notifDaily) {
      var when = today.at(prefs.notifDailyTime);
      if (!when.isAfter(now)) when = today.addDays(1).at(prefs.notifDailyTime);
      limited.add(ScheduledNotif(
        id: notifId('daily'),
        channel: NotifChannel.dailyReminder,
        title: _l.notifDailyTitle,
        body: _l.notifDailyBody,
        when: when,
        route: '/add',
        daily: true,
      ));
    }
    return limited;
  }

  String _ruleName(RecurringRuleRow r, Map<String, CategoryRow> cats) {
    final n = RecurringRepository.displayName(r);
    if (n.isNotEmpty) return n;
    return cats[r.templateCategoryId]?.name ?? _l.typeTransfer;
  }

  Future<void> rescheduleAll() async {
    await gateway.cancelScheduled();
    if (!await gateway.isPermitted()) return;
    await gateway.scheduleAll(await build());
  }
}
