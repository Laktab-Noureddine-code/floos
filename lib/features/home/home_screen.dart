import 'package:floos/app/providers.dart';
import 'package:floos/app/services_providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/utils/formatters.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/money_text.dart';
import 'package:floos/core/widgets/progress.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/core/widgets/states.dart';
import 'package:floos/core/widgets/toggles.dart';
import 'package:floos/core/widgets/transaction_tile.dart';
import 'package:floos/data/repositories/settings_repository.dart';
import 'package:floos/data/repositories/transactions_repository.dart';
import 'package:floos/features/common/budget_style.dart';
import 'package:floos/features/common/insight_text.dart';
import 'package:floos/features/common/period_sheet.dart';
import 'package:floos/features/home/home_providers.dart';
import 'package:floos/features/home/pending_card.dart';
import 'package:floos/features/transaction_form/transaction_form_sheet.dart';
import 'package:floos/features/transactions/tx_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Home tab (design.md §4.1, APP_PROMPT §6.3).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.onRefresh});

  /// Re-runs the recurring engine (pull-to-refresh).
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: RefreshIndicator(
      onRefresh: () async {
        await onRefresh?.call();
        ref
          ..invalidate(insightsProvider)
          ..invalidate(homeSummaryProvider);
      },
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _Header()),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -AppSizes.headerOverlap),
              child: Container(
                decoration: BoxDecoration(
                  color: context.colors.background,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                ),
                padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.x2, AppSpace.screen, 0),
                child: const _Content(),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: AppSizes.scrollBottomPadding)),
        ],
      ),
    ),
  );
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final prefs = ref.watch(prefsProvider);
    final summary = ref.watch(homeSummaryProvider);
    final period = ref.watch(homePeriodProvider);
    final base = ref.watch(baseCurrencyProvider);
    final unread = ref.watch(unreadNotificationsProvider).value ?? 0;
    final top = MediaQuery.paddingOf(context).top;
    final initials = _initials(prefs.displayName);
    return Container(
      height: AppSizes.homeHeaderHeight + top,
      decoration: BoxDecoration(gradient: c.headerGradient),
      foregroundDecoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.9, -0.9),
          radius: 1.2,
          colors: [c.onDark.withValues(alpha: AppOpacity.sheen), c.onDark.withValues(alpha: 0)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(AppSpace.screen, top + AppSpace.sm, AppSpace.screen, AppSizes.headerOverlap),
      child: Column(
        children: [
          Row(
            children: [
              Semantics(
                button: true,
                label: l.a11yProfile,
                child: GestureDetector(
                  onTap: () => context.push('/settings/general'),
                  child: Container(
                    width: AppSizes.avatar,
                    height: AppSizes.avatar,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.onDark.withValues(alpha: AppOpacity.onPurpleFill),
                      border: Border.all(color: c.onDark, width: AppSizes.avatarBorder),
                    ),
                    alignment: Alignment.center,
                    child: initials.isEmpty
                        ? Icon(PhosphorIconsFill.user, color: c.onDark)
                        : Text(initials, style: context.text.bodyM.copyWith(color: c.onDark)),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: PeriodPill(
                    label: Fmt.period(period),
                    onPurple: true,
                    onTap: () async {
                      final p = await pickPeriod(context, current: period, allowKinds: false);
                      if (p == null) return;
                      final cur = ref.read(periodCalculatorProvider).monthPeriodFor(ref.read(todayProvider));
                      var offset = 0;
                      var x = cur;
                      while (x.start > p.start && offset < 600) {
                        x = x.previous();
                        offset++;
                      }
                      while (x.start < p.start && offset > -24) {
                        x = x.next();
                        offset--;
                      }
                      ref.read(homePeriodOffsetProvider.notifier).set(offset);
                    },
                  ),
                ),
              ),
              CircleIconButton(
                icon: PhosphorIconsRegular.bell,
                tooltip: unread > 0 ? l.a11yUnread : l.a11yNotifications,
                onPurple: true,
                dot: unread > 0,
                onPressed: () => context.push('/notifications'),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l.homeCurrentBalance, style: context.text.bodyS.copyWith(color: c.onDark.withValues(alpha: AppOpacity.headerLabel))),
              const SizedBox(width: AppSpace.xs),
              Semantics(
                button: true,
                label: l.a11yToggleAmounts,
                child: InkResponse(
                  radius: AppSizes.minTouch / 2,
                  onTap: () {
                    Haptics.light();
                    ref.read(settingsRepoProvider).set(SettingKeys.hideAmounts, !prefs.hideAmounts);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.sm),
                    child: Icon(
                      prefs.hideAmounts ? PhosphorIconsRegular.eyeSlash : PhosphorIconsRegular.eye,
                      size: AppSizes.iconGlyphSmall,
                      color: c.onDark.withValues(alpha: AppOpacity.headerLabel),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          AnimatedSwitcher(
            duration: animationsEnabled(context) ? AppMotion.balance : Duration.zero,
            child: FittedBox(
              key: ValueKey(summary.value?.balance),
              child: MoneyText(
                summary.value?.balance ?? 0,
                base,
                style: context.text.displayL.copyWith(color: c.onDark),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          if (summary.value != null)
            Container(
              height: AppSizes.deltaPillHeight,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
              decoration: BoxDecoration(
                color: c.onDark.withValues(alpha: AppOpacity.onPurpleFill),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              alignment: Alignment.center,
              child: Text(
                l.homeDeltaVs(ref.money(summary.value!.delta, base, showPlus: true, decimals: false)),
                style: context.text.caption.copyWith(color: c.onDark),
              ),
            ),
          const Spacer(),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }
}

class _Content extends ConsumerWidget {
  const _Content();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final summary = ref.watch(homeSummaryProvider);
    final insights = ref.watch(insightsProvider).value ?? const [];
    final pending = ref.watch(pendingProvider).value ?? const [];
    final budgets = ref.watch(budgetSnapshotProvider).value ?? const [];
    final txs = ref.watch(homeTransactionsProvider);
    final any = ref.watch(hasAnyTransactionProvider).value ?? true;
    final mode = ref.watch(homeListModeProvider);
    final totals = summary.value?.totals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l.homeYourMoney,
          trailing: IconButton(
            tooltip: l.homeYourMoneyInfo,
            onPressed: () => Snack.show(context, '${l.homeYourMoneyInfo} ${l.homeInfoIncomeExpense}'),
            icon: Icon(PhosphorIconsRegular.info, size: AppSizes.iconGlyphSmall, color: context.colors.textSecondary),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: PillButton(label: l.details, trailing: Icons.chevron_right_rounded, onTap: () => context.push('/accounts')),
        ),
        const SizedBox(height: AppSpace.md),
        Row(
          children: [
            Expanded(
              child: _MoneyCard(
                label: l.homeIncome,
                icon: PhosphorIconsFill.coins,
                color: CategoryColor.blue,
                amount: totals?.income ?? 0,
                onTap: () => context.go('/report?type=income'),
              ),
            ),
            const SizedBox(width: AppSpace.cardGap),
            Expanded(
              child: _MoneyCard(
                label: l.homeExpenses,
                icon: PhosphorIconsFill.wallet,
                color: CategoryColor.pink,
                amount: totals?.expense ?? 0,
                onTap: () => context.go('/report?type=expense'),
              ),
            ),
          ],
        ),
        if (summary.value?.missingRates.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.sm),
            child: Text(
              l.homeMissingRates(summary.value!.missingRates.join(', ')),
              style: context.text.caption.copyWith(color: context.colors.danger),
            ),
          ),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: AppSpace.section),
          PendingCard(items: pending),
        ],
        if (insights.isNotEmpty) ...[
          const SizedBox(height: AppSpace.lg),
          InsightPill(
            text: insightText(context, ref, insights.first),
            onTap: () => context.push(insights.first.route == '/report' ? '/insights' : insights.first.route),
            onDismiss: () async {
              await ref
                  .read(settingsRepoProvider)
                  .dismissInsight(ref.read(homePeriodProvider).key, insights.first.id);
              if (context.mounted) Snack.show(context, l.insightDismissed);
            },
          ),
        ],
        if (budgets.isNotEmpty) ...[
          const SizedBox(height: AppSpace.section),
          SectionHeader(title: l.homeBudgets, actionLabel: l.viewAll, onAction: () => context.push('/budgets')),
          const SizedBox(height: AppSpace.sm),
          SizedBox(
            height: AppSizes.ring + AppSpace.x4 + AppSpace.md,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: budgets.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpace.md),
              itemBuilder: (context, i) {
                final b = budgets[i];
                return Semantics(
                  button: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    onTap: () => context.push('/budgets/${b.id}'),
                    child: SizedBox(
                      width: AppSizes.ring + AppSpace.x3,
                      child: Column(
                        children: [
                          RingProgress(percent: b.status.percent, color: budgetColor(context, b.status.level)),
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            b.row.name.isEmpty ? l.budgetOverall : b.row.name,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.caption,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: AppSpace.section),
        SectionHeader(
          title: l.homeTransactions,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: l.a11yPinned,
                isSelected: mode == TxOrder.pinnedThenDate,
                onPressed: () => ref.read(homeListModeProvider.notifier).toggle(TxOrder.pinnedThenDate),
                icon: Icon(
                  mode == TxOrder.pinnedThenDate ? PhosphorIconsFill.pushPin : PhosphorIconsRegular.pushPin,
                  size: AppSizes.iconGlyph,
                  color: mode == TxOrder.pinnedThenDate ? context.colors.primary : context.colors.textSecondary,
                ),
              ),
              IconButton(
                tooltip: l.a11yHistory,
                isSelected: mode == TxOrder.updatedDesc,
                onPressed: () => ref.read(homeListModeProvider.notifier).toggle(TxOrder.updatedDesc),
                icon: Icon(
                  PhosphorIconsRegular.clockCounterClockwise,
                  size: AppSizes.iconGlyph,
                  color: mode == TxOrder.updatedDesc ? context.colors.primary : context.colors.textSecondary,
                ),
              ),
              PillButton(
                label: l.homeForPeriod,
                tinted: true,
                onTap: () {
                  final p = ref.read(homePeriodProvider);
                  context.push('/transactions?start=${p.startMs}&end=${p.endExclusiveMs}');
                },
              ),
            ],
          ),
        ),
        AsyncValueView(
          value: txs,
          onRetry: () => ref.invalidate(homeTransactionsProvider),
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                illustration: Illustration.wallet,
                message: any ? l.homeEmptyPeriod : l.homeEmptyTitle,
                actionLabel: l.homeEmptyAction,
                onAction: () => openTransactionForm(context),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GroupedTxList(items: items),
                Center(
                  child: PillButton(
                    label: l.seeAll,
                    trailing: Icons.chevron_right_rounded,
                    onTap: () => context.push('/transactions'),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MoneyCard extends ConsumerWidget {
  const _MoneyCard({required this.label, required this.icon, required this.color, required this.amount, required this.onTap});

  final String label;
  final IconData icon;
  final CategoryColor color;
  final int amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppCard(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.moneyCardHeight - AppSpace.lg * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: icon, color: color),
          const SizedBox(height: AppSpace.md),
          Text(label, style: context.text.bodyS),
          const SizedBox(height: AppSpace.xxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: MoneyText(amount, ref.watch(baseCurrencyProvider), style: context.text.amountM),
          ),
        ],
      ),
    ),
  );
}
