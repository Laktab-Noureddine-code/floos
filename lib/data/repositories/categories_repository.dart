import 'package:drift/drift.dart';
import 'package:floos/core/utils/result.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/db/seed.dart';
import 'package:floos/data/repositories/repo_base.dart';

/// Draft for creating/updating a category.
class CategoryDraft {
  const CategoryDraft({
    required this.name,
    required this.kind,
    required this.icon,
    required this.color,
    this.parentId,
    this.id,
  });

  final String? id;
  final String name;
  final String kind;
  final String icon;
  final String color;
  final String? parentId;
}

/// Outcome of a category deletion/merge.
class CategoryRemoval {
  const CategoryRemoval({this.archivedBudgets = 0});

  /// Budgets archived because their category disappeared (APP_PROMPT §13.4).
  final int archivedBudgets;
}

class CategoriesRepository extends RepoBase {
  CategoriesRepository(super.db, {super.clock, super.hooks});

  Stream<List<CategoryRow>> watchAll() => db.categoriesDao.watchAll();

  Future<List<CategoryRow>> getAll() => db.categoriesDao.getAll();

  Future<CategoryRow?> byId(String id) => db.categoriesDao.byId(id);

  Future<CategoryRow?> system(String key) => db.categoriesDao.bySystemKey(key);

  Future<List<String>> mostUsed(String kind, {int limit = 8}) => db.categoriesDao.mostUsed(
    kind,
    clock.today().addDays(-90).toStorage(),
    limit,
  );

  Future<Result<String>> save(CategoryDraft d) => guard(() async {
    final name = d.name.trim();
    if (name.isEmpty || name.length > 30) {
      return const Err(AppFailure.validation('category_name_length'));
    }
    if (d.kind != 'expense' && d.kind != 'income') {
      return const Err(AppFailure.validation('category_kind_invalid'));
    }
    final existing = d.id == null ? null : await db.categoriesDao.byId(d.id!);
    if (d.parentId != null) {
      if (d.parentId == d.id) return const Err(AppFailure.validation('category_parent_self'));
      final parent = await db.categoriesDao.byId(d.parentId!);
      if (parent == null) return const Err(AppFailure.notFound('category_not_found'));
      if (parent.parentId != null) {
        return const Err(AppFailure.validation('category_max_depth'));
      }
      if (parent.kind != d.kind) return const Err(AppFailure.validation('category_kind_mismatch'));
      if (d.id != null) {
        final all = await db.categoriesDao.getAll();
        if (all.any((c) => c.parentId == d.id)) {
          return const Err(AppFailure.validation('category_has_children'));
        }
      }
    }
    final now = nowMs;
    final id = d.id ?? newId();
    final all = await db.categoriesDao.getAll();
    await db.categoriesDao.upsert(
      CategoriesCompanion(
        id: Value(id),
        createdAt: Value(existing?.createdAt ?? now),
        updatedAt: Value(now),
        name: Value(name),
        kind: Value(existing?.isSystem ?? false ? existing!.kind : d.kind),
        parentId: Value(existing?.isSystem ?? false ? null : d.parentId),
        icon: Value(d.icon),
        color: Value(d.color),
        sortOrder: Value(existing?.sortOrder ?? all.length),
        archived: Value(existing?.archived ?? false),
        isSystem: Value(existing?.isSystem ?? false),
        systemKey: Value(existing?.systemKey),
      ),
    );
    await hooks.onDataChanged();
    return Ok(id);
  });

  Future<Result<void>> reorder(List<String> ids) => guard(() async {
    await db.transaction(() async {
      for (var i = 0; i < ids.length; i++) {
        await (db.update(db.categories)..where((c) => c.id.equals(ids[i])))
            .write(CategoriesCompanion(sortOrder: Value(i)));
      }
    });
    return const Ok(null);
  });

  Future<Result<void>> setArchived(String id, {required bool archived}) => guard(() async {
    final c = await db.categoriesDao.byId(id);
    if (c == null) return const Err(AppFailure.notFound('category_not_found'));
    if (c.isSystem && archived) return const Err(AppFailure.validation('category_system'));
    await (db.update(db.categories)..where((x) => x.id.equals(id) | x.parentId.equals(id)))
        .write(CategoriesCompanion(archived: Value(archived), updatedAt: Value(nowMs)));
    await hooks.onDataChanged();
    return const Ok(null);
  });

  Future<int> usageCount(String id) => db.categoriesDao.usageCount(id);

  /// Deletes [id]. If used, [replacementId] is required (re-assign);
  /// system categories can't be deleted.
  Future<Result<CategoryRemoval>> delete(String id, {String? replacementId}) => guard(() async {
    final c = await db.categoriesDao.byId(id);
    if (c == null) return const Err(AppFailure.notFound('category_not_found'));
    if (c.isSystem) return const Err(AppFailure.validation('category_system'));
    final used = await db.categoriesDao.usageCount(id);
    if (used > 0 && replacementId == null) {
      return const Err(AppFailure.conflict('category_in_use'));
    }
    return Ok(await _remove(c, replacementId));
  });

  /// Merges [sourceId] into [targetId] (re-assigns everything, deletes source).
  Future<Result<CategoryRemoval>> merge(String sourceId, String targetId) => guard(() async {
    if (sourceId == targetId) return const Err(AppFailure.validation('category_merge_same'));
    final s = await db.categoriesDao.byId(sourceId);
    final t = await db.categoriesDao.byId(targetId);
    if (s == null || t == null) return const Err(AppFailure.notFound('category_not_found'));
    if (s.isSystem) return const Err(AppFailure.validation('category_system'));
    if (s.kind != t.kind) return const Err(AppFailure.validation('category_kind_mismatch'));
    return Ok(await _remove(s, targetId));
  });

  Future<CategoryRemoval> _remove(CategoryRow c, String? replacementId) async {
    final now = nowMs;
    var archived = 0;
    await db.transaction(() async {
      if (replacementId != null) {
        final target = await db.categoriesDao.byId(replacementId);
        await db.categoriesDao.reassign(c.id, replacementId, now);
        // Keep max depth 1: children of a deleted parent become roots unless
        // the target itself is a root of the same kind.
        if (target == null || target.parentId != null) {
          await db.customUpdate(
            'UPDATE categories SET parent_id = NULL WHERE parent_id = ?',
            variables: [Variable(replacementId)],
            updates: {db.categories},
          );
        }
      }
      await db.customUpdate(
        'UPDATE categories SET parent_id = NULL WHERE parent_id = ?',
        variables: [Variable(c.id)],
        updates: {db.categories},
      );
      final budgets = await db.categoriesDao.budgetsUsing(c.id);
      for (final b in budgets) {
        await (db.update(db.budgets)..where((x) => x.id.equals(b.id)))
            .write(BudgetsCompanion(archived: const Value(true), updatedAt: Value(now)));
      }
      archived = budgets.length;
      await db.categoriesDao.deleteById(c.id);
    });
    await hooks.onTransactionsChanged({});
    return CategoryRemoval(archivedBudgets: archived);
  }

  /// Ensures system categories exist (after restores of foreign data).
  Future<String> adjustmentCategoryId() async {
    final c = await db.categoriesDao.bySystemKey(SystemCategory.adjustment);
    return c!.id;
  }
}
