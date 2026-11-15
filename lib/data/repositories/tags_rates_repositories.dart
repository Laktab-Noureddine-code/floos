import 'package:drift/drift.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/utils/result.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/repositories/repo_base.dart';
import 'package:floos/domain/services/fx_service.dart';

class TagsRepository extends RepoBase {
  TagsRepository(super.db, {super.clock, super.hooks});

  Stream<List<TagRow>> watchAll() => db.tagsDao.watchAll();

  Future<List<TagRow>> getAll() => db.tagsDao.getAll();

  Stream<Map<String, int>> watchUsage() => db.tagsDao.watchUsage();

  /// Creates a tag or returns the existing one with the same name.
  Future<Result<String>> ensure(String name, {String color = 'purple'}) => guard(() async {
    final n = name.trim();
    if (n.isEmpty || n.length > 30) return const Err(AppFailure.validation('tag_name_length'));
    final existing = await db.tagsDao.byName(n);
    if (existing != null) return Ok(existing.id);
    final id = newId();
    final now = nowMs;
    await db.tagsDao.upsert(
      TagsCompanion.insert(id: id, createdAt: now, updatedAt: now, name: n, color: color),
    );
    return Ok(id);
  });

  Future<Result<void>> update(String id, String name, String color) => guard(() async {
    final n = name.trim();
    if (n.isEmpty || n.length > 30) return const Err(AppFailure.validation('tag_name_length'));
    final other = await db.tagsDao.byName(n);
    if (other != null && other.id != id) return const Err(AppFailure.conflict('tag_name_taken'));
    await (db.update(db.tags)..where((t) => t.id.equals(id)))
        .write(TagsCompanion(name: Value(n), color: Value(color), updatedAt: Value(nowMs)));
    return const Ok(null);
  });

  Future<Result<void>> delete(String id) => guard(() async {
    await db.tagsDao.deleteById(id);
    await hooks.onDataChanged();
    return const Ok(null);
  });
}

class RatesRepository extends RepoBase {
  RatesRepository(super.db, {super.clock, super.hooks});

  Stream<List<RateRow>> watchAll() => db.ratesDao.watchAll();

  Future<FxService> fx() async => FxService((await db.ratesDao.getAll()).map(toFx));

  Stream<FxService> watchFx() => db.ratesDao.watchAll().map((rows) => FxService(rows.map(toFx)));

  static FxRate toFx(RateRow r) => FxRate(
    from: r.fromCode,
    to: r.toCode,
    rateE6: r.rateE6,
    day: LocalDay.fromStorage(r.date),
  );

  Future<Result<void>> add(String from, String to, int rateE6, LocalDay day) => guard(() async {
    if (from == to) return const Err(AppFailure.validation('rate_same_currency'));
    if (!Currencies.isKnown(from) || !Currencies.isKnown(to)) {
      return const Err(AppFailure.validation('currency_invalid'));
    }
    if (rateE6 <= 0) return const Err(AppFailure.validation('rate_invalid'));
    final now = nowMs;
    await db.ratesDao.upsertRate(
      RateRow(
        id: newId(),
        createdAt: now,
        updatedAt: now,
        fromCode: from,
        toCode: to,
        rateE6: rateE6,
        date: day.toStorage(),
      ),
    );
    await hooks.onDataChanged();
    return const Ok(null);
  });

  Future<Result<void>> delete(String id) => guard(() async {
    await db.ratesDao.deleteById(id);
    await hooks.onDataChanged();
    return const Ok(null);
  });

  /// Currencies used by accounts/debts that lack a rate to [base]
  /// (blocks base-currency changes, APP_PROMPT §13.7).
  Future<Set<String>> missingRatesFor(String base) async {
    final fx = await this.fx();
    final rows = await db.customSelect(
      'SELECT DISTINCT currency_code AS c FROM accounts UNION SELECT DISTINCT currency_code FROM debts',
      readsFrom: {db.accounts, db.debts},
    ).get();
    return {
      for (final r in rows)
        if (r.read<String>('c') != base && !fx.hasAnyRate(r.read<String>('c'), base)) r.read<String>('c'),
    };
  }
}
