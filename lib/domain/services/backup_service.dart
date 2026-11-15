import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:floos/core/time/clock.dart';
import 'package:floos/core/utils/logger.dart';
import 'package:floos/core/utils/result.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:path/path.dart' as p;

/// Parsed backup manifest (contracts/backup-format.md).
class BackupManifest {
  const BackupManifest({
    required this.appVersion,
    required this.schemaVersion,
    required this.createdAt,
    required this.baseCurrency,
    required this.counts,
    required this.sha256,
    required this.encrypted,
    this.salt,
    this.iterations,
    this.nonces = const {},
    this.locale = 'fr',
  });

  factory BackupManifest.fromJson(Map<String, dynamic> j) {
    final kdf = j['kdf'] as Map<String, dynamic>?;
    final cipher = j['cipher'] as Map<String, dynamic>?;
    return BackupManifest(
      appVersion: j['app_version'] as String? ?? '',
      schemaVersion: j['schema_version'] as int,
      createdAt: DateTime.parse(j['created_at'] as String),
      baseCurrency: j['base_currency'] as String? ?? '',
      locale: j['device_locale'] as String? ?? 'fr',
      counts: (j['counts'] as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int)),
      sha256: (j['sha256'] as Map<String, dynamic>).map((k, v) => MapEntry(k, v as String)),
      encrypted: j['encrypted'] as bool? ?? false,
      salt: kdf?['salt'] as String?,
      iterations: kdf?['iterations'] as int?,
      nonces: ((cipher?['nonces'] as Map<String, dynamic>?) ?? {}).map((k, v) => MapEntry(k, v as String)),
    );
  }

  final String appVersion;
  final int schemaVersion;
  final DateTime createdAt;
  final String baseCurrency;
  final String locale;
  final Map<String, int> counts;
  final Map<String, String> sha256;
  final bool encrypted;
  final String? salt;
  final int? iterations;
  final Map<String, String> nonces;

  Map<String, Object?> toJson() => {
    'app': BackupService.appId,
    'app_version': appVersion,
    'schema_version': schemaVersion,
    'created_at': createdAt.toUtc().toIso8601String(),
    'device_locale': locale,
    'base_currency': baseCurrency,
    'counts': counts,
    'sha256': sha256,
    'encrypted': encrypted,
    if (encrypted) 'kdf': {'algo': 'pbkdf2', 'salt': salt, 'iterations': iterations},
    if (encrypted) 'cipher': {'algo': 'aes-256-gcm', 'nonces': nonces},
  };
}

/// An opened, validated backup ready to be restored.
class BackupPreview {
  const BackupPreview(this.file, this.manifest);
  final File file;
  final BackupManifest manifest;
}

/// Backup / restore with optional password encryption (APP_PROMPT §7.1).
class BackupService {
  BackupService({
    required this.db,
    required this.attachmentsDir,
    required this.backupsDir,
    required this.appVersion,
    this.clock = const Clock(),
  });

  static const appId = 'floos';
  static const iterations = 310000;
  static const safetyPrefix = 'floos_safety_';
  static const backupPrefix = 'floos_backup_';
  static const extension = '.floos';
  static const safetyKeep = 3;

  final AppDatabase db;
  final Directory attachmentsDir;
  final Directory backupsDir;
  final String appVersion;
  final Clock clock;

  /// Counted tables shown in the restore preview.
  static const countedTables = [
    'transactions',
    'accounts',
    'categories',
    'budgets',
    'goals',
    'recurring_rules',
    'debts',
    'tags',
    'attachments',
  ];

  static String _stamp(DateTime d) =>
      '${d.year}${_2(d.month)}${_2(d.day)}_${_2(d.hour)}${_2(d.minute)}';
  static String _2(int v) => v.toString().padLeft(2, '0');

