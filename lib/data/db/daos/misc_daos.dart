import 'package:drift/drift.dart';

import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/db/tables/tables.dart';

part 'misc_daos.g.dart';

@DriftAccessor(tables: [Tags, TransactionTags])
class TagsDao extends DatabaseAccessor<AppDatabase> with _$TagsDaoMixin {
  TagsDao(super.attachedDatabase);

  Stream<List<TagRow>> watchAll() =>
      (select(tags)..orderBy([(t) => OrderingTerm(expression: t.name.lower())])).watch();

  Future<List<TagRow>> getAll() =>
      (select(tags)..orderBy([(t) => OrderingTerm(expression: t.name.lower())])).get();

  Future<TagRow?> byName(String name) async {
    final rows = await customSelect(
      'SELECT * FROM tags WHERE lower(name) = lower(?)',
      variables: [Variable(name.trim())],
      readsFrom: {tags},
    ).get();
    return rows.isEmpty ? null : tags.map(rows.first.data);
  }

  Future<void> upsert(TagsCompanion c) => into(tags).insertOnConflictUpdate(c);

  Future<int> deleteById(String id) => (delete(tags)..where((t) => t.id.equals(id))).go();

  Stream<Map<String, int>> watchUsage() => customSelect(
    'SELECT tag_id, count(*) AS n FROM transaction_tags GROUP BY tag_id',
    readsFrom: {transactionTags},
  ).watch().map((rows) => {for (final r in rows) r.read<String>('tag_id'): r.read<int>('n')});
}

@DriftAccessor(tables: [Attachments])
class AttachmentsDao extends DatabaseAccessor<AppDatabase> with _$AttachmentsDaoMixin {
  AttachmentsDao(super.attachedDatabase);

  Future<List<AttachmentRow>> forTransaction(String txId) =>
      (select(attachments)..where((a) => a.transactionId.equals(txId))).get();

  Future<List<AttachmentRow>> forTransactions(Iterable<String> txIds) =>
      (select(attachments)..where((a) => a.transactionId.isIn(txIds))).get();

  Future<List<AttachmentRow>> getAll() => select(attachments).get();

  Future<void> insertRow(AttachmentsCompanion c) => into(attachments).insert(c);

  Future<int> deleteById(String id) =>
      (delete(attachments)..where((a) => a.id.equals(id))).go();
}

@DriftAccessor(tables: [ExchangeRates])
class RatesDao extends DatabaseAccessor<AppDatabase> with _$RatesDaoMixin {
  RatesDao(super.attachedDatabase);

  Stream<List<RateRow>> watchAll() => (select(exchangeRates)
        ..orderBy([
          (r) => OrderingTerm(expression: r.fromCode),
          (r) => OrderingTerm(expression: r.toCode),
          (r) => OrderingTerm(expression: r.date, mode: OrderingMode.desc),
        ]))
      .watch();

  Future<List<RateRow>> getAll() => select(exchangeRates).get();

  Future<void> upsertRate(RateRow r) => into(exchangeRates).insert(
    r,
    onConflict: DoUpdate(
      (_) => ExchangeRatesCompanion(rateE6: Value(r.rateE6), updatedAt: Value(r.updatedAt)),
      target: [exchangeRates.fromCode, exchangeRates.toCode, exchangeRates.date],
    ),
  );

  Future<int> deleteById(String id) =>
      (delete(exchangeRates)..where((r) => r.id.equals(id))).go();
}

@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.attachedDatabase);

  Future<Map<String, String>> getAll() async {
    final rows = await select(appSettings).get();
    return {for (final r in rows) r.key: r.value};
  }

  Stream<Map<String, String>> watchAll() => select(appSettings)
      .watch()
      .map((rows) => {for (final r in rows) r.key: r.value});

  Future<void> put(String key, String value, int now) => into(appSettings).insertOnConflictUpdate(
    AppSettingsCompanion.insert(key: key, value: value, updatedAt: now),
  );

  Future<int> remove(String key) =>
      (delete(appSettings)..where((s) => s.key.equals(key))).go();
}

@DriftAccessor(tables: [NotificationsLog])
class NotificationsDao extends DatabaseAccessor<AppDatabase> with _$NotificationsDaoMixin {
  NotificationsDao(super.attachedDatabase);

  Stream<List<NotificationRow>> watchAll() => (select(notificationsLog)
        ..orderBy([(n) => OrderingTerm(expression: n.createdAt, mode: OrderingMode.desc)])
        ..limit(300))
      .watch();

  Stream<int> watchUnread() => customSelect(
    'SELECT count(*) AS c FROM notifications_log WHERE read = 0',
    readsFrom: {notificationsLog},
  ).watchSingle().map((r) => r.read<int>('c'));

  Future<void> add(NotificationsLogCompanion c) => into(notificationsLog).insert(c);

  Future<void> markRead(String id) => (update(notificationsLog)..where((n) => n.id.equals(id)))
      .write(const NotificationsLogCompanion(read: Value(true)));

  Future<void> markAllRead() =>
      update(notificationsLog).write(const NotificationsLogCompanion(read: Value(true)));

  Future<void> clear() => delete(notificationsLog).go();
}

@DriftAccessor(tables: [ErrorLog])
class ErrorLogDao extends DatabaseAccessor<AppDatabase> with _$ErrorLogDaoMixin {
  ErrorLogDao(super.attachedDatabase);

  static const maxRows = 500;

  Stream<List<ErrorRow>> watchAll() => (select(errorLog)
        ..orderBy([(e) => OrderingTerm(expression: e.createdAt, mode: OrderingMode.desc)]))
      .watch();

  Future<List<ErrorRow>> getAll() => (select(errorLog)
        ..orderBy([(e) => OrderingTerm(expression: e.createdAt, mode: OrderingMode.desc)]))
      .get();

  Future<void> add(String kind, String message, String? stack, int now) async {
    await into(errorLog).insert(
      ErrorLogCompanion.insert(createdAt: now, kind: kind, message: message, stack: Value(stack)),
    );
    await customStatement(
      'DELETE FROM error_log WHERE id NOT IN (SELECT id FROM error_log ORDER BY id DESC LIMIT $maxRows)',
    );
  }

  Future<void> clear() => delete(errorLog).go();
}
