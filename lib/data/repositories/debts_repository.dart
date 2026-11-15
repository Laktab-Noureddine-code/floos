import 'package:drift/drift.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/money/money.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/utils/result.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/db/seed.dart';
import 'package:floos/data/repositories/repo_base.dart';
import 'package:floos/data/repositories/transactions_repository.dart';
import 'package:floos/domain/services/debt_service.dart';
import 'package:floos/domain/services/fx_service.dart';

/// Draft for creating/updating a debt.
class DebtDraft {
  const DebtDraft({
    required this.direction,
    required this.personName,
    required this.amount,
    required this.currencyCode,
    required this.start,
    this.id,
    this.due,
    this.note,
  });

  final String? id;

  /// `i_owe` | `owed_to_me`.
  final String direction;
  final String personName;
  final int amount;
  final String currencyCode;
  final LocalDay start;
  final LocalDay? due;
  final String? note;
}

/// A payment shown in the debt detail (transaction-backed or record-only).
class DebtPaymentView {
  const DebtPaymentView({
    required this.id,
    required this.amount,
    required this.day,
    required this.recordOnly,
    this.note,
  });

  final String id;

  /// Amount in the debt currency.
  final int amount;
  final LocalDay day;
  final bool recordOnly;
  final String? note;
}

/// A debt with its payments and computed status.
class DebtView {
  const DebtView(this.row, this.payments, this.status);
  final DebtRow row;
  final List<DebtPaymentView> payments;
  final DebtStatus status;

  String get id => row.id;
  Currency get currency => Currencies.of(row.currencyCode);
}

class DebtsRepository extends RepoBase {
  DebtsRepository(super.db, {required this.transactions, super.clock, super.hooks});

  final TransactionsRepository transactions;

  Stream<List<DebtRow>> watchAll() => db.debtsDao.watchAll();

  Future<DebtRow?> byId(String id) => db.debtsDao.byId(id);

  Future<List<DebtRow>> getAll() => db.debtsDao.getAll();

  Future<Result<String>> save(DebtDraft d) => guard(() async {
    final name = d.personName.trim();
    if (name.isEmpty || name.length > 40) return const Err(AppFailure.validation('person_name_length'));
    if (d.direction != 'i_owe' && d.direction != 'owed_to_me') {
      return const Err(AppFailure.validation('direction_invalid'));
    }
    if (d.amount <= 0) return const Err(AppFailure.validation('amount_zero'));
    if (d.amount >= kMaxMinorUnits) return const Err(AppFailure.validation('amount_too_large'));
    if (d.due != null && d.due! < d.start) return const Err(AppFailure.validation('due_before_start'));
    final existing = d.id == null ? null : await db.debtsDao.byId(d.id!);
    final now = nowMs;
    final id = d.id ?? newId();
    await db.debtsDao.upsert(
      DebtsCompanion(
        id: Value(id),
        createdAt: Value(existing?.createdAt ?? now),
        updatedAt: Value(now),
        direction: Value(d.direction),
        personName: Value(name),
        originalAmount: Value(d.amount),
        currencyCode: Value(d.currencyCode),
        startDate: Value(d.start.toStorage()),
        dueDate: Value(d.due?.toStorage()),
        note: Value(d.note?.trim().isEmpty ?? true ? null : d.note!.trim()),
        status: Value(existing?.status ?? 'open'),
        settledAt: Value(existing?.settledAt),
      ),
    );
    await hooks.onDataChanged();
    return Ok(id);
  });

