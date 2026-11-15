import 'dart:io';

import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/money/money_formatter.dart';
import 'package:floos/core/time/clock.dart';
import 'package:floos/core/time/period_calculator.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/db/db_connection.dart';
import 'package:floos/data/repositories/accounts_repository.dart';
import 'package:floos/data/repositories/attachment_store.dart';
import 'package:floos/data/repositories/budgets_repository.dart';
import 'package:floos/data/repositories/categories_repository.dart';
import 'package:floos/data/repositories/debts_repository.dart';
import 'package:floos/data/repositories/goals_repository.dart';
import 'package:floos/data/repositories/notifications_repository.dart';
import 'package:floos/data/repositories/recurring_repository.dart';
import 'package:floos/data/repositories/repo_base.dart';
import 'package:floos/data/repositories/settings_repository.dart';
import 'package:floos/data/repositories/tags_rates_repositories.dart';
import 'package:floos/data/repositories/transactions_repository.dart';
import 'package:floos/domain/services/fx_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Directories used by the app (overridden at bootstrap / in tests).
@immutable
class AppDirs {
  const AppDirs({required this.documents});
  final Directory documents;

  Directory get attachments => Directory('${documents.path}/attachments');
  Directory get backups => Directory('${documents.path}/backups');
}

/// Platform image compression (overridden at bootstrap).
final imageCompressorProvider = Provider<ImageCompressor>((ref) => (path) async => File(path).readAsBytes());

final databaseProvider = Provider<AppDatabase>(
  (ref) => throw StateError('databaseProvider must be overridden at bootstrap'),
);

final secretStoreProvider = Provider<SecretStore>((ref) => const DeviceSecretStore());

final appDirsProvider = Provider<AppDirs>(
  (ref) => throw StateError('appDirsProvider must be overridden at bootstrap'),
);

final clockProvider = Provider<Clock>((ref) => const Clock());

/// Relay so app-level effects (alerts, widgets) can be attached after
/// repositories are created.
final hooksProvider = Provider<HookRelay>((ref) => HookRelay());

final Provider<SettingsRepository> settingsRepoProvider = Provider(
  (ref) => SettingsRepository(ref.watch(databaseProvider), clock: ref.watch(clockProvider)),
);

final Provider<AttachmentStore> attachmentStoreProvider = Provider(
  (ref) => AttachmentStore(
    ref.watch(databaseProvider),
    directory: ref.watch(appDirsProvider).attachments,
    compressor: ref.watch(imageCompressorProvider),
    clock: ref.watch(clockProvider),
  ),
);

final Provider<TransactionsRepository> transactionsRepoProvider = Provider(
  (ref) => TransactionsRepository(
    ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
    hooks: ref.watch(hooksProvider),
    onDeleteFiles: ref.watch(attachmentStoreProvider).deleteFiles,
  ),
);

final Provider<AccountsRepository> accountsRepoProvider = Provider(
  (ref) => AccountsRepository(
    ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
    hooks: ref.watch(hooksProvider),
    onDeleteFiles: ref.watch(attachmentStoreProvider).deleteFiles,
  ),
);

final Provider<CategoriesRepository> categoriesRepoProvider = Provider(
  (ref) => CategoriesRepository(
    ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
    hooks: ref.watch(hooksProvider),
  ),
);

final Provider<TagsRepository> tagsRepoProvider = Provider(
  (ref) => TagsRepository(ref.watch(databaseProvider), clock: ref.watch(clockProvider), hooks: ref.watch(hooksProvider)),
);

final Provider<RatesRepository> ratesRepoProvider = Provider(
  (ref) => RatesRepository(ref.watch(databaseProvider), clock: ref.watch(clockProvider), hooks: ref.watch(hooksProvider)),
);

final Provider<BudgetsRepository> budgetsRepoProvider = Provider(
  (ref) => BudgetsRepository(ref.watch(databaseProvider), clock: ref.watch(clockProvider), hooks: ref.watch(hooksProvider)),
);

final Provider<GoalsRepository> goalsRepoProvider = Provider(
  (ref) => GoalsRepository(
    ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
    hooks: ref.watch(hooksProvider),
    transactions: ref.watch(transactionsRepoProvider),
  ),
);

