import 'package:drift/drift.dart';

import 'package:floos/data/db/daos/accounts_dao.dart';
import 'package:floos/data/db/daos/categories_dao.dart';
import 'package:floos/data/db/daos/misc_daos.dart';
import 'package:floos/data/db/daos/plan_daos.dart';
import 'package:floos/data/db/daos/transactions_dao.dart';
import 'package:floos/data/db/tables/tables.dart';

part 'app_database.g.dart';

/// Current schema version. Bump together with a migration step + test.
const int kSchemaVersion = 1;

@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    Transactions,
    Tags,
    TransactionTags,
    Attachments,
    Budgets,
    BudgetAlertLog,
    Goals,
    GoalContributions,
    RecurringRules,
    Debts,
    DebtPayments,
    ExchangeRates,
    AppSettings,
    NotificationsLog,
    ErrorLog,
  ],
  daos: [
    AccountsDao,
    CategoriesDao,
    TransactionsDao,
    TagsDao,
    AttachmentsDao,
    BudgetsDao,
    GoalsDao,
    RecurringDao,
    DebtsDao,
    RatesDao,
    SettingsDao,
    NotificationsDao,
    ErrorLogDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => kSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await createExtras(this);
    },
    onUpgrade: (m, from, to) async {
      // Stepwise migrations: add `if (from < N) { ... }` blocks per version.
      // Version 1 is the baseline; there are no steps yet.
      await customStatement('PRAGMA foreign_keys = OFF');
      for (var v = from + 1; v <= to; v++) {
        await migrationSteps[v]?.call(m, this);
      }
      await customStatement('PRAGMA foreign_keys = ON');
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Wipes every user table (used by "Delete all data").
  Future<void> wipeAll() => transaction(() async {
    await customStatement('PRAGMA foreign_keys = OFF');
    for (final t in allTables.toList().reversed) {
      await customStatement('DELETE FROM ${t.actualTableName}');
    }
    await customStatement("INSERT INTO transactions_fts(transactions_fts) VALUES('rebuild')");
    await customStatement('PRAGMA foreign_keys = ON');
  });
}

/// Migration step registry: version → step that upgrades from version-1.
final Map<int, Future<void> Function(Migrator m, AppDatabase db)>
migrationSteps = {};

/// FTS5 table, triggers and partial indexes not expressible in table DSL.
Future<void> createExtras(GeneratedDatabase db) async {
  const stmts = [
    '''CREATE VIRTUAL TABLE IF NOT EXISTS transactions_fts USING fts5(
         payee, note, content='transactions', content_rowid='rowid',
         tokenize='unicode61 remove_diacritics 2')''',
    '''CREATE TRIGGER IF NOT EXISTS transactions_ai AFTER INSERT ON transactions BEGIN
         INSERT INTO transactions_fts(rowid, payee, note) VALUES (new.rowid, new.payee, new.note);
       END''',
    '''CREATE TRIGGER IF NOT EXISTS transactions_ad AFTER DELETE ON transactions BEGIN
         INSERT INTO transactions_fts(transactions_fts, rowid, payee, note)
           VALUES ('delete', old.rowid, old.payee, old.note);
       END''',
    '''CREATE TRIGGER IF NOT EXISTS transactions_au AFTER UPDATE ON transactions BEGIN
         INSERT INTO transactions_fts(transactions_fts, rowid, payee, note)
           VALUES ('delete', old.rowid, old.payee, old.note);
         INSERT INTO transactions_fts(rowid, payee, note) VALUES (new.rowid, new.payee, new.note);
       END''',
    '''CREATE UNIQUE INDEX IF NOT EXISTS ux_tx_recurring_date
         ON transactions(recurring_rule_id, date) WHERE recurring_rule_id IS NOT NULL''',
    '''CREATE UNIQUE INDEX IF NOT EXISTS ux_budget_active
         ON budgets(coalesce(category_id, '__overall__'), period) WHERE archived = 0''',
    'CREATE INDEX IF NOT EXISTS idx_tx_updated ON transactions(updated_at)',
    'CREATE INDEX IF NOT EXISTS idx_tx_payee ON transactions(payee)',
    'CREATE INDEX IF NOT EXISTS idx_contrib_goal ON goal_contributions(goal_id, date)',
    'CREATE INDEX IF NOT EXISTS idx_notif_created ON notifications_log(created_at)',
  ];
  for (final s in stmts) {
    await db.customStatement(s);
  }
}