  /// Creates a backup file. With [password], content is AES-GCM encrypted
  /// with a PBKDF2-HMAC-SHA256 (310k) key.
  Future<Result<File>> create({String? password, bool safety = false, String? baseCurrency, int? iterationsOverride}) async {
    final tmp = await Directory.systemTemp.createTemp('floos_bk');
    try {
      await backupsDir.create(recursive: true);
      final plain = File(p.join(tmp.path, 'data.db'));
      await exportPlain(plain);
      final files = <String, Uint8List>{'data.db': await plain.readAsBytes()};
      if (attachmentsDir.existsSync()) {
        await for (final f in attachmentsDir.list()) {
          if (f is File) files['attachments/${p.basename(f.path)}'] = await f.readAsBytes();
        }
      }
      String? salt;
      final nonces = <String, String>{};
      final rounds = iterationsOverride ?? iterations;
      if (password != null && password.isNotEmpty) {
        final s = _random(16);
        salt = base64Encode(s);
        final key = await deriveKey(password, s, rounds);
        for (final e in files.entries.toList()) {
          final n = _random(12);
          nonces[e.key] = base64Encode(n);
          files[e.key] = await _encrypt(e.value, key, n);
        }
      }
      final manifest = BackupManifest(
        appVersion: appVersion,
        schemaVersion: db.schemaVersion,
        createdAt: clock.now(),
        baseCurrency: baseCurrency ?? '',
        counts: await _counts(),
        sha256: {for (final e in files.entries) e.key: crypto.sha256.convert(e.value).toString()},
        encrypted: salt != null,
        salt: salt,
        iterations: salt != null ? rounds : null,
        nonces: nonces,
      );
      final archive = Archive()
        ..addFile(ArchiveFile.bytes('manifest.json', utf8.encode(jsonEncode(manifest.toJson()))));
      for (final e in files.entries) {
        archive.addFile(ArchiveFile.bytes(e.key, e.value));
      }
      final name = '${safety ? safetyPrefix : backupPrefix}${_stamp(clock.now())}$extension';
      final out = File(p.join(backupsDir.path, name));
      await out.writeAsBytes(ZipEncoder().encodeBytes(archive), flush: true);
      if (safety) await rotate(safetyKeep, prefix: safetyPrefix);
      return Ok(out);
    } on Object catch (e, st) {
      AppLogger.error('backup_create', e, st);
      return Err(AppFailure.storage('backup_failed', details: e.runtimeType.toString()));
    } finally {
      await tmp.delete(recursive: true);
    }
  }

  /// Writes a consistent, unencrypted copy of the database to [target].
  Future<void> exportPlain(File target) async {
    if (target.existsSync()) await target.delete();
    final path = target.path.replaceAll("'", "''");
    await _attach(path, 'bk');
    try {
      final schema = await _schema('main');
      await db.transaction(() async {
        for (final t in schema.tables) {
          final create = t.sql.replaceFirst(
            RegExp(r'^CREATE TABLE\s+(IF NOT EXISTS\s+)?"?\w+"?'),
            'CREATE TABLE bk."${t.name}"',
          );
          await db.customStatement(create);
          await db.customStatement('INSERT INTO bk."${t.name}" SELECT * FROM main."${t.name}"');
        }
      });
      await db.customStatement('PRAGMA bk.user_version = ${db.schemaVersion}');
    } finally {
      await db.customStatement('DETACH DATABASE bk');
    }
  }

  Future<void> _attach(String path, String alias) async {
    try {
      await db.customStatement("ATTACH DATABASE '$path' AS $alias KEY ''");
    } on Object {
      await db.customStatement("ATTACH DATABASE '$path' AS $alias");
    }
  }

  /// Tables of a schema (excluding sqlite internals and FTS shadow tables).
  Future<({List<({String name, String sql})> tables})> _schema(String alias) async {
    final rows = await db.customSelect(
      "SELECT name, sql FROM $alias.sqlite_master WHERE type = 'table' AND sql IS NOT NULL "
      "AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'transactions_fts%' ORDER BY rowid",
    ).get();
    return (tables: [for (final r in rows) (name: r.read<String>('name'), sql: r.read<String>('sql'))]);
  }

  Future<Map<String, int>> _counts() async => {
    for (final t in countedTables)
      t: (await db.customSelect('SELECT count(*) AS c FROM "$t"').getSingle()).read<int>('c'),
  };

