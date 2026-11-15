import 'package:drift/drift.dart';

import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/db/tables/tables.dart';

part 'plan_daos.g.dart';

@DriftAccessor(tables: [Budgets, BudgetAlertLog])
class BudgetsDao extends DatabaseAccessor<AppDatabase> with _$BudgetsDaoMixin {
  BudgetsDao(super.attachedDatabase);

  Stream<List<BudgetRow>> watchAll() =>
      (select(budgets)..orderBy([(b) => OrderingTerm(expression: b.createdAt)])).watch();

  Future<List<BudgetRow>> getAll() => select(budgets).get();

  Future<List<BudgetRow>> active() =>
      (select(budgets)..where((b) => b.archived.equals(false))).get();

  Future<BudgetRow?> byId(String id) =>
      (select(budgets)..where((b) => b.id.equals(id))).getSingleOrNull();

  Future<void> upsert(BudgetsCompanion c) => into(budgets).insertOnConflictUpdate(c);

  Future<int> deleteById(String id) => (delete(budgets)..where((b) => b.id.equals(id))).go();

  Future<bool> activeExists(String? categoryId, String period, {String? exceptId}) async {
    final rows = await customSelect(
      '''SELECT id FROM budgets WHERE archived = 0 AND period = ?
           AND coalesce(category_id, '__overall__') = coalesce(?, '__overall__') AND id != ?''',
      variables: [Variable(period), Variable(categoryId), Variable(exceptId ?? '')],
      readsFrom: {budgets},
    ).get();
    return rows.isNotEmpty;
  }

  /// Inserts an alert log row; returns false if it already existed.
  Future<bool> logAlert(String budgetId, int periodStart, int threshold, int now) async {
    await into(budgetAlertLog).insert(
      BudgetAlertLogCompanion.insert(
        budgetId: budgetId,
        periodStart: periodStart,
        threshold: threshold,
        createdAt: now,
      ),
      mode: InsertMode.insertOrIgnore,
    );
    return (await _changes()) > 0;
  }

  Future<int> _changes() async {
    final r = await customSelect('SELECT changes() AS c').getSingle();
    return r.read<int>('c');
  }
}

@DriftAccessor(tables: [Goals, GoalContributions])
class GoalsDao extends DatabaseAccessor<AppDatabase> with _$GoalsDaoMixin {
  GoalsDao(super.attachedDatabase);

  Stream<List<GoalRow>> watchAll() => (select(goals)
        ..orderBy([
          (g) => OrderingTerm(expression: g.priority, mode: OrderingMode.desc),
          (g) => OrderingTerm(expression: g.createdAt),
        ]))
      .watch();

  Future<List<GoalRow>> getAll() => select(goals).get();

  Future<GoalRow?> byId(String id) =>
      (select(goals)..where((g) => g.id.equals(id))).getSingleOrNull();

  Future<void> upsert(GoalsCompanion c) => into(goals).insertOnConflictUpdate(c);

  Future<int> deleteById(String id) => (delete(goals)..where((g) => g.id.equals(id))).go();

  Stream<List<ContributionRow>> watchContributions(String goalId) => (select(goalContributions)
        ..where((c) => c.goalId.equals(goalId))
        ..orderBy([(c) => OrderingTerm(expression: c.date, mode: OrderingMode.desc)]))
      .watch();

  Stream<List<ContributionRow>> watchAllContributions() => select(goalContributions).watch();

  Future<List<ContributionRow>> contributions(String goalId) =>
      (select(goalContributions)..where((c) => c.goalId.equals(goalId))).get();

  Future<List<ContributionRow>> allContributions() => select(goalContributions).get();

  Future<void> addContribution(GoalContributionsCompanion c) =>
      into(goalContributions).insertOnConflictUpdate(c);

  Future<int> deleteContribution(String id) =>
      (delete(goalContributions)..where((c) => c.id.equals(id))).go();

  Future<void> unlinkAccount(String accountId, int now) => customUpdate(
    '''UPDATE goals SET tracking_mode = 'manual', linked_account_id = NULL, updated_at = ?2
        WHERE linked_account_id = ?1''',
    variables: [Variable(accountId), Variable(now)],
    updates: {goals},
  );
}

@DriftAccessor(tables: [RecurringRules])
class RecurringDao extends DatabaseAccessor<AppDatabase> with _$RecurringDaoMixin {
  RecurringDao(super.attachedDatabase);

  Stream<List<RecurringRuleRow>> watchAll() => (select(recurringRules)
        ..orderBy([(r) => OrderingTerm(expression: r.nextDueDate)]))
      .watch();

  Future<List<RecurringRuleRow>> getAll() => select(recurringRules).get();

  Future<List<RecurringRuleRow>> active() =>
      (select(recurringRules)..where((r) => r.active.equals(true))).get();

  Future<RecurringRuleRow?> byId(String id) =>
      (select(recurringRules)..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<void> upsert(RecurringRulesCompanion c) => into(recurringRules).insertOnConflictUpdate(c);

  Future<int> deleteById(String id) =>
      (delete(recurringRules)..where((r) => r.id.equals(id))).go();
}

@DriftAccessor(tables: [Debts, DebtPayments])
class DebtsDao extends DatabaseAccessor<AppDatabase> with _$DebtsDaoMixin {
  DebtsDao(super.attachedDatabase);

  Stream<List<DebtRow>> watchAll() => (select(debts)
        ..orderBy([(d) => OrderingTerm(expression: d.createdAt, mode: OrderingMode.desc)]))
      .watch();

  Future<List<DebtRow>> getAll() => select(debts).get();

  Future<DebtRow?> byId(String id) =>
      (select(debts)..where((d) => d.id.equals(id))).getSingleOrNull();

  Future<void> upsert(DebtsCompanion c) => into(debts).insertOnConflictUpdate(c);

  Future<int> deleteById(String id) => (delete(debts)..where((d) => d.id.equals(id))).go();

  Stream<List<DebtPaymentRow>> watchPayments() => select(debtPayments).watch();

  Future<List<DebtPaymentRow>> payments(String debtId) =>
      (select(debtPayments)..where((p) => p.debtId.equals(debtId))).get();

  Future<void> addPayment(DebtPaymentsCompanion c) => into(debtPayments).insert(c);

  Future<int> deletePayment(String id) =>
      (delete(debtPayments)..where((p) => p.id.equals(id))).go();
}
