import 'dart:io';

import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Notification channels, one per type (APP_PROMPT §8).
enum NotifChannel {
  budgetAlerts,
  billReminders,
  pendingRecurring,
  goalMilestones,
  debtDue,
  dailyReminder,
  backup;

  String get id => switch (this) {
    NotifChannel.budgetAlerts => 'budget_alerts',
    NotifChannel.billReminders => 'bill_reminders',
    NotifChannel.pendingRecurring => 'pending_recurring',
    NotifChannel.goalMilestones => 'goal_milestones',
    NotifChannel.debtDue => 'debt_due',
    NotifChannel.dailyReminder => 'daily_reminder',
    NotifChannel.backup => 'backup',
  };

  String name(AppLocalizations l) => switch (this) {
    NotifChannel.budgetAlerts => l.channelBudget,
    NotifChannel.billReminders => l.channelBills,
    NotifChannel.pendingRecurring => l.channelPending,
    NotifChannel.goalMilestones => l.channelGoals,
    NotifChannel.debtDue => l.channelDebts,
    NotifChannel.dailyReminder => l.channelDaily,
    NotifChannel.backup => l.channelBackup,
  };
}

/// A scheduled notification request.
@immutable
class ScheduledNotif {
  const ScheduledNotif({
    required this.id,
    required this.channel,
    required this.title,
    required this.body,
    required this.when,
    this.route,
    this.daily = false,
  });

  final int id;
  final NotifChannel channel;
  final String title;
  final String body;
  final DateTime when;
  final String? route;
  final bool daily;
}

/// Abstraction over the platform plugin so tests use a fake.
abstract class NotificationGateway {
  Future<void> init(void Function(String? route) onTap);
  Future<bool> isPermitted();
  Future<bool> requestPermission();
  Future<void> show(int id, NotifChannel channel, String title, String body, {String? route});
  Future<void> scheduleAll(List<ScheduledNotif> items);
  Future<void> cancelScheduled();

  /// Route of the notification that launched the app, if any.
  Future<String?> launchRoute();
}

/// Deterministic notification id from a key (stable across runs).
int notifId(String key) {
  var h = 0x811c9dc5;
  for (final c in key.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0x7fffffff;
  }
  return h;
}

/// flutter_local_notifications implementation.
class LocalNotificationGateway implements NotificationGateway {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _icon = '@mipmap/ic_launcher';

  AppLocalizations get _l => lookupAppLocalizations(appLocale);

  @override
  Future<void> init(void Function(String? route) onTap) async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name.identifier));
    } on Object catch (e, st) {
      AppLogger.error('timezone', e, st);
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_icon),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        linux: LinuxInitializationSettings(defaultActionName: 'Ouvrir'),
      ),
      onDidReceiveNotificationResponse: (r) => onTap(r.payload),
    );
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    for (final c in NotifChannel.values) {
      await android?.createNotificationChannel(
        AndroidNotificationChannel(c.id, c.name(_l), importance: Importance.high),
      );
    }
    _ready = true;
  }

  @override
  Future<bool> isPermitted() async {
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;
    }
    if (Platform.isIOS) {
      final s = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      return s?.isEnabled ?? false;
    }
    return true;
  }

  @override
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final a = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final ok = await a?.requestNotificationsPermission() ?? false;
      // Exact alarms are optional: inexact fallback is used when refused.
      if (ok && !(await a?.canScheduleExactNotifications() ?? true)) {
        await a?.requestExactAlarmsPermission();
      }
      return ok;
    }
    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return true;
  }

  NotificationDetails _details(NotifChannel c) => NotificationDetails(
    android: AndroidNotificationDetails(
      c.id,
      c.name(_l),
      importance: Importance.high,
      priority: Priority.high,
      icon: _icon,
      // Lock screen shows only the app name; content is in the body.
      visibility: NotificationVisibility.private,
    ),
    iOS: const DarwinNotificationDetails(),
  );

  @override
  Future<void> show(int id, NotifChannel channel, String title, String body, {String? route}) async {
    try {
      await _plugin.show(id: id, title: title, body: body, notificationDetails: _details(channel), payload: route);
    } on Object catch (e, st) {
      AppLogger.error('notif_show', e, st);
    }
  }

  @override
  Future<void> scheduleAll(List<ScheduledNotif> items) async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final exact = await android?.canScheduleExactNotifications() ?? false;
    for (final n in items) {
      try {
        await _plugin.zonedSchedule(
          id: n.id,
          scheduledDate: tz.TZDateTime.from(n.when, tz.local),
          notificationDetails: _details(n.channel),
          androidScheduleMode: exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
          title: n.title,
          body: n.body,
          payload: n.route,
          matchDateTimeComponents: n.daily ? DateTimeComponents.time : null,
        );
      } on Object catch (e, st) {
        AppLogger.error('notif_schedule', e, st);
      }
    }
  }

  @override
  Future<void> cancelScheduled() => _plugin.cancelAllPendingNotifications();

  @override
  Future<String?> launchRoute() async {
    final d = await _plugin.getNotificationAppLaunchDetails();
    return d?.didNotificationLaunchApp ?? false ? d!.notificationResponse?.payload : null;
  }
}

/// In-memory gateway for tests and hosts without notification support.
class FakeNotificationGateway implements NotificationGateway {
  final shown = <(int, NotifChannel, String, String)>[];
  final scheduled = <ScheduledNotif>[];
  bool permitted = true;

  @override
  Future<void> init(void Function(String? route) onTap) async {}

  @override
  Future<bool> isPermitted() async => permitted;

  @override
  Future<bool> requestPermission() async => permitted;

  @override
  Future<void> show(int id, NotifChannel channel, String title, String body, {String? route}) async =>
      shown.add((id, channel, title, body));

  @override
  Future<void> scheduleAll(List<ScheduledNotif> items) async => scheduled.addAll(items);

  @override
  Future<void> cancelScheduled() async => scheduled.clear();

  @override
  Future<String?> launchRoute() async => null;
}