  /// Validates a backup file (manifest, app id, checksums, schema version).
  Future<Result<BackupPreview>> inspect(File file) async {
    try {
      final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
      final mf = archive.findFile('manifest.json');
      if (mf == null) return const Err(AppFailure.importFormat('backup_invalid'));
      final json = jsonDecode(utf8.decode(mf.readBytes()!)) as Map<String, dynamic>;
      if (json['app'] != appId) return const Err(AppFailure.importFormat('backup_invalid'));
      final manifest = BackupManifest.fromJson(json);
      if (manifest.schemaVersion > db.schemaVersion) {
        return const Err(AppFailure.importFormat('backup_newer_schema'));
      }
      for (final e in manifest.sha256.entries) {
        final f = archive.findFile(e.key);
        if (f == null || crypto.sha256.convert(f.readBytes()!).toString() != e.value) {
          return const Err(AppFailure.importFormat('backup_checksum'));
        }
      }
      if (archive.findFile('data.db') == null) return const Err(AppFailure.importFormat('backup_invalid'));
      return Ok(BackupPreview(file, manifest));
    } on Object catch (e, st) {
      AppLogger.error('backup_inspect', e, st);
      return const Err(AppFailure.importFormat('backup_invalid'));
    }
  }

  /// Restores [preview] atomically. A safety backup must be created by the
  /// caller first (Constitution VII). On any failure nothing changes.
  Future<Result<void>> restore(BackupPreview preview, {String? password}) async {
    final tmp = await Directory.systemTemp.createTemp('floos_rs');
    try {
      final archive = ZipDecoder().decodeBytes(await preview.file.readAsBytes());
      final m = preview.manifest;
      SecretKey? key;
      if (m.encrypted) {
        if (password == null || password.isEmpty) return const Err(AppFailure.crypto('backup_wrong_password'));
        key = await deriveKey(password, base64Decode(m.salt!), m.iterations ?? iterations);
      }
      Future<Uint8List?> read(String name) async {
        final bytes = archive.findFile(name)?.readBytes();
        if (bytes == null) return null;
        if (key == null) return bytes;
        return _decrypt(bytes, key, base64Decode(m.nonces[name]!));
      }

      final Uint8List? dbBytes;
      try {
        dbBytes = await read('data.db');
      } on SecretBoxAuthenticationError {
        return const Err(AppFailure.crypto('backup_wrong_password'));
      }
      if (dbBytes == null) return const Err(AppFailure.importFormat('backup_invalid'));
      final plain = File(p.join(tmp.path, 'data.db'));
      await plain.writeAsBytes(dbBytes, flush: true);
      final attachments = <String, Uint8List>{};
      for (final f in archive.files) {
        if (f.isFile && f.name.startsWith('attachments/')) {
          attachments[p.basename(f.name)] = (await read(f.name))!;
        }
      }
      await _importPlain(plain);
      // Swap attachment files only after the DB swap succeeded.
      if (attachmentsDir.existsSync()) await attachmentsDir.delete(recursive: true);
      await attachmentsDir.create(recursive: true);
      for (final e in attachments.entries) {
        await File(p.join(attachmentsDir.path, e.key)).writeAsBytes(e.value, flush: true);
      }
      return const Ok(null);
    } on AppFailureException catch (e) {
      return Err(e.failure);
    } on Object catch (e, st) {
      AppLogger.error('backup_restore', e, st);
      return Err(AppFailure.storage('backup_failed', details: e.runtimeType.toString()));
    } finally {
      await tmp.delete(recursive: true);
    }
  }

