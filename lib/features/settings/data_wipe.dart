import 'package:floos/app/providers.dart';
import 'package:floos/data/db/db_connection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Deletes every table, attachment and the PIN, then reseeds categories.
Future<void> wipeAllData(WidgetRef ref) async {
  final db = ref.read(databaseProvider);
  await db.wipeAll();
  await ref.read(attachmentStoreProvider).wipe();
  final store = ref.read(secretStoreProvider);
  for (final k in [SecretKeys.pinHash, SecretKeys.pinFailures, SecretKeys.pinLockedUntil]) {
    await store.delete(k);
  }
  await ref.read(uiPrefsProvider).clear();
}
