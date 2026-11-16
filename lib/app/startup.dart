import 'package:floos/app/providers.dart';
import 'package:floos/app/services_providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/utils/logger.dart';
import 'package:floos/data/repositories/notifications_repository.dart';
import 'package:floos/data/repositories/settings_repository.dart';
import 'package:floos/app/services/notification_gateway.dart';
import 'package:floos/domain/services/backup_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Work done at launch and on every resume: recurring catch-up, reminder
/// rescheduling, due auto-backup, orphan attachment cleanup (FR-001).
Future<void> runStartupTasks(ProviderContainer c, {bool full = false}) async {
  final l = lookupAppLocalizations(appLocale);
  try {
    c.read(todayProvider.notifier).refresh();
    final summary = await c.read(recurringRepoProvider).runDue();
    if (summary.created.length > 3) {
      await c.read(alertServiceProvider).emit(
        type: NotifType.summary,
        channel: NotifChannel.pendingRecurring,
        key: 'recurring_summary:${c.read(todayProvider).toStorage()}',
        title: l.notifSummaryTitle,
        body: l.notifSummaryBody(summary.created.length),
        route: '/home',
        enabled: (p) => p.notifBills,
      );
    } else {
      for (final (id, day, name) in summary.pending) {
        await c.read(alertServiceProvider).emit(
          type: NotifType.pending,
          channel: NotifChannel.pendingRecurring,
          key: 'pending:$id:${day.toStorage()}',
          title: l.notifPendingTitle,
          body: l.notifPendingBody(name),
          route: '/home',
          enabled: (p) => p.notifBills,
        );
      }
    }
    await c.read(notificationSchedulerProvider).rescheduleAll();
    final prefs = await c.read(settingsRepoProvider).load();
    final now = c.read(clockProvider).now();
    if (BackupService.isDue(prefs.autoBackupFrequency, prefs.lastBackupAt, now)) {
      final svc = c.read(backupServiceProvider);
      final r = await svc.create(baseCurrency: prefs.baseCurrency);
      if (r.isOk) {
        await svc.rotate(prefs.autoBackupKeep);
        await c.read(settingsRepoProvider).set(SettingKeys.lastBackupAt, now);
      }
    }
    if (full) await c.read(attachmentStoreProvider).cleanupOrphans();
  } on Object catch (e, st) {
    AppLogger.error('startup', e, st);
  }
}
