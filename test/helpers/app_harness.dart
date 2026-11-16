import 'dart:io';

import 'package:floos/app/app.dart';
import 'package:floos/app/providers.dart';
import 'package:floos/core/time/clock.dart';
import 'package:floos/data/db/db_connection.dart';
import 'package:floos/data/repositories/settings_repository.dart';
import 'package:floos/features/lock/lock_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_db.dart';

/// Boots the real [FloosApp] on an in-memory database.
class AppHarness {
  AppHarness._(this.env, this.container, this.secrets, this.dir);

  final TestEnv env;
  final ProviderContainer container;
  final MemorySecretStore secrets;
  final Directory dir;

  static Future<AppHarness> create(
    WidgetTester tester, {
    bool onboarded = true,
    bool seed = true,
    bool lock = false,
  }) async {
    await initializeDateFormatting('fr');
    SharedPreferences.setMockInitialValues({});
    final env = TestEnv(now: DateTime(2026, 1, 15, 12));
    final secrets = MemorySecretStore();
    late AppHarness h;
    await tester.runAsync(() async {
      if (seed) await env.seed(locale: 'fr');
      if (onboarded) await env.settings.set(SettingKeys.onboardingDone, true);
      if (lock) await env.settings.set(SettingKeys.lockEnabled, true);
    });
    final prefs = await tester.runAsync(env.settings.load) ?? AppPrefs.defaults;
    final dir = Directory.systemTemp.createTempSync('floos_test');
    final ui = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(env.db),
        appDirsProvider.overrideWithValue(AppDirs(documents: dir)),
        uiPrefsProvider.overrideWithValue(ui),
        initialPrefsProvider.overrideWithValue(prefs),
        initialLockedProvider.overrideWithValue(prefs.lockEnabled),
        secretStoreProvider.overrideWithValue(secrets),
        clockProvider.overrideWithValue(env.clock),
      ],
    );
    h = AppHarness._(env, container, secrets, dir);
    return h;
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const FloosApp()));
    await settle(tester);
  }

  /// Pumps real time so drift streams/futures resolve without pumpAndSettle
  /// (streams keep timers alive).
  Future<void> settle(WidgetTester tester, {int frames = 10}) async {
    for (var i = 0; i < frames; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.runAsync(env.dispose);
    dir.deleteSync(recursive: true);
  }
}
