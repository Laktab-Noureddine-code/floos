import 'dart:async';

import 'package:floos/app/providers.dart';
import 'package:floos/core/utils/logger.dart';
import 'package:floos/data/db/db_connection.dart';
import 'package:floos/data/repositories/settings_repository.dart';
import 'package:floos/domain/services/pin_hasher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Result of a PIN attempt.
sealed class PinResult {
  const PinResult();
}

class PinOk extends PinResult {
  const PinOk();
}

class PinWrong extends PinResult {
  const PinWrong(this.failures);
  final int failures;
}

class PinLockedOut extends PinResult {
  const PinLockedOut(this.seconds);
  final int seconds;
}

/// Hashes off the UI isolate (100k PBKDF2 rounds).
Future<String> hashPin(String pin) => compute(PinHasher.hash, pin);
Future<bool> verifyPinOffThread(String pin, String stored) => compute(_verify, (pin, stored));
bool _verify((String, String) a) => PinHasher.verify(a.$1, a.$2);

/// Whether the app is currently locked.
class LockState extends Notifier<bool> {
  @override
  bool build() => ref.watch(initialLockedProvider);

  void lock() {
    if (ref.read(prefsProvider).lockEnabled) state = true;
  }

  void unlock() => state = false;
}

final initialLockedProvider = Provider<bool>((ref) => false);
final lockedProvider = NotifierProvider<LockState, bool>(LockState.new);

/// PIN storage, lockout and biometrics.
class PinService {
  PinService(this._store, this._settings);

  final SecretStore _store;
  final SettingsRepository _settings;
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> hasPin() async => (await _store.read(SecretKeys.pinHash)) != null;

  Future<void> setPin(String pin) async {
    await _store.write(SecretKeys.pinHash, await hashPin(pin));
    await _store.delete(SecretKeys.pinFailures);
    await _store.delete(SecretKeys.pinLockedUntil);
    await _settings.set(SettingKeys.lockEnabled, true);
  }

  Future<void> removePin() async {
    await _store.delete(SecretKeys.pinHash);
    await _settings.setAll({SettingKeys.lockEnabled: false, SettingKeys.lockBiometrics: false});
  }

  Future<int> remainingLockSeconds() async {
    final until = int.tryParse(await _store.read(SecretKeys.pinLockedUntil) ?? '');
    if (until == null) return 0;
    final left = until - DateTime.now().millisecondsSinceEpoch;
    return left <= 0 ? 0 : (left / 1000).ceil();
  }

  Future<PinResult> verify(String pin) async {
    final locked = await remainingLockSeconds();
    if (locked > 0) return PinLockedOut(locked);
    final stored = await _store.read(SecretKeys.pinHash);
    if (stored == null) return const PinOk();
    if (await verifyPinOffThread(pin, stored)) {
      await _store.delete(SecretKeys.pinFailures);
      await _store.delete(SecretKeys.pinLockedUntil);
      return const PinOk();
    }
    final failures = (int.tryParse(await _store.read(SecretKeys.pinFailures) ?? '') ?? 0) + 1;
    await _store.write(SecretKeys.pinFailures, '$failures');
    final delay = PinHasher.delayFor(failures);
    if (delay > Duration.zero) {
      await _store.write(
        SecretKeys.pinLockedUntil,
        '${DateTime.now().add(delay).millisecondsSinceEpoch}',
      );
      return PinLockedOut(delay.inSeconds);
    }
    return PinWrong(failures);
  }

  Future<bool> biometricsAvailable() async {
    try {
      return await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } on Object {
      return false;
    }
  }

  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason, biometricOnly: true);
    } on PlatformException catch (e) {
      AppLogger.error('biometrics', e);
      return false;
    }
  }
}

final pinServiceProvider = Provider(
  (ref) => PinService(ref.watch(secretStoreProvider), ref.watch(settingsRepoProvider)),
);
