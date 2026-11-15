import 'package:drift/drift.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/money/money.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/time/period.dart';
import 'package:floos/core/utils/result.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/db/daos/transactions_dao.dart';
import 'package:floos/data/db/seed.dart';
import 'package:floos/data/repositories/repo_base.dart';
import 'package:floos/data/repositories/tags_rates_repositories.dart';

export 'package:floos/data/db/daos/transactions_dao.dart' show AggKey, AggRow, AmountOp, TxFilter, TxOrder, TxView;

/// Editable transaction data (form state → repository).
class TxDraft {
  const TxDraft({
    required this.type,
    required this.amount,
    required this.accountId,
    required this.day,
    this.id,
    this.toAccountId,
    this.toAmount,
    this.categoryId,
    this.timeMinutes,
    this.payee,
    this.note,
    this.tagIds = const [],
    this.recurringRuleId,
    this.debtId,
    this.goalId,
    this.pending = false,
    this.excludeFromReports = false,
    this.pinned = false,
  });

  factory TxDraft.fromRow(TxRow r, List<String> tagIds) => TxDraft(
    id: r.id,
    type: r.type,
    amount: r.amount,
    accountId: r.accountId,
    toAccountId: r.toAccountId,
    toAmount: r.toAmount,
    categoryId: r.categoryId,
    day: LocalDay.fromStorage(r.date),
    timeMinutes: r.timeOfDayMinutes,
    payee: r.payee,
    note: r.note,
    tagIds: tagIds,
    recurringRuleId: r.recurringRuleId,
    debtId: r.debtId,
    goalId: r.goalId,
    pending: r.isPending,
    excludeFromReports: r.excludeFromReports,
    pinned: r.pinned,
  );

  final String? id;
  final String type;
  final int amount;
  final String accountId;
  final String? toAccountId;
  final int? toAmount;
  final String? categoryId;
  final LocalDay day;
  final int? timeMinutes;
  final String? payee;
  final String? note;
  final List<String> tagIds;
  final String? recurringRuleId;
  final String? debtId;
  final String? goalId;
  final bool pending;
  final bool excludeFromReports;
  final bool pinned;

  TxDraft copyWith({
    String? id,
    int? amount,
    LocalDay? day,
    bool? pending,
    String? Function()? categoryId,
    String? Function()? accountId,
  }) => TxDraft(
    id: id ?? this.id,
    type: type,
    amount: amount ?? this.amount,
    accountId: accountId != null ? accountId()! : this.accountId,
    toAccountId: toAccountId,
    toAmount: toAmount,
    categoryId: categoryId != null ? categoryId() : this.categoryId,
    day: day ?? this.day,
    timeMinutes: timeMinutes,
    payee: payee,
    note: note,
    tagIds: tagIds,
    recurringRuleId: recurringRuleId,
    debtId: debtId,
    goalId: goalId,
    pending: pending ?? this.pending,
    excludeFromReports: excludeFromReports,
    pinned: pinned,
  );
}

/// Everything needed to undo a deletion.
class TxSnapshot {
  const TxSnapshot(this.row, this.tagIds, this.attachments, this.contributions);
  final TxRow row;
  final List<String> tagIds;
  final List<AttachmentRow> attachments;
  final List<ContributionRow> contributions;
}

class TransactionsRepository extends RepoBase {
  TransactionsRepository(super.db, {super.clock, super.hooks, this.onDeleteFiles});

  /// Removes attachment files after a deletion is final.
  final Future<void> Function(List<String> attachmentIds)? onDeleteFiles;

  TransactionsDao get _dao => db.transactionsDao;

  // ------------------------------------------------------------------ reads

  Stream<List<TxView>> watch(TxFilter f, {TxOrder order = TxOrder.dateDesc, int? limit, int? offset}) =>
      _dao.watchView(f, order: order, limit: limit, offset: offset);

  Future<List<TxView>> get(TxFilter f, {TxOrder order = TxOrder.dateDesc, int? limit, int? offset}) =>
      _dao.getView(f, order: order, limit: limit, offset: offset);

  Future<TxView?> view(String id) => _dao.viewById(id);

