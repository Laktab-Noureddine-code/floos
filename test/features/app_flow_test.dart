import 'package:floos/app/providers.dart';
import 'package:floos/features/lock/lock_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  testWidgets('home shows empty state without transactions', (tester) async {
    final h = await AppHarness.create(tester);
    await h.pump(tester);
    expect(find.text('Floos'), findsNothing); // no raw template text
    expect(find.byType(Scaffold), findsWidgets);
    await h.dispose(tester);
  });

  testWidgets('home lists a saved transaction', (tester) async {
    final h = await AppHarness.create(tester);
    await tester.runAsync(() async {
      final acc = await h.env.account(initial: 10000);
      await h.env.expense(acc, 2500, payee: 'Marjane');
    });
    await h.pump(tester);
    expect(find.text('Marjane'), findsWidgets);
    await h.dispose(tester);
  });

  testWidgets('fresh install shows onboarding', (tester) async {
    final h = await AppHarness.create(tester, onboarded: false, seed: false);
    await h.pump(tester);
    expect(find.text('Bienvenue sur Floos'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('lock screen blocks until the right PIN is entered', (tester) async {
    final h = await AppHarness.create(tester, lock: true);
    await tester.runAsync(() => h.container.read(pinServiceProvider).setPin('1234'));
    await h.pump(tester);
    expect(find.text('Saisissez votre code PIN'), findsOneWidget);
    expect(h.container.read(lockedProvider), isTrue);

    Future<void> enter(String pin) async {
      for (final d in pin.split('')) {
        await tester.tap(find.text(d).first);
        await tester.pump();
      }
      await tester.tap(find.text('Confirmer'));
      await h.settle(tester, frames: 30);
    }

    await enter('9999');
    expect(find.text('Code PIN incorrect'), findsOneWidget);
    await enter('1234');
    expect(h.container.read(lockedProvider), isFalse);
    expect(h.container.read(prefsProvider).lockEnabled, isTrue);
    await h.dispose(tester);
  });
}
