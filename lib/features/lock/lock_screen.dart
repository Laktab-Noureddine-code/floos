import 'dart:async';

import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/widgets/nav.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/features/lock/lock_controller.dart';
import 'package:floos/features/lock/pin_pad.dart';
import 'package:floos/features/settings/data_wipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full-screen PIN gate (APP_PROMPT §6.2).
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _pin = '';
  String? _error;
  int _lockLeft = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    final svc = ref.read(pinServiceProvider);
    await _refreshLock();
    if (ref.read(prefsProvider).lockBiometrics && _lockLeft == 0) await _biometric();
    if (!mounted) return;
    setState(() {});
    unawaited(svc.remainingLockSeconds());
  }

  Future<void> _refreshLock() async {
    _lockLeft = await ref.read(pinServiceProvider).remainingLockSeconds();
    _timer?.cancel();
    if (_lockLeft > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _lockLeft = (_lockLeft - 1).clamp(0, 1 << 30));
        if (_lockLeft == 0) _timer?.cancel();
      });
    }
  }

  Future<void> _biometric() async {
    final ok = await ref.read(pinServiceProvider).authenticate(context.l10n.pinBiometricReason);
    if (ok) ref.read(lockedProvider.notifier).unlock();
  }

  Future<void> _submit(String pin) async {
    final l = context.l10n;
    final r = await ref.read(pinServiceProvider).verify(pin);
    if (!mounted) return;
    switch (r) {
      case PinOk():
        ref.read(lockedProvider.notifier).unlock();
      case PinWrong():
        setState(() {
          _pin = '';
          _error = l.pinWrong;
        });
      case PinLockedOut():
        await _refreshLock();
        setState(() {
          _pin = '';
          _error = null;
        });
    }
  }

  Future<void> _forgot() async {
    final l = context.l10n;
    final svc = ref.read(pinServiceProvider);
    final bio = await svc.biometricsAvailable();
    if (!mounted) return;
    final choice = await showAppSheet<String>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetTitle(l.pinForgotTitle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            child: Text(l.pinForgotBody, style: context.text.bodyM),
          ),
          if (bio) ListTile(leading: const Icon(Icons.fingerprint), title: Text(l.pinUseBiometrics), onTap: () => Navigator.pop(ctx, 'bio')),
          ListTile(
            leading: Icon(Icons.delete_forever_rounded, color: ctx.colors.expense),
            title: Text(l.pinWipeAll, style: TextStyle(color: ctx.colors.expense)),
            onTap: () => Navigator.pop(ctx, 'wipe'),
          ),
          const SizedBox(height: AppSpace.lg),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'bio') {
      if (await svc.authenticate(l.pinBiometricReason)) {
        await svc.removePin();
        ref.read(lockedProvider.notifier).unlock();
      }
    } else if (choice == 'wipe') {
      if (!await confirmDialog(context, title: l.pinWipeAll, message: l.pinWipeConfirm1, danger: true)) return;
      if (!mounted) return;
      if (!await confirmDialog(context, title: l.pinWipeAll, message: l.pinWipeConfirm2, danger: true)) return;
      await wipeAllData(ref);
      ref.read(lockedProvider.notifier).unlock();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bio = ref.watch(prefsProvider).lockBiometrics;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.x2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(size: 72),
                const SizedBox(height: AppSpace.lg),
                Text(l.pinEnter, style: context.text.titleM),
                const SizedBox(height: AppSpace.lg),
                if (_lockLeft > 0)
                  Padding(
                    padding: const EdgeInsets.all(AppSpace.x2),
                    child: Text(l.pinLocked(_lockLeft), style: context.text.bodyM.copyWith(color: context.colors.expense)),
                  )
                else
                  PinPad(
                    length: 6,
                    pin: _pin,
                    error: _error,
                    onChanged: (v) => setState(() {
                      _pin = v;
                      _error = null;
                    }),
                    onSubmit: _submit,
                    extra: bio ? IconButton(icon: const Icon(Icons.fingerprint), tooltip: l.pinUseBiometrics, onPressed: _biometric) : null,
                  ),
                TextButton(onPressed: _forgot, child: Text(l.pinForgot)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