final Provider<RecurringRepository> recurringRepoProvider = Provider(
  (ref) => RecurringRepository(
    ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
    hooks: ref.watch(hooksProvider),
    transactions: ref.watch(transactionsRepoProvider),
  ),
);

final Provider<DebtsRepository> debtsRepoProvider = Provider(
  (ref) => DebtsRepository(
    ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
    hooks: ref.watch(hooksProvider),
    transactions: ref.watch(transactionsRepoProvider),
  ),
);

final Provider<NotificationsRepository> notificationsRepoProvider = Provider(
  (ref) => NotificationsRepository(ref.watch(databaseProvider), clock: ref.watch(clockProvider)),
);

// ------------------------------------------------------------- live state

final prefsStreamProvider = StreamProvider<AppPrefs>((ref) => ref.watch(settingsRepoProvider).watch());

/// Current settings (defaults while loading).
final prefsProvider = Provider<AppPrefs>(
  (ref) => ref.watch(prefsStreamProvider).value ?? AppPrefs.defaults,
);

final fxStreamProvider = StreamProvider<FxService>((ref) => ref.watch(ratesRepoProvider).watchFx());

final fxProvider = Provider<FxService>((ref) => ref.watch(fxStreamProvider).value ?? FxService(const []));

/// Ticks whenever transactions change (drives recomputation).
final txTickProvider = StreamProvider<int>((ref) => ref.watch(transactionsRepoProvider).watchChanges());

/// Today, refreshed on resume / day change.
class TodayNotifier extends Notifier<LocalDay> {
  @override
  LocalDay build() => ref.watch(clockProvider).today();

  void refresh() {
    final now = ref.read(clockProvider).today();
    if (now != state) state = now;
  }
}

final todayProvider = NotifierProvider<TodayNotifier, LocalDay>(TodayNotifier.new);

final periodCalculatorProvider = Provider<PeriodCalculator>((ref) {
  final p = ref.watch(prefsProvider);
  return PeriodCalculator(monthStartDay: p.monthStartDay, weekStartDay: p.weekStartDay);
});

final baseCurrencyProvider = Provider<Currency>((ref) => Currencies.of(ref.watch(prefsProvider).baseCurrency));

final formatterProvider = Provider<MoneyFormatter>((ref) => const MoneyFormatter(locale: appLocaleName));

final hideAmountsProvider = Provider<bool>((ref) => ref.watch(prefsProvider).hideAmounts);

final accountsStreamProvider = StreamProvider<List<AccountRow>>((ref) => ref.watch(accountsRepoProvider).watchAll());

final accountsWithBalanceProvider = StreamProvider<List<AccountWithBalance>>(
  (ref) => ref.watch(accountsRepoProvider).watchWithBalances(ref.watch(todayProvider)),
);

final categoriesStreamProvider = StreamProvider<List<CategoryRow>>(
  (ref) => ref.watch(categoriesRepoProvider).watchAll(),
);

final categoriesMapProvider = Provider<Map<String, CategoryRow>>((ref) {
  final list = ref.watch(categoriesStreamProvider).value ?? const [];
  return {for (final c in list) c.id: c};
});

final tagsStreamProvider = StreamProvider<List<TagRow>>((ref) => ref.watch(tagsRepoProvider).watchAll());

final unreadNotificationsProvider = StreamProvider<int>(
  (ref) => ref.watch(notificationsRepoProvider).watchUnread(),
);

/// UI-only preferences (last tab, last account…), overridden at bootstrap.
final uiPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw StateError('uiPrefsProvider must be overridden at bootstrap'),
);

/// Keys for [uiPrefsProvider].
abstract final class UiKeys {
  static const lastTxType = 'last_tx_type';
  static const lastAccount = 'last_account';
  static const reportDonut = 'report_donut';
}

final goalsStreamProvider = StreamProvider<List<GoalRow>>((ref) => ref.watch(goalsRepoProvider).watchAll());

final debtsStreamProvider = StreamProvider<List<DebtRow>>((ref) => ref.watch(debtsRepoProvider).watchAll());

final recurringStreamProvider = StreamProvider<List<RecurringRuleRow>>(
  (ref) => ref.watch(recurringRepoProvider).watchAll(),
);

final budgetsStreamProvider = StreamProvider<List<BudgetRow>>((ref) => ref.watch(budgetsRepoProvider).watchAll());
