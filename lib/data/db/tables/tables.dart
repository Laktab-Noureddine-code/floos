import 'package:drift/drift.dart';

/// Common columns: UUID primary key and UTC-ms timestamps.
mixin BaseColumns on Table {
  TextColumn get id => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AccountRow')
class Accounts extends Table with BaseColumns {
  TextColumn get name => text().withLength(min: 1, max: 40)();
  TextColumn get type => text()();
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();
  IntColumn get initialBalance => integer().withDefault(const Constant(0))();
  TextColumn get color => text()();
  TextColumn get icon => text()();
  BoolColumn get includeInTotal => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

@DataClassName('CategoryRow')
class Categories extends Table with BaseColumns {
  TextColumn get name => text().withLength(min: 1, max: 30)();
  TextColumn get kind => text()();
  TextColumn get parentId => text().nullable().references(Categories, #id)();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  TextColumn get systemKey => text().nullable().unique()();
}

@DataClassName('TxRow')
@TableIndex(name: 'idx_tx_date', columns: {#date})
@TableIndex(name: 'idx_tx_account_date', columns: {#accountId, #date})
@TableIndex(name: 'idx_tx_to_account_date', columns: {#toAccountId, #date})
@TableIndex(name: 'idx_tx_category_date', columns: {#categoryId, #date})
@TableIndex(name: 'idx_tx_type_date', columns: {#type, #date})
class Transactions extends Table with BaseColumns {
  TextColumn get type => text()();
  IntColumn get amount => integer()();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get toAccountId => text().nullable().references(Accounts, #id)();
  IntColumn get toAmount => integer().nullable()();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  IntColumn get date => integer()();
  IntColumn get timeOfDayMinutes => integer().nullable()();
  TextColumn get payee => text().nullable().withLength(max: 60)();
  TextColumn get note => text().nullable().withLength(max: 500)();
  TextColumn get recurringRuleId => text()
      .nullable()
      .references(RecurringRules, #id, onDelete: KeyAction.setNull)();
  TextColumn get debtId =>
      text().nullable().references(Debts, #id, onDelete: KeyAction.setNull)();
  TextColumn get goalId =>
      text().nullable().references(Goals, #id, onDelete: KeyAction.setNull)();
  BoolColumn get isPending => boolean().withDefault(const Constant(false))();
  BoolColumn get excludeFromReports =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
}

@DataClassName('TagRow')
class Tags extends Table with BaseColumns {
  TextColumn get name => text().withLength(min: 1, max: 30).unique()();
  TextColumn get color => text()();
}

@DataClassName('TransactionTagRow')
class TransactionTags extends Table {
  TextColumn get transactionId =>
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {transactionId, tagId};
}

@DataClassName('AttachmentRow')
class Attachments extends Table with BaseColumns {
  TextColumn get transactionId =>
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();
  TextColumn get fileName => text()();
  TextColumn get mime => text()();
  IntColumn get sizeBytes => integer()();
  TextColumn get sha256 => text()();
}

@DataClassName('BudgetRow')
class Budgets extends Table with BaseColumns {
  TextColumn get name => text()();
  TextColumn get categoryId => text()
      .nullable()
      .references(Categories, #id, onDelete: KeyAction.setNull)();
  BoolColumn get includeSubcategories =>
      boolean().withDefault(const Constant(true))();
  IntColumn get amount => integer()();
  TextColumn get period => text()();
  IntColumn get customStart => integer().nullable()();
  IntColumn get customEnd => integer().nullable()();
  BoolColumn get rollover => boolean().withDefault(const Constant(false))();
  TextColumn get alertThresholds =>
      text().withDefault(const Constant('[80,100]'))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

@DataClassName('BudgetAlertRow')
class BudgetAlertLog extends Table {
  TextColumn get budgetId =>
      text().references(Budgets, #id, onDelete: KeyAction.cascade)();
  IntColumn get periodStart => integer()();
  IntColumn get threshold => integer()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {budgetId, periodStart, threshold};
}

@DataClassName('GoalRow')
class Goals extends Table with BaseColumns {
  TextColumn get name => text().withLength(min: 1, max: 40)();
  IntColumn get targetAmount => integer()();
  IntColumn get startDate => integer()();
  IntColumn get deadline => integer().nullable()();
  TextColumn get trackingMode => text().withDefault(const Constant('manual'))();
  TextColumn get linkedAccountId => text()
      .nullable()
      .references(Accounts, #id, onDelete: KeyAction.setNull)();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  IntColumn get completedAt => integer().nullable()();
  BoolColumn get celebrated => boolean().withDefault(const Constant(false))();
  TextColumn get milestonesNotified =>
      text().withDefault(const Constant('[]'))();
}

@DataClassName('ContributionRow')
class GoalContributions extends Table with BaseColumns {
  TextColumn get goalId =>
      text().references(Goals, #id, onDelete: KeyAction.cascade)();
  IntColumn get amount => integer()();
  IntColumn get date => integer()();
  TextColumn get note => text().nullable()();
  TextColumn get transactionId => text()
      .nullable()
      .references(Transactions, #id, onDelete: KeyAction.setNull)();
}

@DataClassName('RecurringRuleRow')
class RecurringRules extends Table with BaseColumns {
  TextColumn get name => text().nullable()();
  TextColumn get templateType => text()();
  IntColumn get templateAmount => integer()();
  TextColumn get templateAccountId => text().references(Accounts, #id)();
  TextColumn get templateToAccountId =>
      text().nullable().references(Accounts, #id)();
  IntColumn get templateToAmount => integer().nullable()();
  TextColumn get templateCategoryId =>
      text().nullable().references(Categories, #id)();
  TextColumn get templatePayee => text().nullable()();
  TextColumn get templateNote => text().nullable()();
  TextColumn get templateTagIds => text().withDefault(const Constant('[]'))();
  TextColumn get frequency => text()();
  IntColumn get interval => integer().withDefault(const Constant(1))();
  IntColumn get byWeekday => integer().nullable()();
  IntColumn get byMonthDay => integer().nullable()();
  IntColumn get startDate => integer()();
  IntColumn get endDate => integer().nullable()();
  IntColumn get maxOccurrences => integer().nullable()();
  IntColumn get occurrencesCount => integer().withDefault(const Constant(0))();
  IntColumn get nextDueDate => integer()();
  TextColumn get mode => text().withDefault(const Constant('auto'))();
  IntColumn get remindDaysBefore => integer().nullable()();
  IntColumn get remindTimeMinutes =>
      integer().withDefault(const Constant(540))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

@DataClassName('DebtRow')
class Debts extends Table with BaseColumns {
  TextColumn get direction => text()();
  TextColumn get personName => text().withLength(min: 1, max: 40)();
  IntColumn get originalAmount => integer()();
  TextColumn get currencyCode => text()();
  IntColumn get startDate => integer()();
  IntColumn get dueDate => integer().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('open'))();
  IntColumn get settledAt => integer().nullable()();
}

@DataClassName('DebtPaymentRow')
class DebtPayments extends Table with BaseColumns {
  TextColumn get debtId =>
      text().references(Debts, #id, onDelete: KeyAction.cascade)();
  IntColumn get amount => integer()();
  IntColumn get date => integer()();
  TextColumn get note => text().nullable()();
}

@DataClassName('RateRow')
class ExchangeRates extends Table with BaseColumns {
  TextColumn get fromCode => text()();
  TextColumn get toCode => text()();
  IntColumn get rateE6 => integer()();
  IntColumn get date => integer()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {fromCode, toCode, date},
  ];
}

@DataClassName('SettingRow')
class AppSettings extends Table {
  @override
  String get tableName => 'settings';

  TextColumn get key => text()();
  TextColumn get value => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DataClassName('NotificationRow')
class NotificationsLog extends Table with BaseColumns {
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get route => text().nullable()();
  BoolColumn get read => boolean().withDefault(const Constant(false))();
}

@DataClassName('ErrorRow')
class ErrorLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get createdAt => integer()();
  TextColumn get kind => text()();
  TextColumn get message => text()();
  TextColumn get stack => text().nullable()();
}
