import 'package:drift/drift.dart';

import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/db/tables/tables.dart';

part 'accounts_dao.g.dart';

/// Per-account balance aggregate (source currency, minor units).
class AccountFlow {
  const AccountFlow(this.accountId, this.delta);
  final String accountId;
  final int delta;
}

@DriftAccessor(tables: [Accounts, Transactions])
class AccountsDao extends DatabaseAccessor<AppDatabase> with _$AccountsDaoMixin {
  AccountsDao(super.attachedDatabase);

  Stream<List<AccountRow>> watchAll() => (select(accounts)
        ..orderBy([(a) => OrderingTerm(expression: a.sortOrder), (a) => OrderingTerm(expression: a.createdAt)]))
      .watch();

  Future<List<AccountRow>> getAll() => (select(accounts)
        ..orderBy([(a) => OrderingTerm(expression: a.sortOrder)]))
      .get();

  Future<AccountRow?> byId(String id) =>
      (select(accounts)..where((a) => a.id.equals(id))).getSingleOrNull();

  Stream<AccountRow?> watchById(String id) =>
      (select(accounts)..where((a) => a.id.equals(id))).watchSingleOrNull();

  Future<void> upsert(AccountsCompanion c) => into(accounts).insertOnConflictUpdate(c);

  Future<int> deleteById(String id) =>
      (delete(accounts)..where((a) => a.id.equals(id))).go();

  Future<bool> nameTaken(String name, {String? exceptId}) async {
    final rows = await customSelect(
      'SELECT id FROM accounts WHERE archived = 0 AND lower(name) = lower(?) AND id != ?',
      variables: [Variable(name.trim()), Variable(exceptId ?? '')],
      readsFrom: {accounts},
    ).get();
    return rows.isNotEmpty;
  }

  Future<int> maxSortOrder() async {
    final r = await customSelect(
      'SELECT coalesce(max(sort_order), -1) AS m FROM accounts',
      readsFrom: {accounts},
    ).getSingle();
    return r.read<int>('m');
  }

  Future<int> transactionCount(String accountId) async {
    final r = await customSelect(
      'SELECT count(*) AS c FROM transactions WHERE account_id = ?1 OR to_account_id = ?1',
      variables: [Variable(accountId)],
      readsFrom: {transactions},
    ).getSingle();
    return r.read<int>('c');
  }

  static const _flowSql = '''
    SELECT account_id AS acc, SUM(CASE type WHEN 'income' THEN amount ELSE -amount END) AS d
      FROM transactions WHERE is_pending = 0 AND date < ?1 GROUP BY account_id
    UNION ALL
    SELECT to_account_id AS acc, SUM(coalesce(to_amount, amount)) AS d
      FROM transactions WHERE is_pending = 0 AND type = 'transfer' AND date < ?1
      GROUP BY to_account_id
  ''';

  /// Σ of transaction effects per account strictly before [beforeMs]
  /// (balance = initial + flow). Excludes pending items (APP_PROMPT §5.3).
  Future<Map<String, int>> flows(int beforeMs) async {
    final rows = await customSelect(
      _flowSql,
      variables: [Variable(beforeMs)],
      readsFrom: {transactions},
    ).get();
    return _fold(rows);
  }

  Stream<Map<String, int>> watchFlows(int beforeMs) => customSelect(
    _flowSql,
    variables: [Variable(beforeMs)],
    readsFrom: {transactions, accounts},
  ).watch().map(_fold);

  Map<String, int> _fold(List<QueryRow> rows) {
    final out = <String, int>{};
    for (final r in rows) {
      final acc = r.read<String>('acc');
      out[acc] = (out[acc] ?? 0) + r.read<int>('d');
    }
    return out;
  }

  /// Daily net flow for one account (for balance charts).
  Future<List<(int date, int delta)>> dailyFlow(String accountId, int fromMs, int toMs) async {
    final rows = await customSelect(
      '''
      SELECT date, SUM(d) AS d FROM (
        SELECT date, CASE type WHEN 'income' THEN amount ELSE -amount END AS d
          FROM transactions WHERE is_pending = 0 AND account_id = ?1 AND date >= ?2 AND date < ?3
        UNION ALL
        SELECT date, coalesce(to_amount, amount) AS d
          FROM transactions WHERE is_pending = 0 AND type = 'transfer' AND to_account_id = ?1
            AND date >= ?2 AND date < ?3
      ) GROUP BY date ORDER BY date
      ''',
      variables: [Variable(accountId), Variable(fromMs), Variable(toMs)],
      readsFrom: {transactions},
    ).get();
    return [for (final r in rows) (r.read<int>('date'), r.read<int>('d'))];
  }
}
