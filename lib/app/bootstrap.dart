import 'dart:async';
import 'dart:io';

import 'package:floos/app/app.dart';
import 'package:floos/app/providers.dart';
import 'package:floos/app/services/home_widget_sync.dart';
import 'package:floos/app/services/notification_gateway.dart';
import 'package:floos/app/services_providers.dart';
import 'package:floos/app/startup.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/utils/logger.dart';
import 'package:floos/data/db/db_connection.dart';
import 'package:floos/features/lock/lock_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opens the database, wires platform services and starts the app.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(appLocaleName);
  const store = DeviceSecretStore();
  final db = await openAppDatabase(store);
  final docs = await getApplicationDocumentsDirectory();
  final ui = await SharedPreferences.getInstance();
  final info = await PackageInfo.fromPlatform();
  final prefs = await ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)])
      .read(settingsRepoProvider)
      .load();

  AppLogger.sink = (kind, message, stack) => db.errorLogDao.add(kind, message, stack, DateTime.now().millisecondsSinceEpoch);
  FlutterError.onError = (d) {
    FlutterError.presentError(d);
    AppLogger.error('flutter', d.exception, d.stack);
  };
  PlatformDispatcher.instance.onError = (e, st) {
    AppLogger.error('platform', e, st);
    return true;
  };

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      appDirsProvider.overrideWithValue(AppDirs(documents: docs)),
      uiPrefsProvider.overrideWithValue(ui),
      initialPrefsProvider.overrideWithValue(prefs),
      initialLockedProvider.overrideWithValue(prefs.lockEnabled),
      appVersionProvider.overrideWithValue('${info.version}+${info.buildNumber}'),
      notificationGatewayProvider.overrideWithValue(LocalNotificationGateway()),
      homeWidgetSyncProvider.overrideWithValue(PlatformHomeWidgetSync()),
      imageCompressorProvider.overrideWithValue(_compress),
    ],
  );
  container.read(appEffectsProvider);
  if (prefs.hideAmountsDefault && !prefs.hideAmounts) {
    unawaited(container.read(settingsRepoProvider).set('hide_amounts', true));
  }

  runApp(UncontrolledProviderScope(container: container, child: const FloosApp()));
  if (prefs.onboardingDone) unawaited(runStartupTasks(container, full: true));
}

Future<Uint8List?> _compress(String path) async {
  if (!Platform.isAndroid && !Platform.isIOS) return File(path).readAsBytes();
  final out = await FlutterImageCompress.compressWithFile(path, minWidth: 1600, minHeight: 1600, quality: 80);
  return out ?? await File(path).readAsBytes();
}
