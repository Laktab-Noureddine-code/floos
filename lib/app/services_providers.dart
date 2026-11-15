import 'package:floos/app/providers.dart';
import 'package:floos/app/services/alert_service.dart';
import 'package:floos/app/services/app_effects.dart';
import 'package:floos/app/services/csv_importer.dart';
import 'package:floos/app/services/home_widget_sync.dart';
import 'package:floos/app/services/insights_service.dart';
import 'package:floos/app/services/notification_gateway.dart';
import 'package:floos/app/services/notification_scheduler.dart';
import 'package:floos/app/services/summary_service.dart';
import 'package:floos/domain/services/backup_service.dart';
import 'package:floos/domain/services/insight_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationGatewayProvider = Provider<NotificationGateway>((ref) => FakeNotificationGateway());

final homeWidgetSyncProvider = Provider<HomeWidgetSync>((ref) => const NoopHomeWidgetSync());

final appVersionProvider = Provider<String>((ref) => '1.0.0+1');

final summaryServiceProvider = Provider(
  (ref) => SummaryService(ref.watch(transactionsRepoProvider), ref.watch(accountsRepoProvider)),
);

final alertServiceProvider = Provider(
  (ref) => AlertService(
    log: ref.watch(notificationsRepoProvider),
    gateway: ref.watch(notificationGatewayProvider),
    settings: ref.watch(settingsRepoProvider),
  ),
);

final notificationSchedulerProvider = Provider(
  (ref) => NotificationScheduler(
    gateway: ref.watch(notificationGatewayProvider),
    settings: ref.watch(settingsRepoProvider),
    recurring: ref.watch(recurringRepoProvider),
    debts: ref.watch(debtsRepoProvider),
    categories: ref.watch(categoriesRepoProvider),
    clock: ref.watch(clockProvider),
  ),
);

final appEffectsProvider = Provider((ref) {
  final effects = AppEffects(
    settings: ref.watch(settingsRepoProvider),
    rates: ref.watch(ratesRepoProvider),
    budgets: ref.watch(budgetsRepoProvider),
    goals: ref.watch(goalsRepoProvider),
    debts: ref.watch(debtsRepoProvider),
    summary: ref.watch(summaryServiceProvider),
    alerts: ref.watch(alertServiceProvider),
    scheduler: ref.watch(notificationSchedulerProvider),
    widgets: ref.watch(homeWidgetSyncProvider),
    clock: ref.watch(clockProvider),
  );
  ref.watch(hooksProvider).target = effects;
  ref.onDispose(effects.dispose);
  return effects;
});

final insightsServiceProvider = Provider(
  (ref) => InsightsService(
    summary: ref.watch(summaryServiceProvider),
    budgets: ref.watch(budgetsRepoProvider),
    goals: ref.watch(goalsRepoProvider),
    recurring: ref.watch(recurringRepoProvider),
    transactions: ref.watch(transactionsRepoProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Ranked insights, recomputed when data, settings or rates change.
final insightsProvider = FutureProvider<List<Insight>>((ref) async {
  ref
    ..watch(txTickProvider)
    ..watch(budgetsStreamProvider)
    ..watch(goalsStreamProvider)
    ..watch(recurringStreamProvider)
    ..watch(todayProvider);
  return ref.watch(insightsServiceProvider).compute(ref.watch(prefsProvider), ref.watch(fxProvider));
});

final backupServiceProvider = Provider(
  (ref) => BackupService(
    db: ref.watch(databaseProvider),
    attachmentsDir: ref.watch(appDirsProvider).attachments,
    backupsDir: ref.watch(appDirsProvider).backups,
    appVersion: ref.watch(appVersionProvider),
    clock: ref.watch(clockProvider),
  ),
);

final csvImporterProvider = Provider(
  (ref) => CsvImporter(ref.watch(databaseProvider), ref.watch(transactionsRepoProvider), clock: ref.watch(clockProvider)),
);
