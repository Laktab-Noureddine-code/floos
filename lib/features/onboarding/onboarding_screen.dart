import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/amount_input_parser.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/nav.dart';
import 'package:floos/core/widgets/states.dart';
import 'package:floos/data/db/seed.dart';
import 'package:floos/data/repositories/accounts_repository.dart';
import 'package:floos/data/repositories/settings_repository.dart';
import 'package:floos/features/common/pickers.dart';
import 'package:floos/features/lock/lock_controller.dart';
import 'package:floos/features/lock/pin_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 4-step first-run flow (APP_PROMPT §6.1): welcome, currency + month start,
/// first account, security.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _steps = 4;
  int _step = 0;
  String _currency = 'MAD';
  int _monthStart = 1;
  final _name = TextEditingController();
  final _balance = TextEditingController(text: '0');
  String? _pin;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final l = context.l10n;
    setState(() => _busy = true);
    final cur = Currencies.of(_currency);
    final bal = AmountInputParser.parse(_balance.text.isEmpty ? '0' : _balance.text, cur, allowNegative: true);
    if (bal.isErr) {
      setState(() {
        _step = 2;
        _busy = false;
        _error = failureMessage(l, bal.failureOrNull);
      });
      return;
    }
    final db = ref.read(databaseProvider);
    final now = ref.read(clockProvider).now().millisecondsSinceEpoch;
    await seedCategories(db, appLocaleName, now);
    final name = _name.text.trim().isEmpty ? l.obAccountDefault : _name.text.trim();
    final res = await ref
        .read(accountsRepoProvider)
        .save(
          AccountDraft(
            name: name,
            type: 'cash',
            currencyCode: _currency,
            initialBalance: bal.valueOrNull ?? 0,
            color: 'purple',
            icon: 'wallet',
          ),
        );
    if (res.isErr) {
      setState(() {
        _busy = false;
        _error = failureMessage(l, res.failureOrNull);
        _step = 2;
      });
      return;
    }
    if (_pin != null) await ref.read(pinServiceProvider).setPin(_pin!);
    await ref.read(settingsRepoProvider).setAll({
      SettingKeys.baseCurrency: _currency,
      SettingKeys.monthStartDay: _monthStart,
      SettingKeys.onboardingDone: true,
    });
    // Router redirect reacts to the setting change.
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final last = _step == _steps - 1;
    final pages = [_welcome(l), _currencyPage(l), _accountPage(l), _securityPage(l)];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.screen),
          child: Column(
            children: [
              Row(
                children: [
                  if (_step > 0)
                    IconButton(tooltip: l.back, icon: const Icon(Icons.arrow_back_rounded), onPressed: () => setState(() => _step--))
                  else
                    const SizedBox(width: 48),
                  Expanded(child: Center(child: Text(l.obStep(_step + 1, _steps), style: context.text.caption))),
                  const SizedBox(width: 48),
                ],
              ),
              Expanded(child: SingleChildScrollView(child: pages[_step])),
              if (_error != null) Text(_error!, style: context.text.caption.copyWith(color: context.colors.expense)),
              const SizedBox(height: AppSpace.md),
              PrimaryButton(
                label: _step == 0 ? l.obStart : (last ? l.obFinish : l.next),
                busy: _busy,
                onPressed: () {
                  if (last) {
                    _finish();
                  } else {
                    setState(() {
                      _step++;
                      _error = null;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _welcome(AppLocalizations l) => Column(
    children: [
      const SizedBox(height: AppSpace.x3),
      const AppLogo(size: 96),
      const SizedBox(height: AppSpace.x2),
      const IllustrationView(Illustration.onboardingPrivacy),
      Text(l.obWelcomeTitle, style: context.text.displayM, textAlign: TextAlign.center),
      const SizedBox(height: AppSpace.md),
      Text(l.obWelcomeBody, style: context.text.bodyM, textAlign: TextAlign.center),
    ],
  );

  Widget _currencyPage(AppLocalizations l) => Column(
    children: [
      const IllustrationView(Illustration.onboardingCurrency),
      Text(l.obCurrencyTitle, style: context.text.displayM, textAlign: TextAlign.center),
      const SizedBox(height: AppSpace.sm),
      Text(l.obCurrencyBody, style: context.text.bodyM, textAlign: TextAlign.center),
      const SizedBox(height: AppSpace.lg),
      AppCard(
        onTap: () async {
          final c = await pickCurrency(context, selected: _currency);
          if (c != null) setState(() => _currency = c);
        },
        child: Row(
          children: [
            Expanded(child: Text('$_currency · ${Currencies.of(_currency).name}', style: context.text.bodyM)),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
      const SizedBox(height: AppSpace.md),
      Row(
        children: [
          Expanded(child: Text(l.obMonthStart, style: context.text.bodyM)),
          DropdownButton<int>(
            value: _monthStart,
            items: [for (var d = 1; d <= 28; d++) DropdownMenuItem(value: d, child: Text('$d'))],
            onChanged: (v) => setState(() => _monthStart = v ?? 1),
          ),
        ],
      ),
    ],
  );

  Widget _accountPage(AppLocalizations l) => Column(
    children: [
      const IllustrationView(Illustration.onboardingAccount),
      Text(l.obAccountTitle, style: context.text.displayM, textAlign: TextAlign.center),
      const SizedBox(height: AppSpace.sm),
      Text(l.obAccountBody, style: context.text.bodyM, textAlign: TextAlign.center),
      const SizedBox(height: AppSpace.lg),
      TextField(controller: _name, decoration: InputDecoration(labelText: l.obAccountName, hintText: l.obAccountDefault)),
      const SizedBox(height: AppSpace.md),
      TextField(
        controller: _balance,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        decoration: InputDecoration(labelText: l.obInitialBalance, suffixText: _currency),
      ),
    ],
  );

  Widget _securityPage(AppLocalizations l) => Column(
    children: [
      const IllustrationView(Illustration.lock),
      Text(l.obSecurityTitle, style: context.text.displayM, textAlign: TextAlign.center),
      const SizedBox(height: AppSpace.sm),
      Text(l.obSecurityBody, style: context.text.bodyM, textAlign: TextAlign.center),
      const SizedBox(height: AppSpace.lg),
      PrimaryButton(
        label: _pin == null ? l.obSetPin : l.pinChanged,
        secondary: true,
        onPressed: () async {
          final p = await createPinDialog(context);
          if (p != null) setState(() => _pin = p);
        },
      ),
      if (_pin != null)
        TextButton(onPressed: () => setState(() => _pin = null), child: Text(l.obSkipPin)),
    ],
  );
}