  Future<TxRow?> byId(String id) => _dao.byId(id);

  Future<List<String>> tagIds(String id) => _dao.tagIdsFor(id);

  Stream<List<(String, String, int, int)>> watchTotals(TxFilter f) => _dao.watchTotals(f);

  Stream<int> watchChanges() => _dao.watchChangeTick();

  Future<Map<String, int>> runningFlows(Set<String> accountIds, Set<String> txIds) =>
      _dao.runningFlows(accountIds, txIds);

  Future<List<(String, String?, String)>> payees(String prefix) => _dao.payees(prefix);

  Future<List<AggRow>> aggregate({
    required String type,
    required Period period,
    AggKey key = AggKey.none,
    Set<String> categoryIds = const {},
    String? accountId,
    LocalDay? capAt,
  }) {
    var end = period.endExclusiveMs;
    if (capAt != null) {
      final cap = capAt.addDays(1).toStorage();
      if (cap < end) end = cap;
    }
    return _dao.aggregate(
      type: type,
      startMs: period.startMs,
      endExclusiveMs: end,
      key: key,
      categoryIds: categoryIds,
      accountId: accountId,
    );
  }

  // ------------------------------------------------------------- validation

  Future<Result<void>> validate(TxDraft d) async {
    if (!const ['expense', 'income', 'transfer'].contains(d.type)) {
      return const Err(AppFailure.validation('tx_type_invalid'));
    }
    if (d.amount <= 0) return const Err(AppFailure.validation('amount_zero'));
    if (d.amount >= kMaxMinorUnits) return const Err(AppFailure.validation('amount_too_large'));
    final account = await db.accountsDao.byId(d.accountId);
    if (account == null) return const Err(AppFailure.validation('account_required'));
    if ((d.payee?.length ?? 0) > 60) return const Err(AppFailure.validation('payee_too_long'));
    if ((d.note?.length ?? 0) > 500) return const Err(AppFailure.validation('note_too_long'));
    if (d.timeMinutes != null && (d.timeMinutes! < 0 || d.timeMinutes! > 1439)) {
      return const Err(AppFailure.validation('time_invalid'));
    }
    if (d.type == 'transfer') {
      if (d.toAccountId == null) return const Err(AppFailure.validation('to_account_required'));
      if (d.toAccountId == d.accountId) return const Err(AppFailure.validation('same_account'));
      final to = await db.accountsDao.byId(d.toAccountId!);
      if (to == null) return const Err(AppFailure.validation('to_account_required'));
      if (to.currencyCode != account.currencyCode) {
        if (d.toAmount == null || d.toAmount! <= 0) {
          return const Err(AppFailure.validation('to_amount_required'));
        }
        if (d.toAmount! >= kMaxMinorUnits) return const Err(AppFailure.validation('amount_too_large'));
      }
    } else {
      if (d.categoryId == null) return const Err(AppFailure.validation('category_required'));
      final c = await db.categoriesDao.byId(d.categoryId!);
      if (c == null) return const Err(AppFailure.validation('category_required'));
      if (c.kind != d.type && c.systemKey != SystemCategory.adjustment) {
        return const Err(AppFailure.validation('category_kind_mismatch'));
      }
    }
    return const Ok(null);
  }

  // ----------------------------------------------------------------- writes

