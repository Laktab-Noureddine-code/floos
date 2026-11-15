import 'package:drift/drift.dart';

import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/db/tables/tables.dart';

part 'transactions_dao.g.dart';

/// Comparison operator for amount search (`=45`, `>100`, `<20`).
enum AmountOp { eq, gt, lt, gte, lte }

/// Filter applied to transaction lists, totals and exports.
class TxFilter {
  const TxFilter({
    this.startMs,
    this.endExclusiveMs,
    this.types = const {},
    this.accountIds = const {},
    this.categoryIds = const {},
    this.tagIds = const {},
    this.minAmount,
    this.maxAmount,
    this.hasAttachment = false,
    this.pendingOnly = false,
    this.includePending = false,
    this.pinnedOnly = false,
    this.text,
    this.amountOp,
    this.amountValue,
    this.recurringRuleId,
    this.debtId,
    this.goalId,
    this.ids,
  });

  final int? startMs;
  final int? endExclusiveMs;
  final Set<String> types;
  final Set<String> accountIds;
  final Set<String> categoryIds;
  final Set<String> tagIds;
  final int? minAmount;
  final int? maxAmount;
  final bool hasAttachment;
  final bool pendingOnly;
  final bool includePending;
  final bool pinnedOnly;
  final String? text;
  final AmountOp? amountOp;
  final int? amountValue;
  final String? recurringRuleId;
  final String? debtId;
  final String? goalId;
  final Set<String>? ids;

  bool get isEmpty =>
      types.isEmpty &&
      accountIds.isEmpty &&
      categoryIds.isEmpty &&
      tagIds.isEmpty &&
      minAmount == null &&
      maxAmount == null &&
      !hasAttachment &&
      !pendingOnly &&
      (text == null || text!.trim().isEmpty) &&
      amountOp == null;

  TxFilter copyWith({
    int? startMs,
    int? endExclusiveMs,
    Set<String>? types,
    Set<String>? accountIds,
    Set<String>? categoryIds,
    Set<String>? tagIds,
    int? Function()? minAmount,
    int? Function()? maxAmount,
    bool? hasAttachment,
    bool? pendingOnly,
    bool? includePending,
    bool? pinnedOnly,
    String? Function()? text,
    AmountOp? Function()? amountOp,
    int? Function()? amountValue,
    bool clearRange = false,
  }) => TxFilter(
    startMs: clearRange ? null : (startMs ?? this.startMs),
    endExclusiveMs: clearRange ? null : (endExclusiveMs ?? this.endExclusiveMs),
    types: types ?? this.types,
    accountIds: accountIds ?? this.accountIds,
    categoryIds: categoryIds ?? this.categoryIds,
    tagIds: tagIds ?? this.tagIds,
    minAmount: minAmount != null ? minAmount() : this.minAmount,
    maxAmount: maxAmount != null ? maxAmount() : this.maxAmount,
    hasAttachment: hasAttachment ?? this.hasAttachment,
    pendingOnly: pendingOnly ?? this.pendingOnly,
    includePending: includePending ?? this.includePending,
    pinnedOnly: pinnedOnly ?? this.pinnedOnly,
    text: text != null ? text() : this.text,
    amountOp: amountOp != null ? amountOp() : this.amountOp,
    amountValue: amountValue != null ? amountValue() : this.amountValue,
    recurringRuleId: recurringRuleId,
    debtId: debtId,
    goalId: goalId,
    ids: ids,
  );
}

/// Ordering for transaction lists.
enum TxOrder { dateDesc, updatedDesc, pinnedThenDate }

/// A transaction joined with display data.
class TxView {
  const TxView({
    required this.tx,
    required this.accountName,
    required this.accountCurrency,
    required this.accountColor,
    required this.accountIcon,
    this.toAccountName,
    this.toAccountCurrency,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.parentCategoryId,
    this.parentCategoryName,
    this.attachmentCount = 0,
    this.tagNames = const [],
  });

  final TxRow tx;
  final String accountName;
  final String accountCurrency;
  final String accountColor;
  final String accountIcon;
  final String? toAccountName;
  final String? toAccountCurrency;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String? parentCategoryId;
  final String? parentCategoryName;
  final int attachmentCount;
  final List<String> tagNames;
}

