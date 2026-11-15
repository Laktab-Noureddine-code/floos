import 'package:floos/core/time/clock.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/db/db_connection.dart';
import 'package:floos/data/db/seed.dart';
import 'package:floos/data/repositories/accounts_repository.dart';
import 'package:floos/data/repositories/budgets_repository.dart';
import 'package:floos/data/repositories/categories_repository.dart';
import 'package:floos/data/repositories/debts_repository.dart';
import 'package:floos/data/repositories/goals_repository.dart';
import 'package:floos/data/repositories/recurring_repository.dart';
import 'package:floos/data/repositories/settings_repository.dart';
import 'package:floos/data/repositories/tags_rates_repositories.dart';
import 'package:floos/data/repositories/transactions_repository.dart';

/// In-memory database with repositories wired for tests.
class TestEnv {
  TestEnv({DateTime? now}) : clock = FixedClock(now ?? DateTime(2026, 1, 15, 12)) {
    db = openMemoryDatabase();
    settings = SettingsRepository(db, clock: clock);
    accounts = AccountsRepository(db, clock: clock);
    categories = CategoriesRepository(db, clock: clock);
    tags = TagsRepository(db, clock: clock);
    rates = RatesRepository(db, clock: clock);
    transactions = TransactionsRepository(db, clock: clock);
    budgets = BudgetsRepository(db, clock: clock);
    goals = GoalsRepository(db, clock: clock, transactions: transactions);
    recurring = RecurringRepository(db, clock: clock, transactions: transactions);
    debts = DebtsRepository(db, clock: clock, transactions: transactions);
  }

  final FixedClock clock;
  late final AppDatabase db;
  late final SettingsRepository settings;
  late final AccountsRepository accounts;
  late final CategoriesRepository categories;
  late final TagsRepository tags;
  late final RatesRepository rates;
  late final TransactionsRepository transactions;
  late final BudgetsRepository budgets;
  late final GoalsRepository goals;
  late final RecurringRepository recurring;
  late final DebtsRepository debts;

  LocalDay get today => clock.today();

  Future<void> seed({String locale = 'en', String base = 'MAD'}) async {
    await seedCategories(db, locale, clock.now().millisecondsSinceEpoch);
    await settings.set(SettingKeys.baseCurrency, base);
  }

  Future<String> account({String name = 'Cash', String currency = 'MAD', int initial = 0}) async =>
      (await accounts.save(
        AccountDraft(name: name, type: 'cash', currencyCode: currency, initialBalance: initial, color: 'purple', icon: 'wallet'),
      )).requireValue;

  Future<String> categoryId(String name) async =>
      (await categories.getAll()).firstWhere((c) => c.name == name).id;

  Future<String> expense(String accountId, int amount, {String category = 'Food & Groceries', LocalDay? day, String? payee, String? note}) async =>
      (await transactions.save(
        TxDraft(
          type: 'expense',
          amount: amount,
          accountId: accountId,
          categoryId: await categoryId(category),
          day: day ?? today,
          payee: payee,
          note: note,
        ),
      )).requireValue;

  Future<String> income(String accountId, int amount, {String category = 'Salary', LocalDay? day}) async =>
      (await transactions.save(
        TxDraft(type: 'income', amount: amount, accountId: accountId, categoryId: await categoryId(category), day: day ?? today),
      )).requireValue;

  Future<void> dispose() => db.close();
}
