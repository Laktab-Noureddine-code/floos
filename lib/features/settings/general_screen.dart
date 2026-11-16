import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/data/repositories/settings_repository.dart';
import 'package:floos/features/common/pickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings › General: base currency, month/week start, theme, hide amounts.
class GeneralSettingsScreen extends ConsumerWidget {
  const GeneralSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = ref.watch(prefsProvider);
    final repo = ref.read(settingsRepoProvider);
    Future<void> choose<T>(String title, List<(T, String)> options, T current, Future<void> Function(T) on) async {
      final v = await showAppSheet<T>(
        context,
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetTitle(title),
            for (final (value, label) in options)
              ListTile(
                title: Text(label),
                trailing: value == current ? Icon(Icons.check_rounded, color: ctx.colors.primary) : null,
                onTap: () => Navigator.pop(ctx, value),
              ),
            const SizedBox(height: AppSpace.lg),
          ],
        ),
      );
      if (v != null) await on(v);
    }

    final themeLabels = {'system': l.themeSystem, 'light': l.themeLight, 'dark': l.themeDark};
    final weekLabels = {1: l.weekMonday, 6: l.weekSaturday, 7: l.weekSunday};
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsGeneral)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: [
          SettingsGroup(
            children: [
              SettingsRow(
                label: l.settingsBaseCurrency,
                value: p.baseCurrency,
                onTap: () async {
                  final c = await pickCurrency(context, selected: p.baseCurrency);
                  if (c == null || c == p.baseCurrency) return;
                  final missing = await ref.read(ratesRepoProvider).missingRatesFor(c);
                  if (missing.isNotEmpty) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.baseCurrencyBlocked(missing.join(', ')))));
                    }
                    return;
                  }
                  await repo.set(SettingKeys.baseCurrency, Currencies.of(c).code);
                },
              ),
              SettingsRow(
                label: l.settingsMonthStart,
                value: '${p.monthStartDay}',
                onTap: () => choose<int>(
                  l.settingsMonthStart,
                  [for (var d = 1; d <= 28; d++) (d, '$d')],
                  p.monthStartDay,
                  (v) => repo.set(SettingKeys.monthStartDay, v),
                ),
              ),
              SettingsRow(
                label: l.settingsWeekStart,
                value: weekLabels[p.weekStartDay],
                onTap: () => choose<int>(
                  l.settingsWeekStart,
                  [for (final e in weekLabels.entries) (e.key, e.value)],
                  p.weekStartDay,
                  (v) => repo.set(SettingKeys.weekStartDay, v),
                ),
              ),
              SettingsRow(
                label: l.settingsTheme,
                value: themeLabels[p.themeMode],
                onTap: () => choose<String>(
                  l.settingsTheme,
                  [for (final e in themeLabels.entries) (e.key, e.value)],
                  p.themeMode,
                  (v) => repo.set(SettingKeys.themeMode, v),
                ),
              ),
              SwitchRow(
                label: l.settingsHideAmounts,
                value: p.hideAmountsDefault,
                onChanged: (v) => repo.setAll({SettingKeys.hideAmountsDefault: v, SettingKeys.hideAmounts: v}),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
