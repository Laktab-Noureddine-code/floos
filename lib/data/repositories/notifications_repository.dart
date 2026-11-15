import 'package:drift/drift.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/repositories/repo_base.dart';

/// Notification types (APP_PROMPT §8, §6.11).
abstract final class NotifType {
  static const budget = 'budget';
  static const bill = 'bill';
  static const pending = 'pending';
  static const goal = 'goal';
  static const debt = 'debt';
  static const daily = 'daily';
  static const backup = 'backup';
  static const summary = 'summary';
}

/// Local notification center log (always written, even without permission).
class NotificationsRepository extends RepoBase {
  NotificationsRepository(super.db, {super.clock});

  Stream<List<NotificationRow>> watchAll() => db.notificationsDao.watchAll();

  Stream<int> watchUnread() => db.notificationsDao.watchUnread();

  Future<void> log({
    required String type,
    required String title,
    required String body,
    String? route,
  }) {
    final now = nowMs;
    return db.notificationsDao.add(
      NotificationsLogCompanion.insert(
        id: newId(),
        createdAt: now,
        updatedAt: now,
        type: type,
        title: title,
        body: body,
        route: Value(route),
      ),
    );
  }

  Future<void> markRead(String id) => db.notificationsDao.markRead(id);

  Future<void> markAllRead() => db.notificationsDao.markAllRead();

  Future<void> clear() => db.notificationsDao.clear();
}
