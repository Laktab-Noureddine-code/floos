import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/data/repositories/settings_repository.dart';
import 'package:floos/features/lock/lock_controller.dart';
import 'package:floos/features/lock/pin_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings › Security: PIN, biometrics, re-lock timeout, secure flag.
class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  Future<bool> _verifyCurrent(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final svc = ref.read(pinServiceProvider);
    String pin = '';
    String? err;
    final ok = await showAppSheet<bool>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: const EdgeInsets.all(AppSpace.x2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.pinCurrent, style: ctx.text.titleM),
              const SizedBox(height: AppSpace.lg),
              PinPad(
                length: 6,
                pin: pin,
                error: err,
                onChanged: (v) => set(() => pin = v),
                onSubmit: (v) async {
                  final r = await svc.verify(v);
                  if (r is PinOk) {
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } else {
                    set(() {
                      pin = '';
                      err = r is PinLockedOut ? l.pinLocked(r.seconds) : l.pinWrong;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = ref.watch(prefsProvider);
    final repo = ref.read(settingsRepoProvider);
    final svc = ref.read(pinServiceProvider);
    final timeouts = {0: l.timeoutImmediate, 30: l.timeout30, 60: l.timeout60, 300: l.timeout300};
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsSecurity)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: [
          SettingsGroup(
            children: [
              SwitchRow(
                label: l.securityLock,
                value: p.lockEnabled,
                onChanged: (v) async {
                  if (v) {
                    final pin = await createPinDialog(context);
                    if (pin != null) await svc.setPin(pin);
                  } else if (await _verifyCurrent(context, ref)) {
                    await svc.removePin();
                  }
                },
              ),
              if (p.lockEnabled) ...[
                SettingsRow(
                  label: l.securityChangePin,
                  onTap: () async {
                    if (!await _verifyCurrent(context, ref) || !context.mounted) return;
                    final pin = await createPinDialog(context);
                    if (pin != null) {
                      await svc.setPin(pin);
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.pinChanged)));
                    }
                  },
                ),
                FutureBuilder<bool>(
                  future: svc.biometricsAvailable(),
                  builder: (context, snap) => snap.data == true
                      ? SwitchRow(
                          label: l.securityBiometrics,
                          value: p.lockBiometrics,
                          onChanged: (v) async {
                            if (!v || await svc.authenticate(l.pinBiometricReason)) {
                              await repo.set(SettingKeys.lockBiometrics, v);
                            }
                          },
                        )
                      : const SizedBox.shrink(),
                ),
                SettingsRow(
                  label: l.securityTimeout,
                  value: timeouts[p.lockTimeoutSeconds],
                  onTap: () async {
                    final v = await showAppSheet<int>(
                      context,
                      builder: (ctx) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SheetTitle(l.securityTimeout),
                          for (final e in timeouts.entries)
                            ListTile(
                              title: Text(e.value),
                              trailing: e.key == p.lockTimeoutSeconds ? const Icon(Icons.check_rounded) : null,
                              onTap: () => Navigator.pop(ctx, e.key),
                            ),
                          const SizedBox(height: AppSpace.lg),
                        ],
                      ),
                    );
                    if (v != null) await repo.set(SettingKeys.lockTimeoutSeconds, v);
                  },
                ),
              ],
              SwitchRow(
                label: l.securitySecureFlag,
                value: p.secureFlag,
                onChanged: (v) => repo.set(SettingKeys.secureFlag, v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
