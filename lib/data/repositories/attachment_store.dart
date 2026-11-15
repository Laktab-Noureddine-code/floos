import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:floos/core/utils/logger.dart';
import 'package:floos/core/utils/result.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/repositories/repo_base.dart';
import 'package:path/path.dart' as p;

/// Compresses images to max 1600 px, JPEG quality 80 (APP_PROMPT §4.5).
typedef ImageCompressor = Future<Uint8List?> Function(String sourcePath);

/// Stores receipt images under `<appDocs>/attachments/<id>.jpg`.
class AttachmentStore extends RepoBase {
  AttachmentStore(super.db, {required this.directory, required this.compressor, super.clock});

  final Directory directory;
  final ImageCompressor compressor;

  static const maxSide = 1600;
  static const quality = 80;

  File fileFor(String attachmentId) => File(p.join(directory.path, '$attachmentId.jpg'));

  Future<List<AttachmentRow>> forTransaction(String txId) => db.attachmentsDao.forTransaction(txId);

  /// Compresses [sourcePath] and attaches it to [txId].
  Future<Result<AttachmentRow>> add(String txId, String sourcePath) => guard(() async {
    final bytes = await compressor(sourcePath);
    if (bytes == null || bytes.isEmpty) {
      return const Err(AppFailure.storage('attachment_failed'));
    }
    return await addBytes(txId, bytes, p.basename(sourcePath));
  });

  Future<Result<AttachmentRow>> addBytes(String txId, Uint8List bytes, String name) => guard(() async {
    await directory.create(recursive: true);
    final id = newId();
    await fileFor(id).writeAsBytes(bytes, flush: true);
    final now = nowMs;
    final row = AttachmentRow(
      id: id,
      createdAt: now,
      updatedAt: now,
      transactionId: txId,
      fileName: name,
      mime: 'image/jpeg',
      sizeBytes: bytes.length,
      sha256: sha256.convert(bytes).toString(),
    );
    await db.attachmentsDao.insertRow(row.toCompanion(false));
    return Ok(row);
  });

  /// Removes a single attachment (row + file).
  Future<Result<void>> remove(String attachmentId) => guard(() async {
    await db.attachmentsDao.deleteById(attachmentId);
    await deleteFiles([attachmentId]);
    return const Ok(null);
  });

  Future<void> deleteFiles(List<String> attachmentIds) async {
    for (final id in attachmentIds) {
      try {
        final f = fileFor(id);
        if (f.existsSync()) await f.delete();
      } on Object catch (e, st) {
        AppLogger.error('attachment_delete', e, st);
      }
    }
  }

  /// Deletes files without a matching row (e.g. app killed during Undo).
  Future<int> cleanupOrphans() async {
    if (!directory.existsSync()) return 0;
    final ids = {for (final a in await db.attachmentsDao.getAll()) a.id};
    var removed = 0;
    await for (final f in directory.list()) {
      if (f is! File) continue;
      final id = p.basenameWithoutExtension(f.path);
      if (!ids.contains(id)) {
        await f.delete();
        removed++;
      }
    }
    return removed;
  }

  Future<void> wipe() async {
    if (directory.existsSync()) await directory.delete(recursive: true);
  }
}
