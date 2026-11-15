import 'package:drift/drift.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/time/clock.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/utils/result.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/repositories/transactions_repository.dart';
import 'package:floos/domain/services/csv_service.dart';
import 'package:uuid/uuid.dart';

/// How an unknown account/category name is resolved.
sealed class NameResolution {
  const NameResolution();
}

class MapToExisting extends NameResolution {
  const MapToExisting(this.id);
  final String id;
}

class CreateNew extends NameResolution {
  const CreateNew();
}

/// Dry-run analysis of an import.
class ImportPlan {
  const ImportPlan({
    required this.rows,
    required this.errors,
    required this.unknownAccounts,
    required this.unknownCategories,
    required this.duplicates,
  });

  final List<CsvImportRow> rows;
  final List<CsvRowError> errors;

  /// Unknown account names → their (detected) currency.
  final Map<String, String?> unknownAccounts;

  /// Unknown category names → kind (`expense` / `income`).
  final Map<String, String> unknownCategories;

  /// Row numbers that duplicate existing transactions.
  final Set<int> duplicates;
}

/// Import result report (APP_PROMPT §7.3 step 5).
class ImportReport {
  const ImportReport({required this.imported, required this.skipped, required this.errors});
  final int imported;
  final int skipped;
  final List<CsvRowError> errors;
}

/// Executes CSV imports atomically against the database.
class CsvImporter {
  CsvImporter(this.db, this.transactions, {this.clock = const Clock()});

  final AppDatabase db;
  final TransactionsRepository transactions;
  final Clock clock;
  static const _uuid = Uuid();

  String _k(String s) => s.trim().toLowerCase();

  Future<ImportPlan> plan(List<CsvImportRow> rows, List<CsvRowError> errors, String baseCurrency) async {
    final accounts = {for (final a in await db.accountsDao.getAll()) _k(a.name): a};
    final cats = await db.categoriesDao.getAll();
    final catKeys = {for (final c in cats) '${c.kind}:${_k(c.name)}'};
    final unknownAccounts = <String, String?>{};
    final unknownCategories = <String, String>{};
    for (final r in rows) {
      for (final name in [r.account, r.toAccount]) {
        if (name != null && !accounts.containsKey(_k(name))) {
          unknownAccounts.putIfAbsent(name, () => r.currency);
        }
      }
      if (r.type != 'transfer' && r.category != null && !catKeys.contains('${r.type}:${_k(r.category!)}')) {
        unknownCategories.putIfAbsent(r.category!, () => r.type);
      }
    }
    final duplicates = <int>{};
    final existing = await _existingKeys();
    for (final r in rows) {
      final a = r.account == null ? null : accounts[_k(r.account!)];
      if (a == null) continue;
      final minor = r.minor(Currencies.of(a.currencyCode)).valueOrNull;
      if (minor == null) continue;
      if (existing.contains(CsvService.duplicateKey(r.day, minor, r.payee, a.id))) duplicates.add(r.rowNumber);
    }
    return ImportPlan(
      rows: rows,
      errors: errors,
      unknownAccounts: unknownAccounts,
      unknownCategories: unknownCategories,
      duplicates: duplicates,
    );
  }

  Future<Set<String>> _existingKeys() async {
    final rows = await db.customSelect('SELECT date, amount, payee, account_id FROM transactions').get();
    return {
      for (final r in rows)
        '${LocalDay.fromStorage(r.read<int>('date')).toIso()}|${r.read<int>('amount')}|${(r.readNullable<String>('payee') ?? '').trim().toLowerCase()}|${r.read<String>('account_id')}',
    };
  }

