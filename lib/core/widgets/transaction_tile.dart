import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/utils/formatters.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/icon_registry.dart';
import 'package:floos/core/widgets/money_text.dart';
import 'package:floos/data/db/daos/transactions_dao.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Transaction row (design.md §3.12): icon, title, account · category,
/// signed amount and running balance. Swipe left → Delete / Edit.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.view,
    required this.today,
    super.key,
    this.runningBalance,
    this.onTap,
    this.onLongPress,
    this.onDelete,
    this.onEdit,
    this.selected = false,
    this.selectionMode = false,
  });

  final TxView view;
  final LocalDay today;
  final int? runningBalance;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool selected;
  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final tx = view.tx;
    final currency = Currencies.of(view.accountCurrency);
    final isTransfer = tx.type == 'transfer';
    final title = (tx.payee?.isNotEmpty ?? false)
        ? tx.payee!
        : isTransfer
            ? l.typeTransfer
            : (view.categoryName ?? l.category);
    final subtitle = isTransfer
        ? '${view.accountName} → ${view.toAccountName ?? ''}'
        : '${view.accountName} · ${view.parentCategoryName != null ? '${view.parentCategoryName} › ' : ''}${view.categoryName ?? ''}';
    final scheduled = LocalDay.fromStorage(tx.date) > today;
    final tile = AppCard(
      onTap: onTap,
      onLongPress: onLongPress,
      borderColor: selected ? c.primary : null,
      child: Row(
        children: [
          if (selectionMode)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpace.sm),
              child: Icon(
                selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: selected ? c.primary : c.textTertiary,
              ),
            ),
          if (isTransfer)
            const IconTile(icon: PhosphorIconsFill.arrowsLeftRight, color: CategoryColor.slate)
          else
            IconTile.keyed(view.categoryIcon, view.categoryColor),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (tx.pinned)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: AppSpace.xs),
                        child: Icon(PhosphorIconsFill.pushPin, size: AppSizes.iconGlyphSmall - 4, color: c.primary),
                      ),
                    Flexible(
                      child: Text(title, style: context.text.bodyM, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xxs),
                Row(
                  children: [
                    IconTile.keyed(view.accountIcon, view.accountColor, small: true, key: const ValueKey('acc')),
                    const SizedBox(width: AppSpace.xs),
                    Flexible(
                      child: Text(subtitle, style: context.text.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                if (scheduled || tx.isPending || view.attachmentCount > 0 || view.tagNames.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.xs),
                    child: Wrap(
                      spacing: AppSpace.xs,
                      runSpacing: AppSpace.xs,
                      children: [
                        if (scheduled) _Badge(l.badgeScheduled, c.primary, c.primaryTint),
                        if (tx.isPending) _Badge(l.badgePending, c.warning, c.warningTint),
                        if (view.attachmentCount > 0)
                          Icon(PhosphorIconsFill.paperclip, size: AppSizes.iconGlyphSmall - 2, color: c.textTertiary),
                        for (final t in view.tagNames.take(2)) _Badge('#$t', c.textSecondary, c.surfaceMuted),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TxAmountText(type: tx.type, amount: tx.amount, currency: currency),
              if (runningBalance != null) ...[
                const SizedBox(height: AppSpace.xxs),
                MoneyText(runningBalance!, currency, style: context.text.caption, dimDecimals: false),
              ],
            ],
          ),
        ],
      ),
    );
    if (onDelete == null && onEdit == null || selectionMode) return tile;
    return Semantics(
      hint: l.a11ySwipeHint,
      customSemanticsActions: {
        CustomSemanticsAction(label: l.edit): ?onEdit,
        CustomSemanticsAction(label: l.delete): ?onDelete,
      },
      child: Dismissible(
        key: ValueKey('dismiss-${tx.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          final action = await _SwipeActions.show(context, onEdit: onEdit, onDelete: onDelete);
          action?.call();
          return false;
        },
        background: const SizedBox.shrink(),
        secondaryBackground: _SwipeBackground(),
        child: tile,
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      alignment: AlignmentDirectional.centerEnd,
      padding: const EdgeInsetsDirectional.only(end: AppSpace.lg),
      decoration: BoxDecoration(color: c.dangerTint, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsFill.pencilSimple, color: c.primary),
          const SizedBox(width: AppSpace.lg),
          Icon(PhosphorIconsFill.trash, color: c.danger),
        ],
      ),
    );
  }
}

/// Swipe reveals Delete (danger) and Edit (primary) actions.
abstract final class _SwipeActions {
  static Future<VoidCallback?> show(BuildContext context, {VoidCallback? onEdit, VoidCallback? onDelete}) =>
      showModalBottomSheet<VoidCallback>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Row(
              children: [
                if (onEdit != null)
                  Expanded(
                    child: PrimaryButton(
                      label: ctx.l10n.edit,
                      icon: PhosphorIconsFill.pencilSimple,
                      secondary: true,
                      onPressed: () => Navigator.pop(ctx, onEdit),
                    ),
                  ),
                if (onEdit != null && onDelete != null) const SizedBox(width: AppSpace.md),
                if (onDelete != null)
                  Expanded(
                    child: PrimaryButton(
                      label: ctx.l10n.delete,
                      icon: PhosphorIconsFill.trash,
                      danger: true,
                      onPressed: () => Navigator.pop(ctx, onDelete),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.fg, this.bg);

  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm - 2, vertical: 1),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.full)),
    child: Text(label, style: context.text.caption.copyWith(color: fg, fontSize: 11)),
  );
}

/// Day header: "Lundi 12 janvier 2026 … Total −295,76" (design.md §3.13).
class DateGroupHeader extends StatelessWidget {
  const DateGroupHeader({required this.day, required this.total, required this.currency, super.key});

  final LocalDay day;

  /// Net of income − expense for the day (base currency).
  final int total;
  final Currency currency;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpace.lg, bottom: AppSpace.sm),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(Fmt.longDay(day), style: context.text.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
        Text(context.l10n.total, style: context.text.caption),
        const SizedBox(width: AppSpace.xs),
        MoneyText(total, currency, style: context.text.bodyS.copyWith(fontWeight: FontWeight.w700, color: context.colors.textPrimary), dimDecimals: false),
      ],
    ),
  );
}

/// Dark insight banner (design.md §3.11).
class InsightPill extends StatelessWidget {
  const InsightPill({required this.text, required this.onTap, super.key, this.onDismiss});

  final String text;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final trailing = c.onInverse.withValues(alpha: AppOpacity.insightTrailing);
    return Semantics(
      button: true,
      label: text,
      child: Material(
        color: c.inverse,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          onLongPress: onDismiss,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.insightPillHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.sm),
              child: Row(
                children: [
                  Icon(PhosphorIconsFill.sparkle, color: c.onInverse, size: 18),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      text,
                      style: context.text.bodyS.copyWith(color: c.onInverse, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Text(context.l10n.insightSee, style: context.text.caption.copyWith(color: trailing)),
                  Icon(Icons.chevron_right_rounded, color: trailing, size: AppSizes.iconGlyph),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small helper to resolve icon data for category rows.
IconData categoryIcon(String? key) => IconRegistry.of(key);
