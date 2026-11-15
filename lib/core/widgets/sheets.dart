import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows a modal bottom sheet with the design's drag handle and radius.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool expand = false,
  bool scrollControlled = true,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: scrollControlled,
  useSafeArea: true,
  sheetAnimationStyle: const AnimationStyle(duration: AppMotion.sheet),
  constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
  builder: (ctx) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
    child: expand
        ? SizedBox(height: MediaQuery.sizeOf(ctx).height * 0.9, child: SheetFrame(child: builder(ctx)))
        : SheetFrame(child: builder(ctx)),
  ),
);

/// Drag handle + content.
class SheetFrame extends StatelessWidget {
  const SheetFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SizedBox(height: AppSpace.sm),
      Container(
        width: AppSizes.dragHandleWidth,
        height: AppSizes.dragHandleHeight,
        decoration: BoxDecoration(
          color: context.colors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ),
      const SizedBox(height: AppSpace.sm),
      Flexible(child: child),
    ],
  );
}

/// Sheet title row.
class SheetTitle extends StatelessWidget {
  const SheetTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.sm, AppSpace.md),
    child: Row(
      children: [
        Expanded(child: Text(title, style: context.text.titleM)),
        ?trailing,
      ],
    ),
  );
}

/// Confirmation dialog. Returns true when confirmed.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  bool danger = false,
}) async {
  final l = context.l10n;
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: danger ? ctx.colors.expense : ctx.colors.primary),
          child: Text(confirmLabel ?? l.confirm),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Dialog asking the user to type [expected] to confirm (e.g. "DELETE").
Future<bool> typeToConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String expected,
  required String confirmLabel,
}) async {
  final controller = TextEditingController();
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: AppSpace.md),
            TextField(
              controller: controller,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: expected),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l10n.cancel)),
          TextButton(
            onPressed: controller.text.trim() == expected ? () => Navigator.pop(ctx, true) : null,
            style: TextButton.styleFrom(foregroundColor: ctx.colors.expense),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  return r ?? false;
}

/// Light haptic on save, delete and toggle (UX law 6.6).
abstract final class Haptics {
  static Future<void> light() => HapticFeedback.lightImpact();
}

/// Snack helpers: plain message, or with Undo (5 s, UX law 6.2).
abstract final class Snack {
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Shows "message · Undo". [onClosed] receives true if Undo was tapped.
  static void undo(BuildContext context, String message, {required void Function(bool undone) onClosed}) {
    var undone = false;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger
        .showSnackBar(
          SnackBar(
            content: Text(message),
            duration: AppMotion.undo,
            action: SnackBarAction(label: context.l10n.undo, onPressed: () => undone = true),
          ),
        )
        .closed
        .then((_) => onClosed(undone));
  }
}

/// iOS-style grouped settings list in an [AppCard] (design.md §4.5).
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({required this.children, super.key, this.title});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (title != null)
        Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpace.xs, bottom: AppSpace.sm),
          child: Semantics(header: true, child: Text(title!, style: context.text.caption)),
        ),
      AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(indent: AppSpace.lg, endIndent: AppSpace.lg),
              children[i],
            ],
          ],
        ),
      ),
    ],
  );
}

/// One 52 pt settings row with optional trailing value/chevron/switch.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.label,
    super.key,
    this.icon,
    this.value,
    this.onTap,
    this.trailing,
    this.danger = false,
    this.subtitle,
    this.chevron = true,
  });

  final String label;
  final IconData? icon;
  final String? value;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.rowHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.sm),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppSizes.iconGlyph, color: danger ? c.expense : c.textSecondary),
                const SizedBox(width: AppSpace.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: context.text.bodyM.copyWith(
                        fontWeight: FontWeight.w500,
                        color: danger ? c.expense : c.textPrimary,
                      ),
                    ),
                    if (subtitle != null) Text(subtitle!, style: context.text.caption),
                  ],
                ),
              ),
              if (value != null)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: AppSpace.sm),
                    child: Text(
                      value!,
                      style: context.text.bodyS,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
              ?trailing,
              if (trailing == null && chevron && onTap != null)
                Icon(Icons.chevron_right_rounded, color: c.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Switch row with haptic feedback.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
    this.icon,
    this.subtitle,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: SettingsRow(
      label: label,
      icon: icon,
      subtitle: subtitle,
      onTap: onChanged == null ? null : () => _toggle(!value),
      trailing: Switch(value: value, onChanged: onChanged == null ? null : _toggle),
    ),
  );

  void _toggle(bool v) {
    Haptics.light();
    onChanged?.call(v);
  }
}