  /// Records a payment. With [accountId], creates a linked expense (i owe) or
  /// income (owed to me); otherwise records it without affecting balances.
  Future<Result<void>> addPayment(
    String debtId,
    int amount,
    LocalDay day, {
    String? accountId,
    String? categoryId,
    String? note,
    FxService? fx,
  }) => guard(() async {
    if (amount <= 0) return const Err(AppFailure.validation('amount_zero'));
    if (amount >= kMaxMinorUnits) return const Err(AppFailure.validation('amount_too_large'));
    final debt = await db.debtsDao.byId(debtId);
    if (debt == null) return const Err(AppFailure.notFound('debt_not_found'));
    if (accountId == null) {
      final now = nowMs;
      await db.debtsDao.addPayment(
        DebtPaymentsCompanion.insert(
          id: newId(),
          createdAt: now,
          updatedAt: now,
          debtId: debtId,
          amount: amount,
          date: day.toStorage(),
          note: Value(note),
        ),
      );
    } else {
      final account = await db.accountsDao.byId(accountId);
      if (account == null) return const Err(AppFailure.notFound('account_not_found'));
      var txAmount = amount;
      if (account.currencyCode != debt.currencyCode) {
        final converted = fx?.convertMinor(amount, debt.currencyCode, account.currencyCode, day);
        if (converted == null || converted.isErr) {
          return Err(AppFailure.validation('rate_missing', args: {'from': debt.currencyCode, 'to': account.currencyCode}));
        }
        txAmount = converted.requireValue;
      }
      final iOwe = debt.direction == 'i_owe';
      final cat = categoryId ??
          (await db.categoriesDao.bySystemKey(iOwe ? SystemCategory.otherExpense : SystemCategory.otherIncome))?.id;
      final r = await transactions.save(
        TxDraft(
          type: iOwe ? 'expense' : 'income',
          amount: txAmount,
          accountId: accountId,
          categoryId: cat,
          day: day,
          payee: debt.personName,
          note: note,
          debtId: debtId,
        ),
      );
      if (r case Err(:final failure)) return Err(failure);
    }
    await hooks.onDataChanged();
    return const Ok(null);
  });

  Future<Result<void>> deleteRecordOnlyPayment(String id) => guard(() async {
    await db.debtsDao.deletePayment(id);
    await hooks.onDataChanged();
    return const Ok(null);
  });

  Future<Result<void>> setSettled(String id, {required bool settled}) => guard(() async {
    await (db.update(db.debts)..where((d) => d.id.equals(id))).write(
      DebtsCompanion(
        status: Value(settled ? 'settled' : 'open'),
        settledAt: Value(settled ? nowMs : null),
        updatedAt: Value(nowMs),
      ),
    );
    await hooks.onDataChanged();
    return const Ok(null);
  });

  Future<Result<void>> delete(String id) => guard(() async {
    await db.debtsDao.deleteById(id);
    await hooks.onDataChanged();
    return const Ok(null);
  });

  /// Loads all debts with payments and status.
  Future<List<DebtView>> views(FxService fx) async {
    final today = clock.today();
    final debts = await db.debtsDao.getAll();
    final recordOnly = await db.select(db.debtPayments).get();
    final linked = await db.customSelect(
      '''SELECT t.id, t.debt_id, t.amount, t.date, t.note, a.currency_code AS cur
           FROM transactions t JOIN accounts a ON a.id = t.account_id
          WHERE t.debt_id IS NOT NULL AND t.is_pending = 0''',
      readsFrom: {db.transactions, db.accounts},
    ).get();
    final out = <DebtView>[];
    for (final d in debts) {
      final payments = <DebtPaymentView>[
        for (final p in recordOnly.where((p) => p.debtId == d.id))
          DebtPaymentView(
            id: p.id,
            amount: p.amount,
            day: LocalDay.fromStorage(p.date),
            recordOnly: true,
            note: p.note,
          ),
        for (final r in linked.where((r) => r.read<String>('debt_id') == d.id))
          DebtPaymentView(
            id: r.read<String>('id'),
            amount: fx
                    .convertMinor(
                      r.read<int>('amount'),
                      r.read<String>('cur'),
                      d.currencyCode,
                      LocalDay.fromStorage(r.read<int>('date')),
                    )
                    .valueOrNull ??
                r.read<int>('amount'),
            day: LocalDay.fromStorage(r.read<int>('date')),
            recordOnly: false,
            note: r.readNullable<String>('note'),
          ),
      ]..sort((a, b) => b.day.compareTo(a.day));
      final status = DebtService.evaluate(
        original: d.originalAmount,
        payments: payments.map((p) => p.amount),
        today: today,
        due: d.dueDate == null ? null : LocalDay.fromStorage(d.dueDate!),
      );
      out.add(DebtView(d, payments, status));
    }
    return out;
  }

  /// Auto-settles open debts whose remaining reached 0 (APP_PROMPT §5.8).
  Future<void> autoSettle(FxService fx) async {
    for (final v in await views(fx)) {
      if (v.row.status == 'open' && v.status.shouldSettle) {
        await (db.update(db.debts)..where((d) => d.id.equals(v.id))).write(
          DebtsCompanion(status: const Value('settled'), settledAt: Value(nowMs)),
        );
      }
    }
  }
}
