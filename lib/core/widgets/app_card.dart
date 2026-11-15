import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/widgets/icon_registry.dart';
import 'package:flutter/material.dart';

/// White card, `rLg`, padding 16, `shadowCard` (design.md §3.1).
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.onTap,
    this.onLongPress,
    this.floating = false,
    this.bordered = false,
    this.color,
    this.borderColor,
    this.radius = AppRadius.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool floating;
  final bool bordered;
  final Color? color;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: r,
        boxShadow: floating ? context.shadows.floating : context.shadows.card,
        border: bordered || borderColor != null
            ? Border.all(color: borderColor ?? c.border, width: borderColor != null ? AppSizes.selectedBorder : 1)
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: r,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// 40×40 tile: tint background + strong glyph (design.md §3.2).
class IconTile extends StatelessWidget {
  const IconTile({
    required this.icon,
    required this.color,
    super.key,
    this.small = false,
    this.size,
  });

  /// Builds from stored keys.
  factory IconTile.keyed(String? iconKey, String? colorName, {bool small = false, Key? key}) => IconTile(
    key: key,
    icon: IconRegistry.of(iconKey),
    color: CategoryColor.byName(colorName),
    small: small,
  );

  final IconData icon;
  final CategoryColor color;
  final bool small;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final s = size ?? (small ? AppSizes.iconTileSmall : AppSizes.iconTile);
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: context.colors.tintOf(color),
        borderRadius: BorderRadius.circular(small ? AppRadius.sm : AppRadius.md),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: small ? AppSizes.iconGlyphSmall : AppSizes.iconGlyph,
        color: color == CategoryColor.grey ? context.colors.textSecondary : color.strong,
      ),
    );
  }
}

/// Section title + optional trailing action (design.md §3.10).
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Semantics(
          header: true,
          child: Text(title, style: context.text.titleM, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
      ?trailing,
      if (actionLabel != null)
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            minimumSize: const Size(AppSizes.minTouch, AppSizes.minTouch),
            foregroundColor: context.colors.textSecondary,
          ),
          child: Text(actionLabel!, style: context.text.caption),
        ),
    ],
  );
}

/// 40×40 round icon button (design.md §3.4), optional red dot.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    required this.icon,
    required this.tooltip,
    super.key,
    this.onPressed,
    this.onPurple = false,
    this.dot = false,
    this.filled = false,
    this.outlined = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool onPurple;
  final bool dot;

  /// Black (`inverse`) filled variant used for the Plan "+" button.
  final bool filled;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bg = filled
        ? c.inverse
        : onPurple
            ? c.onDark.withValues(alpha: AppOpacity.onPurpleFill)
            : c.surface;
    final fg = filled ? c.onInverse : (onPurple ? c.onDark : c.textPrimary);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: SizedBox(
          width: AppSizes.minTouch,
          height: AppSizes.minTouch,
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Material(
                  color: bg,
                  shape: CircleBorder(side: outlined ? BorderSide(color: c.border) : BorderSide.none),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onPressed,
                    child: SizedBox(
                      width: AppSizes.circleButton,
                      height: AppSizes.circleButton,
                      child: Icon(icon, size: AppSizes.iconGlyph, color: fg),
                    ),
                  ),
                ),
                if (dot)
                  PositionedDirectional(
                    top: 2,
                    end: 2,
                    child: Container(
                      width: AppSizes.dot + AppSizes.dotBorder * 2,
                      height: AppSizes.dot + AppSizes.dotBorder * 2,
                      decoration: BoxDecoration(
                        color: c.expense,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.onDark, width: AppSizes.dotBorder),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width pill button, height 52, `primary` gradient (design.md §4.4).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.danger = false,
    this.secondary = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool danger;
  final bool secondary;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null && !busy;
    final gradient = !enabled || secondary
        ? null
        : danger
            ? LinearGradient(colors: [c.expense, c.expense])
            : c.fabGradient;
    final bg = !enabled ? c.surfaceMuted : (secondary ? c.primaryTint : null);
    final fg = !enabled ? c.textTertiary : (secondary ? c.primary : c.onDark);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Container(
        height: AppSizes.buttonHeight,
        decoration: BoxDecoration(
          gradient: gradient,
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: enabled ? onPressed : null,
            child: Center(
              child: busy
                  ? SizedBox.square(
                      dimension: AppSizes.iconGlyph,
                      child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: fg, size: AppSizes.iconGlyph),
                          const SizedBox(width: AppSpace.sm),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            style: context.text.bodyM.copyWith(color: fg),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small pill button ("Details ›", height 28, `surfaceMuted`).
class PillButton extends StatelessWidget {
  const PillButton({required this.label, super.key, this.onTap, this.trailing, this.tinted = false, this.leading});

  final String label;
  final VoidCallback? onTap;
  final IconData? trailing;
  final IconData? leading;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = tinted ? c.primary : c.textPrimary;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
        child: Center(
          child: Material(
            color: tinted ? c.primaryTint : c.surfaceMuted,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onTap,
              child: Container(
                constraints: const BoxConstraints(minHeight: AppSizes.detailsPillHeight),
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (leading != null) ...[
                      Icon(leading, size: AppSizes.iconGlyphSmall, color: fg),
                      const SizedBox(width: AppSpace.xs),
                    ],
                    Text(label, style: context.text.caption.copyWith(color: fg, fontWeight: FontWeight.w600)),
                    if (trailing != null) ...[
                      const SizedBox(width: AppSpace.xxs),
                      Icon(trailing, size: AppSizes.iconGlyphSmall, color: fg),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
