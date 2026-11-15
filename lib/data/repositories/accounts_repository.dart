import 'package:drift/drift.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/money/money.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/utils/result.dart';
import 'package:floos/core/utils/streams.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/repositories/repo_base.dart';
import 'package:floos/domain/services/balance_service.dart';

/// Account types (APP_PROMPT §4.1).
const accountTypes = ['cash', 'bank', 'card', 'savings', 'ewallet', 'other'];

/// An account with its derived balance (account currency).
class AccountWithBalance {
  const AccountWithBalance(this.account, this.balance);
  final AccountRow account;
  final int balance;

  Currency get currency => Currencies.of(account.currencyCode);

  AccountBalanceInput toInput() => AccountBalanceInput(
    id: account.id,
    currency: account.currencyCode,
    initial: account.initialBalance,
    flow: balance - account.initialBalance,
    includeInTotal: account.includeInTotal,
    archived: account.archived,
  );
}

/// Draft for creating/updating an account.
class AccountDraft {
  const AccountDraft({
    required this.name,
    required this.type,
    required this.currencyCode,
    required this.initialBalance,
    required this.color,
    required this.icon,
    this.includeInTotal = true,
    this.id,
  });

  final String? id;
  final String name;
  final String type;
  final String currencyCode;
  final int initialBalance;
  final String color;
  final String icon;
  final bool includeInTotal;
}

/// How to handle transactions when deleting an account.
sealed class AccountDeletion {
  const AccountDeletion();
}

class MoveTransactionsTo extends AccountDeletion {
  const MoveTransactionsTo(this.accountId);
  final String accountId;
}

class DeleteTransactions extends AccountDeletion {
  const DeleteTransactions();
}

class AccountsRepository extends RepoBase {
  AccountsRepository(super.db, {super.clock, super.hooks, this.onDeleteFiles});

  /// Called with attachment ids whose files must be removed.
  final Future<void> Function(List<String> attachmentIds)? onDeleteFiles;

  Stream<List<AccountRow>> watchAll() => db.accountsDao.watchAll();

  Future<List<AccountRow>> getAll() => db.accountsDao.getAll();

  Future<AccountRow?> byId(String id) => db.accountsDao.byId(id);

  /// Accounts with balances as of the end of [asOf] (future items excluded).
  Stream<List<AccountWithBalance>> watchWithBalances(LocalDay asOf) => combineLatest2(
    db.accountsDao.watchAll(),
    db.accountsDao.watchFlows(asOf.addDays(1).toStorage()),
    (accounts, flows) => [
      for (final a in accounts) AccountWithBalance(a, a.initialBalance + (flows[a.id] ?? 0)),
    ],
  );

  Future<List<AccountWithBalance>> withBalances(LocalDay asOf) async {
    final accounts = await db.accountsDao.getAll();
    final flows = await db.accountsDao.flows(asOf.addDays(1).toStorage());
    return [for (final a in accounts) AccountWithBalance(a, a.initialBalance + (flows[a.id] ?? 0))];
  }

  Future<int> balanceOf(String accountId, LocalDay asOf) async {
    final a = await db.accountsDao.byId(accountId);
    if (a == null) return 0;
    final flows = await db.accountsDao.flows(asOf.addDays(1).toStorage());
    return a.initialBalance + (flows[accountId] ?? 0);
  }

  Future<Result<String>> save(AccountDraft d) => guard(() async {
    final name = d.name.trim();
    if (name.isEmpty || name.length > 40) {
      return const Err(AppFailure.validation('account_name_length'));
    }
    if (!accountTypes.contains(d.type)) {
      return const Err(AppFailure.validation('account_type_invalid'));
    }
    if (!Currencies.isKnown(d.currencyCode)) {
      return const Err(AppFailure.validation('currency_invalid'));
    }
    if (d.initialBalance.abs() >= kMaxMinorUnits) {
      return const Err(AppFailure.validation('amount_too_large'));
    }
    if (await db.accountsDao.nameTaken(name, exceptId: d.id)) {
      return const Err(AppFailure.conflict('account_name_taken'));
    }
    final now = nowMs;
    final existing = d.id == null ? null : await db.accountsDao.byId(d.id!);
    final id = d.id ?? newId();
    await db.accountsDao.upsert(
      AccountsCompanion(
        id: Value(id),
        createdAt: Value(existing?.createdAt ?? now),
        updatedAt: Value(now),
        name: Value(name),
        type: Value(d.type),
        currencyCode: Value(d.currencyCode),
        initialBalance: Value(d.initialBalance),
        color: Value(d.color),
        icon: Value(d.icon),
        includeInTotal: Value(d.includeInTotal),
        sortOrder: Value(existing?.sortOrder ?? (await db.accountsDao.maxSortOrder()) + 1),
        archived: Value(existing?.archived ?? false),
      ),
    );
    await hooks.onDataChanged();
    return Ok(id);
  });

