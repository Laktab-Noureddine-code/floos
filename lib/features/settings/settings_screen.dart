import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/data/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Settings tab (design.md §4.5).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final prefs = ref.watch(prefsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSizes.scrollBottomPadding),
        children: [
          SettingsGroup(
            title: l.settingsProfile,
            children: [
              SettingsRow(
                label: l.settingsDisplayName,
                icon: PhosphorIconsRegular.user,
                value: prefs.displayName.isEmpty ? null : prefs.displayName,
                onTap: () => _editName(context, ref, prefs.displayName),
              ),
              SettingsRow(
                label: l.settingsGeneral,
                icon: PhosphorIconsRegular.slidersHorizontal,
                onTap: () => context.push('/settings/general'),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          SettingsGroup(
            title: l.settingsManage,
            children: [
              SettingsRow(label: l.accounts, icon: PhosphorIconsRegular.wallet, onTap: () => context.push('/accounts')),
              SettingsRow(label: l.categories, icon: PhosphorIconsRegular.squaresFour, onTap: () => context.push('/categories')),
              SettingsRow(label: l.tags, icon: PhosphorIconsRegular.hash, onTap: () => context.push('/tags')),
              SettingsRow(label: l.settingsRates, icon: PhosphorIconsRegular.currencyCircleDollar, onTap: () => context.push('/rates')),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          SettingsGroup(
            children: [
              SettingsRow(label: l.settingsNotifications, icon: PhosphorIconsRegular.bell, onTap: () => context.push('/settings/notifications')),
              SettingsRow(label: l.settingsSecurity, icon: PhosphorIconsRegular.lockKey, onTap: () => context.push('/settings/security')),
              SettingsRow(label: l.settingsBackup, icon: PhosphorIconsRegular.cloudArrowUp, onTap: () => context.push('/settings/backup')),
              SettingsRow(label: l.settingsAbout, icon: PhosphorIconsRegular.info, onTap: () => context.push('/settings/about')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context, WidgetRef ref, String current) async {
    final l = context.l10n;
    final c = TextEditingController(text: current);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.settingsDisplayName),
        content: TextField(controller: c, autofocus: true, maxLength: 40),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text(l.save)),
        ],
      ),
    );
    c.dispose();
    if (v != null) await ref.read(settingsRepoProvider).set(SettingKeys.displayName, v);
  }
}