  /// Creates or updates a transaction (with tags and optional goal link).
  Future<Result<String>> save(TxDraft d) => guard(() async {
    final v = await validate(d);
    if (v case Err(:final failure)) return Err(failure);
    final days = <int>{d.day.toStorage()};
    final id = d.id ?? newId();
    final now = nowMs;
    await db.transaction(() async {
      final existing = d.id == null ? null : await _dao.byId(d.id!);
      if (existing != null) days.add(existing.date);
      final account = (await db.accountsDao.byId(d.accountId))!;
      final to = d.toAccountId == null ? null : await db.accountsDao.byId(d.toAccountId!);
      final sameCurrency = to == null || to.currencyCode == account.currencyCode;
      await _dao.upsert(
        TransactionsCompanion(
          id: Value(id),
          createdAt: Value(existing?.createdAt ?? now),
          updatedAt: Value(now),
          type: Value(d.type),
          amount: Value(d.amount),
          accountId: Value(d.accountId),
          toAccountId: Value(d.type == 'transfer' ? d.toAccountId : null),
          toAmount: Value(d.type == 'transfer' && !sameCurrency ? d.toAmount : null),
          categoryId: Value(d.type == 'transfer' ? null : d.categoryId),
          date: Value(d.day.toStorage()),
          timeOfDayMinutes: Value(d.timeMinutes),
          payee: Value(_clean(d.payee)),
          note: Value(_clean(d.note)),
          recurringRuleId: Value(d.recurringRuleId),
          debtId: Value(d.debtId),
          goalId: Value(d.goalId),
          isPending: Value(d.pending),
          excludeFromReports: Value(d.excludeFromReports),
          pinned: Value(d.pinned),
        ),
      );
      await _dao.setTags(id, d.tagIds);
      await _syncGoalContribution(id, d, account.currencyCode, now);
    });
    await hooks.onTransactionsChanged(days);
    return Ok(id);
  });

  /// Keeps a goal contribution in sync with a goal-linked transaction.
  Future<void> _syncGoalContribution(String txId, TxDraft d, String currency, int now) async {
    final existing = await (db.select(db.goalContributions)..where((c) => c.transactionId.equals(txId))).get();
    if (d.goalId == null) {
      for (final c in existing) {
        await db.goalsDao.deleteContribution(c.id);
      }
      return;
    }
    final prefs = await db.settingsDao.getAll();
    final base = prefs['base_currency'] ?? currency;
    final fx = await RatesRepository(db).fx();
    final converted = fx.convertMinor(d.amount, currency, base, d.day).valueOrNull ?? d.amount;
    // Expense/transfer into savings = contribution; income from goal = withdrawal.
    final signed = d.type == 'income' ? -converted : converted;
    await db.goalsDao.addContribution(
      GoalContributionsCompanion(
        id: Value(existing.isEmpty ? newId() : existing.first.id),
        createdAt: Value(existing.isEmpty ? now : existing.first.createdAt),
        updatedAt: Value(now),
        goalId: Value(d.goalId!),
        amount: Value(signed),
        date: Value(d.day.toStorage()),
        note: Value(_clean(d.note)),
        transactionId: Value(txId),
      ),
    );
  }

