import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/utils/result.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Original flat illustrations (assets/illustrations, brand purple).
enum Illustration {
  wallet,
  budgets,
  goals,
  debts,
  recurring,
  search,
  success,
  lock,
  onboardingPrivacy,
  onboardingCurrency,
  onboardingAccount,
  chart,
  notifications;

  String get asset => 'assets/illustrations/${switch (this) {
    Illustration.wallet => 'empty_wallet',
    Illustration.budgets => 'empty_budgets',
    Illustration.goals => 'empty_goals',
    Illustration.debts => 'empty_debts',
    Illustration.recurring => 'empty_recurring',
    Illustration.search => 'empty_search',
    Illustration.success => 'success',
    Illustration.lock => 'lock',
    Illustration.onboardingPrivacy => 'onboarding_privacy',
    Illustration.onboardingCurrency => 'onboarding_currency',
    Illustration.onboardingAccount => 'onboarding_account',
    Illustration.chart => 'empty_chart',
    Illustration.notifications => 'empty_notifications',
  }}.svg';
}

class IllustrationView extends StatelessWidget {
  const IllustrationView(this.illustration, {super.key, this.size = AppSizes.illustration});

  final Illustration illustration;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SvgPicture.asset(illustration.asset, width: size, height: size),
  );
}

/// Empty state: illustration, one sentence, one primary action (UX law 6.3).
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.illustration,
    required this.message,
    super.key,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final Illustration illustration;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.x2, vertical: AppSpace.x2),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IllustrationView(illustration, size: compact ? AppSizes.illustration * 0.6 : AppSizes.illustration),
        const SizedBox(height: AppSpace.lg),
        Text(message, style: context.text.bodyS, textAlign: TextAlign.center),
        if (actionLabel != null) ...[
          const SizedBox(height: AppSpace.lg),
          PrimaryButton(label: actionLabel!, onPressed: onAction),
        ],
      ],
    ),
  );
}

/// Error with a recovery action (UX law 6.4).
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, this.failure, this.onRetry});

  final AppFailure? failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpace.x2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, color: context.colors.danger, size: AppSizes.iconTile),
          const SizedBox(height: AppSpace.md),
          Text(
            failure == null ? context.l10n.errorWithRetry : failureMessage(context.l10n, failure),
            style: context.text.bodyS,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpace.lg),
            PillButton(label: context.l10n.retry, onTap: onRetry, tinted: true),
          ],
        ],
      ),
    ),
  );
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      label: context.l10n.loading,
      child: const Padding(
        padding: EdgeInsets.all(AppSpace.x2),
        child: CircularProgressIndicator(),
      ),
    ),
  );
}

/// Renders a Riverpod [AsyncValue] with loading and error (retry) states.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({required this.value, required this.data, super.key, this.onRetry});

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => switch (value) {
    AsyncData(:final value) => data(value),
    AsyncError() when !value.hasValue => ErrorView(onRetry: onRetry),
    _ when value.hasValue => data(value.requireValue),
    _ => const LoadingView(),
  };
}
