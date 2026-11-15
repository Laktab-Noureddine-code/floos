import 'package:drift/drift.dart';

import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/db/tables/tables.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories, Transactions, Budgets, RecurringRules])
class CategoriesDao extends DatabaseAccessor<AppDatabase> with _$CategoriesDaoMixin {
  CategoriesDao(super.attachedDatabase);

  Stream<List<CategoryRow>> watchAll() => (select(categories)
        ..orderBy([(c) => OrderingTerm(expression: c.sortOrder), (c) => OrderingTerm(expression: c.createdAt)]))
      .watch();

  Future<List<CategoryRow>> getAll() => (select(categories)
        ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
      .get();

  Future<CategoryRow?> byId(String id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<CategoryRow?> bySystemKey(String key) =>
      (select(categories)..where((c) => c.systemKey.equals(key))).getSingleOrNull();

  Future<void> upsert(CategoriesCompanion c) => into(categories).insertOnConflictUpdate(c);

  Future<int> deleteById(String id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();

  Future<int> count() async {
    final r = await customSelect('SELECT count(*) AS c FROM categories', readsFrom: {categories}).getSingle();
    return r.read<int>('c');
  }

  Future<int> usageCount(String id) async {
    final r = await customSelect(
      '''SELECT (SELECT count(*) FROM transactions WHERE category_id = ?1)
              + (SELECT count(*) FROM recurring_rules WHERE template_category_id = ?1) AS c''',
      variables: [Variable(id)],
      readsFrom: {transactions, recurringRules},
    ).getSingle();
    return r.read<int>('c');
  }

  /// Re-assigns every reference from [fromId] to [toId].
  Future<void> reassign(String fromId, String toId, int now) async {
    await customUpdate(
      'UPDATE transactions SET category_id = ?2, updated_at = ?3 WHERE category_id = ?1',
      variables: [Variable(fromId), Variable(toId), Variable(now)],
      updates: {transactions},
    );
    await customUpdate(
      'UPDATE recurring_rules SET template_category_id = ?2 WHERE template_category_id = ?1',
      variables: [Variable(fromId), Variable(toId)],
      updates: {recurringRules},
    );
    await customUpdate(
      'UPDATE categories SET parent_id = ?2 WHERE parent_id = ?1 AND id != ?2',
      variables: [Variable(fromId), Variable(toId)],
      updates: {categories},
    );
  }

  /// Category ids ordered by usage in the last window (most used first).
  Future<List<String>> mostUsed(String kind, int sinceMs, int limit) async {
    final rows = await customSelect(
      '''SELECT t.category_id AS id, count(*) AS n FROM transactions t
           JOIN categories c ON c.id = t.category_id
          WHERE c.kind = ?1 AND c.archived = 0 AND t.date >= ?2
          GROUP BY t.category_id ORDER BY n DESC LIMIT ?3''',
      variables: [Variable(kind), Variable(sinceMs), Variable(limit)],
      readsFrom: {transactions, categories},
    ).get();
    return [for (final r in rows) r.read<String>('id')];
  }

  Future<List<BudgetRow>> budgetsUsing(String categoryId) =>
      (select(budgets)..where((b) => b.categoryId.equals(categoryId) & b.archived.equals(false))).get();
}
