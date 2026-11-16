import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:floos/app/providers.dart';
import 'package:floos/app/services_providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/utils/formatters.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/data/repositories/settings_repository.dart';
import 'package:floos/features/backup/exporters.dart';
import 'package:floos/features/common/form_fields.dart';
import 'package:floos/features/settings/data_wipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

/// Settings › Backup & data.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  void _snack(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<String?> _askPassword({required String title, String? hint, bool optional = true}) async {
    final l = context.l10n;
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, obscureText: true, autofocus: true, decoration: InputDecoration(hintText: hint ?? (optional ? l.backupPasswordHint : null))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.confirm)),
        ],
      ),
    );
    final v = c.text;
    c.dispose();
    return ok == true ? v : null;
  }

  Future<void> _backupNow() async {
    final l = context.l10n;
    final pw = await _askPassword(title: l.backupPassword);
    if (pw == null || !mounted) return;
    setState(() => _busy = true);
    final svc = ref.read(backupServiceProvider);
    final r = await svc.create(password: pw.isEmpty ? null : pw, baseCurrency: ref.read(prefsProvider).baseCurrency);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.isErr) return showFailure(context, r.failureOrNull);
    await ref.read(settingsRepoProvider).set(SettingKeys.lastBackupAt, ref.read(clockProvider).now());
    await svc.rotate(ref.read(prefsProvider).autoBackupKeep);
    final file = r.valueOrNull!;
    if (!mounted) return;
    _snack(l.backupCreated);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], fileNameOverrides: [p.basename(file.path)]));
  }

  Future<void> _restore() async {
    final l = context.l10n;
    final picked = await FilePicker.pickFile();
    if (picked == null || !mounted) return;
    final tmp = await Directory.systemTemp.createTemp('floos_pick');
    final file = File(p.join(tmp.path, 'restore.floos'));
    await file.writeAsBytes(await picked.readAsBytes());
    final svc = ref.read(backupServiceProvider);
    final insp = await svc.inspect(file);
    if (!mounted) return;
    if (insp.isErr) return showFailure(context, insp.failureOrNull);
    final prev = insp.valueOrNull!;
    final m = prev.manifest;
    final n = m.counts['transactions'] ?? 0;
    if (!await confirmDialog(
      context,
      title: l.backupRestore,
      message: '${l.backupRestorePreview(Fmt.dateTime(m.createdAt.toLocal()), n)}\n\n${l.backupRestoreWarning}',
      danger: true,
    )) {
      return;
    }
    String? pw;
    if (m.encrypted) {
      if (!mounted) return;
      pw = await _askPassword(title: l.backupEncrypted, hint: '', optional: false);
      if (pw == null) return;
    }
    setState(() => _busy = true);
    final safety = await svc.create(safety: true, baseCurrency: ref.read(prefsProvider).baseCurrency);
    if (safety.isErr) {
      if (mounted) {
        setState(() => _busy = false);
        showFailure(context, safety.failureOrNull);
      }
      return;
    }
    final r = await svc.restore(prev, password: pw);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.isErr) return showFailure(context, r.failureOrNull);
    _snack(l.backupRestoreDone);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = ref.watch(prefsProvider);
    final repo = ref.read(settingsRepoProvider);
    final freq = {'off': l.backupAutoOff, 'daily': l.backupAutoDaily, 'weekly': l.backupAutoWeekly, 'monthly': l.backupAutoMonthly};
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsBackup)),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(AppSpace.screen),
            children: [
              AppCard(
                child: Text(p.lastBackupAt == null ? l.backupNever : l.backupLast(Fmt.dateTime(p.lastBackupAt!)), style: context.text.bodyM),
              ),
              const SizedBox(height: AppSpace.md),
              PrimaryButton(label: l.backupNow, onPressed: _busy ? null : _backupNow),
              const SizedBox(height: AppSpace.sm),
              PrimaryButton(label: l.backupRestore, secondary: true, onPressed: _busy ? null : _restore),
              const SizedBox(height: AppSpace.lg),
              SettingsGroup(
                children: [
                  SettingsRow(
                    label: l.backupAuto,
                    value: freq[p.autoBackupFrequency],
                    onTap: () async {
                      final v = await showAppSheet<String>(
                        context,
                        builder: (ctx) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SheetTitle(l.backupAuto),
                            for (final e in freq.entries) ListTile(title: Text(e.value), onTap: () => Navigator.pop(ctx, e.key)),
                            const SizedBox(height: AppSpace.lg),
                          ],
                        ),
                      );
                      if (v != null) await repo.set(SettingKeys.autoBackupFrequency, v);
                    },
                  ),
                  SettingsRow(
                    label: l.backupKeep,
                    value: '${p.autoBackupKeep}',
                    onTap: () async {
                      final v = await showAppSheet<int>(
                        context,
                        builder: (ctx) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SheetTitle(l.backupKeep),
                            for (final n in const [1, 3, 5, 10, 20]) ListTile(title: Text('$n'), onTap: () => Navigator.pop(ctx, n)),
                            const SizedBox(height: AppSpace.lg),
                          ],
                        ),
                      );
                      if (v != null) await repo.set(SettingKeys.autoBackupKeep, v);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              SettingsGroup(
                children: [
                  SettingsRow(label: l.dataExportCsv, onTap: () => exportTransactionsCsv(context, ref)),
                  SettingsRow(label: l.dataImportCsv, onTap: () => context.push('/backup/import-csv')),
                  SettingsRow(
                    label: l.dataDeleteAll,
                    danger: true,
                    onTap: () async {
                      final ok = await typeToConfirmDialog(
                        context,
                        title: l.dataDeleteAll,
                        message: l.dataDeleteAllBody,
                        expected: l.dataDeleteWord,
                        confirmLabel: l.delete,
                      );
                      if (!ok) return;
                      await wipeAllData(ref);
                      if (mounted) _snack(l.dataDeleted);
                    },
                  ),
                ],
              ),
            ],
          ),
          if (_busy) const Positioned.fill(child: ColoredBox(color: Color(0x66000000), child: Center(child: CircularProgressIndicator()))),
        ],
      ),
    );
  }
}
