import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Abstraction over secure storage so tests can use an in-memory fake.
abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

/// Keychain / Keystore-backed [SecretStore].
class DeviceSecretStore implements SecretStore {
  const DeviceSecretStore();

  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}

/// In-memory [SecretStore] for tests and integration runs.
class MemorySecretStore implements SecretStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> deleteAll() async => values.clear();
}

/// Names of secure-storage keys.
abstract final class SecretKeys {
  static const dbKey = 'db_key_v1';
  static const pinHash = 'pin_hash_v1';
  static const pinFailures = 'pin_failures';
  static const pinLockedUntil = 'pin_locked_until';
}

/// Returns the 32-byte DB key (hex), generating it on first run.
Future<String> obtainDbKey(SecretStore store) async {
  final existing = await store.read(SecretKeys.dbKey);
  if (existing != null && existing.length == 64) return existing;
  final rnd = Random.secure();
  final hex = List.generate(32, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  await store.write(SecretKeys.dbKey, hex);
  return hex;
}

/// Location of the encrypted database file.
Future<File> databaseFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File(p.join(dir.path, 'floos.db'));
}

/// Opens the encrypted database at [file] with [hexKey].
QueryExecutor openEncrypted(File file, String hexKey) => NativeDatabase.createInBackground(
  file,
  setup: (db) {
    db
      ..execute("PRAGMA cipher = 'sqlcipher';")
      ..execute('PRAGMA legacy = 4;')
      ..execute("PRAGMA key = \"x'$hexKey'\";");
    // Fails fast if the key is wrong or the file is not a database.
    db.select('SELECT count(*) FROM sqlite_master;');
  },
);

/// Opens the production database.
Future<AppDatabase> openAppDatabase(SecretStore store) async {
  final key = await obtainDbKey(store);
  final file = await databaseFile();
  return AppDatabase(openEncrypted(file, key));
}

/// In-memory database for tests.
AppDatabase openMemoryDatabase() => AppDatabase(NativeDatabase.memory());
