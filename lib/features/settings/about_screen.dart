import 'dart:convert';

import 'package:floos/app/providers.dart';
import 'package:floos/app/services_providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/utils/formatters.dart';
import 'package:floos/core/widgets/nav.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/features/settings/debug_tools.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

/// Settings › About: version, privacy, licenses, diagnostics.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsAbout)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: [
          const Center(child: AppLogo(size: 88)),
          const SizedBox(height: AppSpace.md),
          Center(child: Text(l.appName, style: context.text.titleL)),
          const SizedBox(height: AppSpace.lg),
          SettingsGroup(
            children: [
              SettingsRow(label: l.aboutVersion, value: ref.watch(appVersionProvider), chevron: false),
              SettingsRow(
                label: l.aboutPrivacy,
                onTap: () => showAppSheet<void>(
                  context,
                  builder: (_) => Padding(
                    padding: const EdgeInsets.all(AppSpace.x2),
                    child: Text(l.aboutPrivacyBody, style: context.text.bodyM),
                  ),
                ),
              ),
              SettingsRow(
                label: l.aboutLicenses,
                onTap: () => showLicensePage(context: context, applicationName: l.appName),
              ),
              SettingsRow(label: l.aboutDiagnostics, onTap: () => context.push('/settings/diagnostics')),
              if (kDebugMode)
                SettingsRow(
                  label: 'Debug: générer 10 000 opérations',
                  onTap: () async {
                    final n = await generateDemoTransactions(ref);
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$n')));
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Diagnostics viewer (sanitized error log, constitution II).
class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final dao = ref.watch(databaseProvider).errorLogDao;
    return StreamBuilder<List<ErrorRow>>(
      stream: dao.watchAll(),
      builder: (context, snap) {
        final rows = snap.data ?? const <ErrorRow>[];
        return Scaffold(
          appBar: AppBar(
            title: Text(l.aboutDiagnostics),
            actions: [
              if (rows.isNotEmpty) ...[
                IconButton(
                  tooltip: l.diagExport,
                  icon: const Icon(Icons.ios_share_rounded),
                  onPressed: () {
                    final text = rows
                        .map((r) => '${DateTime.fromMillisecondsSinceEpoch(r.createdAt).toIso8601String()} ${r.kind} ${r.message}\n${r.stack ?? ''}')
                        .join('\n');
                    SharePlus.instance.share(ShareParams(text: utf8.decode(utf8.encode(text))));
                  },
                ),
                IconButton(tooltip: l.diagClear, icon: const Icon(Icons.delete_outline_rounded), onPressed: dao.clear),
              ],
            ],
          ),
          body: rows.isEmpty
              ? Center(child: Text(l.diagEmpty, style: context.text.bodyM))
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpace.screen),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, i) => ListTile(
                    title: Text('${rows[i].kind} · ${rows[i].message}'),
                    subtitle: Text(Fmt.dateTime(DateTime.fromMillisecondsSinceEpoch(rows[i].createdAt))),
                  ),
                ),
        );
      },
    );
  }
}
