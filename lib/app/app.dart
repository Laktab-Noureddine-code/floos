import 'dart:async';

import 'package:floos/app/providers.dart';
import 'package:floos/app/services_providers.dart';
import 'package:floos/app/startup.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/router/app_router.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/widgets/nav.dart';
import 'package:floos/features/lock/lock_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root widget: themes, router, lock gate, privacy cover and lifecycle.
class FloosApp extends ConsumerStatefulWidget {
  const FloosApp({super.key});

  @override
  ConsumerState<FloosApp> createState() => _FloosAppState();
}

class _FloosAppState extends ConsumerState<FloosApp>
    with WidgetsBindingObserver {
  static const _secureChannel = MethodChannel('com.floos.app/secure');
  DateTime? _pausedAt;
  bool _covered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(appEffectsProvider);
    unawaited(_attachNotifications());
  }

  Future<void> _attachNotifications() async {
    final gw = ref.read(notificationGatewayProvider);
    await gw.init((route) {
      if (route != null) ref.read(routerProvider).go(route);
    });
    final launch = await gw.launchRoute();
    if (launch != null) ref.read(routerProvider).go(launch);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  ProviderContainer get _container => ProviderScope.containerOf(context);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final prefs = ref.read(prefsProvider);
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        setState(() => _covered = true);
      case AppLifecycleState.paused:
        _pausedAt ??= DateTime.now();
        setState(() => _covered = true);
      case AppLifecycleState.resumed:
        final at = _pausedAt;
        _pausedAt = null;
        if (prefs.lockEnabled &&
            at != null &&
            DateTime.now().difference(at).inSeconds >=
                prefs.lockTimeoutSeconds) {
          ref.read(lockedProvider.notifier).lock();
        }
        setState(() => _covered = false);
        unawaited(runStartupTasks(_container));
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final prefs = ref.watch(prefsProvider);
    ref.listen(
      prefsProvider.select((p) => p.secureFlag),
      (_, v) => _setSecure(secure: v),
    );
    return MaterialApp.router(
      title: 'Floos',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (prefs.themeMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      locale: appLocale,
      supportedLocales: const [appLocale],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Stack(
        fit: StackFit.expand,
        children: [
          MediaQuery.withClampedTextScaling(
            minScaleFactor: 0.8,
            maxScaleFactor: 1.6,
            child: child ?? const SizedBox.shrink(),
          ),
          if (_covered && (prefs.lockEnabled || prefs.secureFlag))
            ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: const Center(child: AppLogo(size: 96)),
            ),
        ],
      ),
    );
  }

  Future<void> _setSecure({required bool secure}) async {
    try {
      await _secureChannel.invokeMethod<void>('setSecure', secure);
    } on MissingPluginException {
      // Not available on this platform.
    }
  }
}