  /// Imports [plan] in one transaction. Unknown names are resolved with
  /// [accountRes]/[categoryRes]; rows without an account use [fallbackAccountId].
  Future<Result<ImportReport>> run(
    ImportPlan plan, {
    required Map<String, NameResolution> accountRes,
    required Map<String, NameResolution> categoryRes,
    required String baseCurrency,
    String? fallbackAccountId,
    bool importDuplicates = false,
  }) async {
    final errors = [...plan.errors];
    var imported = 0;
    var skipped = 0;
    try {
      await db.transaction(() async {
        final now = clock.now().millisecondsSinceEpoch;
        final accounts = {for (final a in await db.accountsDao.getAll()) _k(a.name): a};
        for (final e in accountRes.entries) {
          final res = e.value;
          if (res is MapToExisting) {
            final a = await db.accountsDao.byId(res.id);
            if (a != null) accounts[_k(e.key)] = a;
          } else {
            final cur = plan.unknownAccounts[e.key];
            final code = cur != null && Currencies.isKnown(cur) ? cur : baseCurrency;
            final id = _uuid.v4();
            await db.accountsDao.upsert(AccountsCompanion.insert(
              id: id,
              createdAt: now,
              updatedAt: now,
              name: e.key.length > 40 ? e.key.substring(0, 40) : e.key,
              type: 'other',
              currencyCode: code,
              color: 'slate',
              icon: 'wallet',
              sortOrder: Value((await db.accountsDao.maxSortOrder()) + 1),
            ));
            accounts[_k(e.key)] = (await db.accountsDao.byId(id))!;
          }
        }
        final cats = await db.categoriesDao.getAll();
        final catByKey = {for (final c in cats) '${c.kind}:${_k(c.name)}': c.id};
        final otherExpense = cats.firstWhere((c) => c.systemKey == 'other_expense').id;
        final otherIncome = cats.firstWhere((c) => c.systemKey == 'other_income').id;
        for (final e in categoryRes.entries) {
          final kind = plan.unknownCategories[e.key] ?? 'expense';
          final res = e.value;
          if (res is MapToExisting) {
            catByKey['$kind:${_k(e.key)}'] = res.id;
          } else {
            final id = _uuid.v4();
            await db.categoriesDao.upsert(CategoriesCompanion.insert(
              id: id,
              createdAt: now,
              updatedAt: now,
              name: e.key.length > 30 ? e.key.substring(0, 30) : e.key,
              kind: kind,
              icon: 'tag',
              color: 'purple',
              sortOrder: Value(cats.length + catByKey.length),
            ));
            catByKey['$kind:${_k(e.key)}'] = id;
          }
        }
        final tagIds = {for (final t in await db.tagsDao.getAll()) _k(t.name): t.id};
        for (final r in plan.rows) {
          if (plan.duplicates.contains(r.rowNumber) && !importDuplicates) {
            skipped++;
            continue;
          }
          final account = r.account == null
              ? (fallbackAccountId == null ? null : await db.accountsDao.byId(fallbackAccountId))
              : accounts[_k(r.account!)];
          if (account == null) {
            errors.add(CsvRowError(r.rowNumber, 'account'));
            continue;
          }
          final cur = Currencies.of(account.currencyCode);
          final amount = r.minor(cur);
          if (amount.isErr || amount.requireValue <= 0) {
            errors.add(CsvRowError(r.rowNumber, 'amount'));
            continue;
          }
          final to = r.toAccount == null ? null : accounts[_k(r.toAccount!)];
          final toAmount = to == null ? null : r.toMinor(Currencies.of(to.currencyCode))?.valueOrNull;
          String? categoryId;
          if (r.type != 'transfer') {
            categoryId = r.category == null
                ? (r.type == 'income' ? otherIncome : otherExpense)
                : catByKey['${r.type}:${_k(r.category!)}'];
          }
          final draft = TxDraft(
            id: r.id != null && await db.transactionsDao.byId(r.id!) == null ? r.id : null,
            type: r.type,
            amount: amount.requireValue,
            accountId: account.id,
            toAccountId: to?.id,
            toAmount: to != null && to.currencyCode != account.currencyCode ? toAmount : null,
            categoryId: categoryId,
            day: r.day,
            timeMinutes: r.timeMinutes,
            payee: r.payee == null || r.payee!.length <= 60 ? r.payee : r.payee!.substring(0, 60),
            note: r.note == null || r.note!.length <= 500 ? r.note : r.note!.substring(0, 500),
          );
          final v = await transactions.validate(draft);
          if (v case Err(:final failure)) {
            errors.add(CsvRowError(r.rowNumber, failure.code));
            continue;
          }
          final id = draft.id ?? _uuid.v4();
          await db.transactionsDao.upsert(TransactionsCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            type: draft.type,
            amount: draft.amount,
            accountId: draft.accountId,
            toAccountId: Value(draft.type == 'transfer' ? draft.toAccountId : null),
            toAmount: Value(draft.toAmount),
            categoryId: Value(draft.categoryId),
            date: draft.day.toStorage(),
            timeOfDayMinutes: Value(draft.timeMinutes),
            payee: Value(draft.payee),
            note: Value(draft.note),
          ));
          final ids = <String>[];
          for (final t in r.tags) {
            var tid = tagIds[_k(t)];
            if (tid == null) {
              tid = _uuid.v4();
              await db.tagsDao.upsert(TagsCompanion.insert(
                id: tid,
                createdAt: now,
                updatedAt: now,
                name: t.length > 30 ? t.substring(0, 30) : t,
                color: 'purple',
              ));
              tagIds[_k(t)] = tid;
            }
            ids.add(tid);
          }
          await db.transactionsDao.setTags(id, ids);
          imported++;
        }
      });
    } on Object {
      return const Err(AppFailure.storage('storage_error'));
    }
    return Ok(ImportReport(imported: imported, skipped: skipped, errors: errors..sort((a, b) => a.rowNumber.compareTo(b.rowNumber))));
  }
}