  static String? _clean(String? s) {
    final t = s?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  Future<TxSnapshot?> _snapshot(String id) async {
    final row = await _dao.byId(id);
    if (row == null) return null;
    return TxSnapshot(
      row,
      await _dao.tagIdsFor(id),
      await db.attachmentsDao.forTransaction(id),
      await (db.select(db.goalContributions)..where((c) => c.transactionId.equals(id))).get(),
    );
  }

  /// Deletes transactions and returns snapshots for Undo. Attachment files
  /// are removed by [finalizeDelete] once the undo window has passed.
  Future<Result<List<TxSnapshot>>> deleteMany(Iterable<String> ids) => guard(() async {
    final snaps = <TxSnapshot>[];
    await db.transaction(() async {
      for (final id in ids) {
        final s = await _snapshot(id);
        if (s == null) continue;
        snaps.add(s);
        await (db.delete(db.goalContributions)..where((c) => c.transactionId.equals(id))).go();
        await _dao.deleteById(id);
      }
    });
    await hooks.onTransactionsChanged({for (final s in snaps) s.row.date});
    return Ok(snaps);
  });

  Future<Result<List<TxSnapshot>>> delete(String id) => deleteMany([id]);

  /// Restores deleted transactions (Undo).
  Future<Result<void>> restore(List<TxSnapshot> snaps) => guard(() async {
    await db.transaction(() async {
      for (final s in snaps) {
        await db.into(db.transactions).insertOnConflictUpdate(s.row);
        await _dao.setTags(s.row.id, s.tagIds);
        for (final a in s.attachments) {
          await db.into(db.attachments).insertOnConflictUpdate(a);
        }
        for (final c in s.contributions) {
          await db.into(db.goalContributions).insertOnConflictUpdate(c);
        }
      }
    });
    await hooks.onTransactionsChanged({for (final s in snaps) s.row.date});
    return const Ok(null);
  });

  /// Removes attachment files of deleted transactions (after Undo expired).
  Future<void> finalizeDelete(List<TxSnapshot> snaps) async {
    final ids = [for (final s in snaps) ...s.attachments.map((a) => a.id)];
    if (ids.isNotEmpty) await onDeleteFiles?.call(ids);
  }

  Future<Result<void>> setPinned(String id, {required bool pinned}) => guard(() async {
    await (db.update(db.transactions)..where((t) => t.id.equals(id)))
        .write(TransactionsCompanion(pinned: Value(pinned)));
    return const Ok(null);
  });

  Future<Result<void>> changeCategory(Iterable<String> ids, String categoryId) => guard(() async {
    final c = await db.categoriesDao.byId(categoryId);
    if (c == null) return const Err(AppFailure.notFound('category_not_found'));
    final days = <int>{};
    await db.transaction(() async {
      for (final id in ids) {
        final r = await _dao.byId(id);
        if (r == null || r.type != c.kind) continue;
        days.add(r.date);
        await (db.update(db.transactions)..where((t) => t.id.equals(id)))
            .write(TransactionsCompanion(categoryId: Value(categoryId), updatedAt: Value(nowMs)));
      }
    });
    await hooks.onTransactionsChanged(days);
    return const Ok(null);
  });

  Future<Result<void>> changeAccount(Iterable<String> ids, String accountId) => guard(() async {
    final days = <int>{};
    await db.transaction(() async {
      for (final id in ids) {
        final r = await _dao.byId(id);
        if (r == null || r.toAccountId == accountId) continue;
        days.add(r.date);
        await (db.update(db.transactions)..where((t) => t.id.equals(id)))
            .write(TransactionsCompanion(accountId: Value(accountId), updatedAt: Value(nowMs)));
      }
    });
    await hooks.onTransactionsChanged(days);
    return const Ok(null);
  });

  Future<Result<void>> addTag(Iterable<String> ids, String tagId) => guard(() async {
    await db.transaction(() async {
      for (final id in ids) {
        await db.into(db.transactionTags).insert(
          TransactionTagsCompanion.insert(transactionId: id, tagId: tagId),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
    return const Ok(null);
  });

  /// Confirms a pending recurring item, optionally with an edited amount.
  Future<Result<void>> confirmPending(String id, {int? amount}) => guard(() async {
    final r = await _dao.byId(id);
    if (r == null) return const Err(AppFailure.notFound('tx_not_found'));
    if (amount != null && (amount <= 0 || amount >= kMaxMinorUnits)) {
      return const Err(AppFailure.validation('amount_zero'));
    }
    await (db.update(db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        isPending: const Value(false),
        amount: Value(amount ?? r.amount),
        updatedAt: Value(nowMs),
      ),
    );
    await hooks.onTransactionsChanged({r.date});
    return const Ok(null);
  });

  /// Skips (deletes) a pending recurring item.
  Future<Result<void>> skipPending(String id) => guard(() async {
    await _dao.deleteById(id);
    return const Ok(null);
  });

  /// Creates a "Balance adjustment" transaction for reconcile (§5.3).
  Future<Result<String?>> reconcile(String accountId, int currentBalance, int realBalance, LocalDay day) async {
    final diff = realBalance - currentBalance;
    if (diff == 0) return const Ok(null);
    final cat = await db.categoriesDao.bySystemKey(SystemCategory.adjustment);
    if (cat == null) return const Err(AppFailure.notFound('category_not_found'));
    final r = await save(
      TxDraft(
        type: diff > 0 ? 'income' : 'expense',
        amount: diff.abs(),
        accountId: accountId,
        categoryId: cat.id,
        day: day,
        excludeFromReports: true,
      ),
    );
    return r.map((id) => id);
  }

  /// Currency of an account (helper for forms).
  Future<Currency> currencyOf(String accountId) async {
    final a = await db.accountsDao.byId(accountId);
    return Currencies.of(a?.currencyCode ?? 'USD');
  }
}