  /// Replaces all rows with the backup's rows in one transaction. Columns are
  /// matched by name so older schemas migrate (new columns get defaults).
  Future<void> _importPlain(File plain) async {
    final path = plain.path.replaceAll("'", "''");
    await _attach(path, 'rs');
    try {
      final v = (await db.customSelect('PRAGMA rs.user_version').getSingle()).data.values.first as int;
      if (v > db.schemaVersion) throw const AppFailureException(AppFailure.importFormat('backup_newer_schema'));
      final mine = await _schema('main');
      final theirs = {for (final t in (await _schema('rs')).tables) t.name};
      await db.customStatement('PRAGMA foreign_keys = OFF');
      try {
        await db.transaction(() async {
          for (final t in mine.tables.reversed) {
            await db.customStatement('DELETE FROM main."${t.name}"');
          }
          for (final t in mine.tables) {
            if (!theirs.contains(t.name)) continue;
            final a = await _columns('main', t.name);
            final b = await _columns('rs', t.name);
            final cols = a.where(b.contains).map((c) => '"$c"').join(', ');
            await db.customStatement('INSERT INTO main."${t.name}" ($cols) SELECT $cols FROM rs."${t.name}"');
          }
          await db.customStatement("INSERT INTO transactions_fts(transactions_fts) VALUES('rebuild')");
          final fk = await db.customSelect('PRAGMA main.foreign_key_check').get();
          if (fk.isNotEmpty) throw const AppFailureException(AppFailure.importFormat('backup_invalid'));
        });
      } finally {
        await db.customStatement('PRAGMA foreign_keys = ON');
      }
      // Notify drift streams that everything changed.
      db.notifyUpdates({for (final t in db.allTables) TableUpdate.onTable(t)});
    } finally {
      await db.customStatement('DETACH DATABASE rs');
    }
  }

  Future<List<String>> _columns(String alias, String table) async {
    final rows = await db.customSelect('PRAGMA $alias.table_info("$table")').get();
    return [for (final r in rows) r.read<String>('name')];
  }

  /// Keeps the newest [keep] backups with [prefix].
  Future<void> rotate(int keep, {String prefix = backupPrefix}) async {
    final list = await this.list(prefix: prefix);
    for (final f in list.skip(keep)) {
      await f.delete();
    }
  }

  /// Backups (newest first).
  Future<List<File>> list({String prefix = backupPrefix}) async {
    if (!backupsDir.existsSync()) return [];
    final files = [
      await for (final f in backupsDir.list())
        if (f is File && p.basename(f.path).startsWith(prefix) && f.path.endsWith(extension)) f,
    ]..sort((a, b) => p.basename(b.path).compareTo(p.basename(a.path)));
    return files;
  }

  /// Whether an automatic backup is due for [frequency].
  static bool isDue(String frequency, DateTime? last, DateTime now) {
    if (frequency == 'off') return false;
    if (last == null) return true;
    final days = switch (frequency) {
      'daily' => 1,
      'weekly' => 7,
      'monthly' => 30,
      _ => 1 << 30,
    };
    return now.difference(last).inHours >= days * 24 - 1;
  }

  static List<int> _random(int n) {
    final r = Random.secure();
    return List<int>.generate(n, (_) => r.nextInt(256));
  }

  /// PBKDF2-HMAC-SHA256 key derivation (runs in a background isolate).
  static Future<SecretKey> deriveKey(String password, List<int> salt, int rounds) async {
    final bytes = await Isolate.run(() async {
      final kdf = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: rounds, bits: 256);
      final k = await kdf.deriveKeyFromPassword(password: password, nonce: salt);
      return k.extractBytes();
    });
    return SecretKey(bytes);
  }

  static final _aes = AesGcm.with256bits();

  static Future<Uint8List> _encrypt(Uint8List data, SecretKey key, List<int> nonce) async {
    final box = await _aes.encrypt(data, secretKey: key, nonce: nonce);
    return Uint8List.fromList([...box.cipherText, ...box.mac.bytes]);
  }

  static Future<Uint8List> _decrypt(Uint8List data, SecretKey key, List<int> nonce) async {
    const macLen = 16;
    final box = SecretBox(
      data.sublist(0, data.length - macLen),
      nonce: nonce,
      mac: Mac(data.sublist(data.length - macLen)),
    );
    return Uint8List.fromList(await _aes.decrypt(box, secretKey: key));
  }
}

/// Internal exception carrying an [AppFailure] out of a transaction.
class AppFailureException implements Exception {
  const AppFailureException(this.failure);
  final AppFailure failure;
}
