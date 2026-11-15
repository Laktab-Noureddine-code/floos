import 'package:floos/app/services/notification_gateway.dart';
import 'package:floos/data/repositories/notifications_repository.dart';
import 'package:floos/data/repositories/settings_repository.dart';

/// Emits immediate alerts: always logged in the notification center, shown
/// as a system notification only when allowed (APP_PROMPT §8, §13.15).
class AlertService {
  AlertService({required this.log, required this.gateway, required this.settings});

  final NotificationsRepository log;
  final NotificationGateway gateway;
  final SettingsRepository settings;

  Future<void> emit({
    required String type,
    required NotifChannel channel,
    required String key,
    required String title,
    required String body,
    String? route,
    bool Function(AppPrefs p)? enabled,
  }) async {
    await log.log(type: type, title: title, body: body, route: route);
    final prefs = await settings.load();
    if (!prefs.notifMaster || !(enabled?.call(prefs) ?? true)) return;
    if (!await gateway.isPermitted()) return;
    await gateway.show(notifId(key), channel, title, body, route: route);
  }
}
