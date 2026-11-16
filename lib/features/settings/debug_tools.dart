import 'dart:math';

import 'package:drift/drift.dart';
import 'package:floos/app/providers.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Debug-only: inserts [count] random transactions over the last 3 years on
/// the first account, to profile list/report performance (T069).
Future<int> generateDemoTransactions(WidgetRef ref, {int count = 10000}) async {
  final db = ref.read(databaseProvider);
  final accounts = await db.accountsDao.getAll();
  final cats = (await db.categoriesDao.getAll()).where((c) => c.kind == 'expense' && c.systemKey == null).toList();
  if (accounts.isEmpty || cats.isEmpty) return 0;
  final rnd = Random(42);
  final today = ref.read(clockProvider).today();
  const uuid = Uuid();
  final now = DateTime.now().millisecondsSinceEpoch;
  await db.batch((b) {
    for (var i = 0; i < count; i++) {
      final day = LocalDay.fromStorage(today.addDays(-rnd.nextInt(365 * 3)).toStorage());
      b.insert(
        db.transactions,
        TransactionsCompanion.insert(
          id: uuid.v4(),
          createdAt: now + i,
          updatedAt: now + i,
          type: 'expense',
          amount: 100 + rnd.nextInt(50000),
          accountId: accounts.first.id,
          categoryId: Value(cats[rnd.nextInt(cats.length)].id),
          date: day.toStorage(),
          payee: Value('Demo ${rnd.nextInt(200)}'),
        ),
      );
    }
  });
  return count;
}
