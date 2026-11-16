import 'dart:async';

import 'package:floos/app/providers.dart';
import 'package:floos/app/services/notification_gateway.dart';
import 'package:floos/app/services_providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/core/widgets/states.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

final _notifListProvider = StreamProvider<List<NotificationRow>>((ref) => ref.watch(notificationsRepoProvider).watchAll());

/// Notification center (bell on Home).
class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final repo = ref.read(notificationsRepoProvider);
    final rows = ref.watch(_notifListProvider).value ?? const <NotificationRow>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(l.notifCenterTitle),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => v == 'read' ? repo.markAllRead() : repo.clear(),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'read', child: Text(l.notifMarkAllRead)),
              PopupMenuItem(value: 'clear', child: Text(l.notifClear)),
            ],
          ),
        ],
      ),
      body: rows.isEmpty
          ? EmptyState(illustration: Illustration.notifications, message: l.notifCenterEmpty)
          : ListView(
              padding: const EdgeInsets.all(AppSpace.screen),
              children: [
                for (final n in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.sm),
                    child: AppCard(
                      onTap: () async {
                        await repo.markRead(n.id);
                        if (n.route != null && context.mounted) await context.push(n.route!);
                      },
                      child: Row(
                        children: [
                          if (!n.read) Container(width: 8, height: 8, margin: const EdgeInsets.only(right: AppSpace.sm), decoration: BoxDecoration(color: context.colors.primary, shape: BoxShape.circle)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.title, style: context.text.bodyM.copyWith(fontWeight: n.read ? FontWeight.w400 : FontWeight.w600)),
                                Text(n.body, style: context.text.bodyS),
                                Text(DateFormat('d MMM, HH:mm', appLocaleName).format(DateTime.fromMillisecondsSinceEpoch(n.createdAt)), style: context.text.caption),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Settings › Notifications.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  bool? _permitted;

  @override
  void initState() {
    super.initState();
    unawaited(_check());
  }

  Future<void> _check() async {
    final p = await ref.read(notificationGatewayProvider).isPermitted();
    if (mounted) setState(() => _permitted = p);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = ref.watch(prefsProvider);
    final repo = ref.read(settingsRepoProvider);
    final gw = ref.read(notificationGatewayProvider);
    Future<void> set(String k, bool v) async {
      if (v && _permitted == false) {
        final ok = await gw.requestPermission();
        if (!ok) {
          await _check();
          return;
        }
      }
      await repo.set(k, v);
      await ref.read(notificationSchedulerProvider).rescheduleAll();
      await _check();
    }

    final t = p.notifDailyTime;
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsNotifications)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: [
          if (_permitted == false)
            Container(
              padding: const EdgeInsets.all(AppSpace.md),
              margin: const EdgeInsets.only(bottom: AppSpace.md),
              decoration: BoxDecoration(color: context.colors.warningTint, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.notifPermissionDenied, style: context.text.bodyS),
                  TextButton(
                    onPressed: () async {
                      await gw.requestPermission();
                      await _check();
                    },
                    child: Text(l.notifRequestPermission),
                  ),
                ],
              ),
            ),
          SettingsGroup(
            children: [
              SwitchRow(label: l.notifSettingsMaster, value: p.notifMaster, onChanged: (v) => set(SettingKeys.notifMaster, v)),
              if (p.notifMaster) ...[
                SwitchRow(label: l.notifSettingsBudget, value: p.notifBudget, onChanged: (v) => set(SettingKeys.notifBudget, v)),
                SwitchRow(label: l.notifSettingsBills, value: p.notifBills, onChanged: (v) => set(SettingKeys.notifBills, v)),
                SwitchRow(label: l.notifSettingsGoals, value: p.notifGoals, onChanged: (v) => set(SettingKeys.notifGoals, v)),
                SwitchRow(label: l.notifSettingsDebts, value: p.notifDebts, onChanged: (v) => set(SettingKeys.notifDebts, v)),
                SwitchRow(label: l.notifSettingsBackup, value: p.notifBackup, onChanged: (v) => set(SettingKeys.notifBackup, v)),
                SwitchRow(label: l.notifSettingsDaily, value: p.notifDaily, onChanged: (v) => set(SettingKeys.notifDaily, v)),
                if (p.notifDaily)
                  SettingsRow(
                    label: l.notifSettingsDailyTime,
                    value: '${(t ~/ 60).toString().padLeft(2, '0')}:${(t % 60).toString().padLeft(2, '0')}',
                    onTap: () async {
                      final r = await showTimePicker(context: context, initialTime: TimeOfDay(hour: t ~/ 60, minute: t % 60));
                      if (r != null) {
                        await repo.set(SettingKeys.notifDailyTime, r.hour * 60 + r.minute);
                        await ref.read(notificationSchedulerProvider).rescheduleAll();
                      }
                    },
                  ),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          PrimaryButton(
            label: l.notifSendTest,
            secondary: true,
            onPressed: () => gw.show(notifId('test'), NotifChannel.budgetAlerts, l.notifTestTitle, l.notifTestBody),
          ),
        ],
      ),
    );
  }
}