/// Grouped aggregate row (key, currency, local-day ms, sum, count).
class AggRow {
  const AggRow(this.key, this.currency, this.date, this.sum, this.count);
  final String? key;
  final String currency;
  final int date;
  final int sum;
  final int count;
}

/// Grouping dimension for [TransactionsDao.aggregate].
enum AggKey { none, category, account, tag, payee }

@DriftAccessor(
  tables: [Transactions, Accounts, Categories, TransactionTags, Tags, Attachments],
)
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.attachedDatabase);

  Future<TxRow?> byId(String id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsert(TransactionsCompanion c) =>
      into(transactions).insertOnConflictUpdate(c);

  Future<int> insertIgnore(TransactionsCompanion c) =>
      into(transactions).insert(c, mode: InsertMode.insertOrIgnore);

  Future<int> deleteById(String id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  Future<List<String>> tagIdsFor(String txId) async {
    final rows = await (select(transactionTags)..where((t) => t.transactionId.equals(txId))).get();
    return [for (final r in rows) r.tagId];
  }

  Future<void> setTags(String txId, Iterable<String> tagIds) async {
    await (delete(transactionTags)..where((t) => t.transactionId.equals(txId))).go();
    for (final tag in tagIds.toSet()) {
      await into(transactionTags).insert(
        TransactionTagsCompanion.insert(transactionId: txId, tagId: tag),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }

  // ---------------------------------------------------------------- queries

  static const _viewCols = '''
    t.*, a.name AS a_name, a.currency_code AS a_cur, a.color AS a_color, a.icon AS a_icon,
    ta.name AS ta_name, ta.currency_code AS ta_cur,
    c.name AS c_name, c.icon AS c_icon, c.color AS c_color, c.parent_id AS c_parent,
    pc.name AS pc_name,
    (SELECT count(*) FROM attachments x WHERE x.transaction_id = t.id) AS att_count,
    (SELECT group_concat(g.name, '|') FROM transaction_tags tt JOIN tags g ON g.id = tt.tag_id
      WHERE tt.transaction_id = t.id) AS tag_names
  ''';

  static const _viewJoins = '''
    FROM transactions t
    JOIN accounts a ON a.id = t.account_id
    LEFT JOIN accounts ta ON ta.id = t.to_account_id
    LEFT JOIN categories c ON c.id = t.category_id
    LEFT JOIN categories pc ON pc.id = c.parent_id
  ''';

  (String, List<Variable<Object>>) _where(TxFilter f) {
    final w = <String>[];
    final v = <Variable<Object>>[];
    if (f.pendingOnly) {
      w.add('t.is_pending = 1');
    } else if (!f.includePending) {
      w.add('t.is_pending = 0');
    }
    if (f.startMs != null) {
      w.add('t.date >= ?');
      v.add(Variable(f.startMs));
    }
    if (f.endExclusiveMs != null) {
      w.add('t.date < ?');
      v.add(Variable(f.endExclusiveMs));
    }
    if (f.types.isNotEmpty) {
      w.add('t.type IN (${List.filled(f.types.length, '?').join(',')})');
      v.addAll(f.types.map(Variable.new));
    }
    if (f.accountIds.isNotEmpty) {
      final q = List.filled(f.accountIds.length, '?').join(',');
      w.add('(t.account_id IN ($q) OR t.to_account_id IN ($q))');
      v
        ..addAll(f.accountIds.map(Variable.new))
        ..addAll(f.accountIds.map(Variable.new));
    }
    if (f.categoryIds.isNotEmpty) {
      final q = List.filled(f.categoryIds.length, '?').join(',');
      w.add('(t.category_id IN ($q) OR c.parent_id IN ($q))');
      v
        ..addAll(f.categoryIds.map(Variable.new))
        ..addAll(f.categoryIds.map(Variable.new));
    }
    if (f.tagIds.isNotEmpty) {
      final q = List.filled(f.tagIds.length, '?').join(',');
      w.add('EXISTS (SELECT 1 FROM transaction_tags tt WHERE tt.transaction_id = t.id AND tt.tag_id IN ($q))');
      v.addAll(f.tagIds.map(Variable.new));
    }
    if (f.minAmount != null) {
      w.add('t.amount >= ?');
      v.add(Variable(f.minAmount));
    }
    if (f.maxAmount != null) {
      w.add('t.amount <= ?');
      v.add(Variable(f.maxAmount));
    }
    if (f.amountOp != null && f.amountValue != null) {
      final op = switch (f.amountOp!) {
        AmountOp.eq => '=',
        AmountOp.gt => '>',
        AmountOp.lt => '<',
        AmountOp.gte => '>=',
        AmountOp.lte => '<=',
      };
      w.add('t.amount $op ?');
      v.add(Variable(f.amountValue));
    }
    if (f.hasAttachment) {
      w.add('EXISTS (SELECT 1 FROM attachments x WHERE x.transaction_id = t.id)');
    }
    if (f.pinnedOnly) w.add('t.pinned = 1');
    if (f.recurringRuleId != null) {
      w.add('t.recurring_rule_id = ?');
      v.add(Variable(f.recurringRuleId));
    }
    if (f.debtId != null) {
      w.add('t.debt_id = ?');
      v.add(Variable(f.debtId));
    }
    if (f.goalId != null) {
      w.add('t.goal_id = ?');
      v.add(Variable(f.goalId));
    }
    if (f.ids != null) {
      if (f.ids!.isEmpty) {
        w.add('0');
      } else {
        w.add('t.id IN (${List.filled(f.ids!.length, '?').join(',')})');
        v.addAll(f.ids!.map(Variable.new));
      }
    }
    final text = ftsQuery(f.text?.trim() ?? '');
    if (text.isNotEmpty) {
      w.add('t.rowid IN (SELECT rowid FROM transactions_fts WHERE transactions_fts MATCH ?)');
      v.add(Variable(text));
    }
    return (w.isEmpty ? '' : 'WHERE ${w.join(' AND ')}', v);
  }

  /// Builds a safe FTS5 prefix query from free text.
  static String ftsQuery(String text) {
    final tokens = text
        .split(RegExp(r'\s+'))
        .map((s) => s.replaceAll(RegExp(r'["*^():\-]'), ''))
        .where((s) => s.isNotEmpty);
    return tokens.map((s) => '"$s"*').join(' ');
  }

  String _order(TxOrder o) => switch (o) {
    TxOrder.dateDesc =>
      'ORDER BY t.date DESC, coalesce(t.time_of_day_minutes, -1) DESC, t.created_at DESC',
    TxOrder.updatedDesc => 'ORDER BY t.updated_at DESC',
    TxOrder.pinnedThenDate =>
      'ORDER BY t.pinned DESC, t.date DESC, coalesce(t.time_of_day_minutes, -1) DESC, t.created_at DESC',
  };

  Selectable<TxView> _viewQuery(TxFilter f, TxOrder order, {int? limit, int? offset}) {
    final (where, vars) = _where(f);
    final lim = limit == null ? '' : 'LIMIT $limit OFFSET ${offset ?? 0}';
    return customSelect(
      'SELECT $_viewCols $_viewJoins $where ${_order(order)} $lim',
      variables: vars,
      readsFrom: {transactions, accounts, categories, transactionTags, tags, attachments},
    ).map(_mapView);
  }

  TxView _mapView(QueryRow r) {
    final tags = r.readNullable<String>('tag_names');
    return TxView(
      tx: transactions.map(r.data),
      accountName: r.read<String>('a_name'),
      accountCurrency: r.read<String>('a_cur'),
      accountColor: r.read<String>('a_color'),
      accountIcon: r.read<String>('a_icon'),
      toAccountName: r.readNullable<String>('ta_name'),
      toAccountCurrency: r.readNullable<String>('ta_cur'),
      categoryName: r.readNullable<String>('c_name'),
      categoryIcon: r.readNullable<String>('c_icon'),
      categoryColor: r.readNullable<String>('c_color'),
      parentCategoryId: r.readNullable<String>('c_parent'),
      parentCategoryName: r.readNullable<String>('pc_name'),
      attachmentCount: r.read<int>('att_count'),
      tagNames: tags == null || tags.isEmpty ? const [] : tags.split('|'),
    );
  }

  Stream<List<TxView>> watchView(TxFilter f, {TxOrder order = TxOrder.dateDesc, int? limit, int? offset}) =>
      _viewQuery(f, order, limit: limit, offset: offset).watch();

  Future<List<TxView>> getView(TxFilter f, {TxOrder order = TxOrder.dateDesc, int? limit, int? offset}) =>
      _viewQuery(f, order, limit: limit, offset: offset).get();

  Future<TxView?> viewById(String id) async {
    final r = await getView(TxFilter(ids: {id}, includePending: true));
    return r.isEmpty ? null : r.first;
  }

  /// Totals (source currency) per currency and type for a filter.
  Stream<List<(String currency, String type, int sum, int count)>> watchTotals(TxFilter f) {
    final (where, vars) = _where(f);
    return customSelect(
      'SELECT a.currency_code AS cur, t.type AS type, SUM(t.amount) AS s, count(*) AS n $_viewJoins $where GROUP BY cur, t.type',
      variables: vars,
      readsFrom: {transactions, accounts, categories, transactionTags, attachments},
    ).watch().map((rows) => [
          for (final r in rows)
            (r.read<String>('cur'), r.read<String>('type'), r.read<int>('s'), r.read<int>('n')),
        ]);
  }

  /// Running balance after each listed transaction for its source account
  /// (excluding initial balance), via a window function.
  Future<Map<String, int>> runningFlows(Set<String> accountIds, Set<String> txIds) async {
    if (accountIds.isEmpty || txIds.isEmpty) return {};
    final qa = List.filled(accountIds.length, '?').join(',');
    final qt = List.filled(txIds.length, '?').join(',');
    final rows = await customSelect(
      '''
      WITH legs AS (
        SELECT id, account_id AS acc, date, coalesce(time_of_day_minutes, -1) AS tm, created_at,
               CASE type WHEN 'income' THEN amount ELSE -amount END AS d, 1 AS src
          FROM transactions WHERE is_pending = 0 AND account_id IN ($qa)
        UNION ALL
        SELECT id, to_account_id AS acc, date, coalesce(time_of_day_minutes, -1) AS tm, created_at,
               coalesce(to_amount, amount) AS d, 0 AS src
          FROM transactions WHERE is_pending = 0 AND type = 'transfer' AND to_account_id IN ($qa)
      ), run AS (
        SELECT id, src, SUM(d) OVER (PARTITION BY acc ORDER BY date, tm, created_at, id, src
                                     ROWS UNBOUNDED PRECEDING) AS bal FROM legs
      )
      SELECT id, bal FROM run WHERE src = 1 AND id IN ($qt)
      ''',
      variables: [
        ...accountIds.map(Variable.new),
        ...accountIds.map(Variable.new),
        ...txIds.map(Variable.new),
      ],
      readsFrom: {transactions},
    ).get();
    return {for (final r in rows) r.read<String>('id'): r.read<int>('bal')};
  }

  /// Grouped sums for reports. Excludes pending and `exclude_from_reports`.
  Future<List<AggRow>> aggregate({
    required String type,
    required int startMs,
    required int endExclusiveMs,
    AggKey key = AggKey.none,
    Set<String> categoryIds = const {},
    String? accountId,
  }) {
    final keyExpr = switch (key) {
      AggKey.none => 'NULL',
      AggKey.category => 't.category_id',
      AggKey.account => 't.account_id',
      AggKey.tag => 'tt.tag_id',
      AggKey.payee => 'lower(trim(t.payee))',
    };
    final tagJoin = key == AggKey.tag ? 'JOIN transaction_tags tt ON tt.transaction_id = t.id' : '';
    final extra = <String>[];
    final vars = <Variable<Object>>[Variable(type), Variable(startMs), Variable(endExclusiveMs)];
    if (key == AggKey.payee) extra.add("t.payee IS NOT NULL AND trim(t.payee) != ''");
    if (categoryIds.isNotEmpty) {
      final q = List.filled(categoryIds.length, '?').join(',');
      extra.add('t.category_id IN ($q)');
      vars.addAll(categoryIds.map(Variable.new));
    }
    if (accountId != null) {
      extra.add('t.account_id = ?');
      vars.add(Variable(accountId));
    }
    final ex = extra.isEmpty ? '' : 'AND ${extra.join(' AND ')}';
    return customSelect(
      '''
      SELECT $keyExpr AS k, a.currency_code AS cur, t.date AS date, SUM(t.amount) AS s, count(*) AS n
        FROM transactions t JOIN accounts a ON a.id = t.account_id $tagJoin
       WHERE t.type = ? AND t.is_pending = 0 AND t.exclude_from_reports = 0
         AND t.date >= ? AND t.date < ? $ex
       GROUP BY k, cur, t.date
      ''',
      variables: vars,
      readsFrom: {transactions, accounts, transactionTags},
    ).map((r) => AggRow(
          r.readNullable<String>('k'),
          r.read<String>('cur'),
          r.read<int>('date'),
          r.read<int>('s'),
          r.read<int>('n'),
        )).get();
  }

  /// Emits whenever transactions change (for reactive recomputation).
  Stream<int> watchChangeTick() => customSelect(
    'SELECT count(*) AS c, coalesce(max(updated_at), 0) AS u FROM transactions',
    readsFrom: {transactions, transactionTags},
  ).watch().map((rows) => rows.first.read<int>('u') + rows.first.read<int>('c'));

  /// Payee suggestions with the category of their latest use.
  Future<List<(String payee, String? categoryId, String type)>> payees(String prefix, {int limit = 8}) async {
    final rows = await customSelect(
      '''SELECT payee, category_id, type, max(date * 10000 + coalesce(time_of_day_minutes, 0)) AS m
           FROM transactions WHERE payee IS NOT NULL AND payee != '' AND payee LIKE ? ESCAPE '\\'
          GROUP BY lower(payee) ORDER BY m DESC LIMIT ?''',
      variables: [Variable('${_escapeLike(prefix)}%'), Variable(limit)],
      readsFrom: {transactions},
    ).get();
    return [
      for (final r in rows)
        (r.read<String>('payee'), r.readNullable<String>('category_id'), r.read<String>('type')),
    ];
  }

  static String _escapeLike(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

  /// Expense amounts of a category since [sinceMs] (for median-based insights).
  Future<List<int>> categoryAmounts(String categoryId, int sinceMs) async {
    final rows = await customSelect(
      '''SELECT amount FROM transactions WHERE category_id = ? AND type = 'expense'
           AND is_pending = 0 AND date >= ? ORDER BY amount''',
      variables: [Variable(categoryId), Variable(sinceMs)],
      readsFrom: {transactions},
    ).get();
    return [for (final r in rows) r.read<int>('amount')];
  }

  Future<int?> lastTransactionDate() async {
    final r = await customSelect(
      'SELECT max(date) AS d FROM transactions WHERE is_pending = 0',
      readsFrom: {transactions},
    ).getSingle();
    return r.readNullable<int>('d');
  }

  Future<int> count({bool includePending = true}) async {
    final r = await customSelect(
      'SELECT count(*) AS c FROM transactions ${includePending ? '' : 'WHERE is_pending = 0'}',
      readsFrom: {transactions},
    ).getSingle();
    return r.read<int>('c');
  }

  /// Moves every transaction of [fromId] (source or destination) to [toId].
  Future<void> moveAccount(String fromId, String toId, int now) async {
    await customUpdate(
      'UPDATE transactions SET account_id = ?2, updated_at = ?3 WHERE account_id = ?1',
      variables: [Variable(fromId), Variable(toId), Variable(now)],
      updates: {transactions},
    );
    await customUpdate(
      'UPDATE transactions SET to_account_id = ?2, updated_at = ?3 WHERE to_account_id = ?1',
      variables: [Variable(fromId), Variable(toId), Variable(now)],
      updates: {transactions},
    );
    // A transfer may now point to itself: convert to expense-free no-op by deleting it.
    await customStatement(
      "DELETE FROM transactions WHERE type = 'transfer' AND account_id = to_account_id",
    );
  }

  Future<List<String>> idsForAccount(String accountId) async {
    final rows = await customSelect(
      'SELECT id FROM transactions WHERE account_id = ?1 OR to_account_id = ?1',
      variables: [Variable(accountId)],
      readsFrom: {transactions},
    ).get();
    return [for (final r in rows) r.read<String>('id')];
  }
}