  Future<Result<void>> reorder(List<String> ids) => guard(() async {
    await db.transaction(() async {
      for (var i = 0; i < ids.length; i++) {
        await (db.update(db.accounts)..where((a) => a.id.equals(ids[i])))
            .write(AccountsCompanion(sortOrder: Value(i), updatedAt: Value(nowMs)));
      }
    });
    return const Ok(null);
  });

  Future<Result<void>> setArchived(String id, {required bool archived}) => guard(() async {
    final a = await db.accountsDao.byId(id);
    if (a == null) return const Err(AppFailure.notFound('account_not_found'));
    if (!archived && await db.accountsDao.nameTaken(a.name, exceptId: id)) {
      return const Err(AppFailure.conflict('account_name_taken'));
    }
    await (db.update(db.accounts)..where((x) => x.id.equals(id)))
        .write(AccountsCompanion(archived: Value(archived), updatedAt: Value(nowMs)));
    await hooks.onDataChanged();
    return const Ok(null);
  });

  Future<int> transactionCount(String id) => db.accountsDao.transactionCount(id);

  /// Deletes an account. With transactions, a [deletion] strategy is required
  /// (APP_PROMPT §6.6). Linked goals switch to manual mode (§13.5).
  Future<Result<void>> delete(String id, {AccountDeletion? deletion}) => guard(() async {
    final count = await db.accountsDao.transactionCount(id);
    final rules = await (db.select(db.recurringRules)
          ..where((r) => r.templateAccountId.equals(id) | r.templateToAccountId.equals(id)))
        .get();
    if ((count > 0 || rules.isNotEmpty) && deletion == null) {
      return const Err(AppFailure.conflict('account_has_transactions'));
    }
    final now = nowMs;
    var deletedTx = <String>[];
    await db.transaction(() async {
      switch (deletion) {
        case MoveTransactionsTo(:final accountId):
          if (accountId == id) throw StateError('same account');
          await db.transactionsDao.moveAccount(id, accountId, now);
          await db.customUpdate(
            'UPDATE recurring_rules SET template_account_id = ?2 WHERE template_account_id = ?1',
            variables: [Variable(id), Variable(accountId)],
            updates: {db.recurringRules},
          );
          await db.customUpdate(
            'UPDATE recurring_rules SET template_to_account_id = ?2 WHERE template_to_account_id = ?1',
            variables: [Variable(id), Variable(accountId)],
            updates: {db.recurringRules},
          );
          await db.customStatement(
            "DELETE FROM recurring_rules WHERE template_type = 'transfer' AND template_account_id = template_to_account_id",
          );
        case DeleteTransactions():
          final txIds = await db.transactionsDao.idsForAccount(id);
          deletedTx = [
            for (final a in await db.attachmentsDao.forTransactions(txIds)) a.id,
          ];
          await db.customUpdate(
            'DELETE FROM transactions WHERE account_id = ?1 OR to_account_id = ?1',
            variables: [Variable(id)],
            updates: {db.transactions},
          );
          await db.customUpdate(
            'DELETE FROM recurring_rules WHERE template_account_id = ?1 OR template_to_account_id = ?1',
            variables: [Variable(id)],
            updates: {db.recurringRules},
          );
        case null:
          break;
      }
      await db.goalsDao.unlinkAccount(id, now);
      await db.accountsDao.deleteById(id);
    });
    if (deletedTx.isNotEmpty) await onDeleteFiles?.call(deletedTx);
    await hooks.onTransactionsChanged({});
    return const Ok(null);
  });
}
