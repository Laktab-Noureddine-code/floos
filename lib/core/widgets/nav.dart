import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/widgets/progress.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// 56×56 gradient "+" with 4 pt white ring and purple glow (design.md §2).
class GradientFab extends StatefulWidget {
  const GradientFab({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  State<GradientFab> createState() => _GradientFabState();
}

class _GradientFabState extends State<GradientFab> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: context.l10n.fabAddTransaction,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: _down ? AppMotion.fabPressScale : 1,
          duration: animationsEnabled(context) ? AppMotion.fabPress : Duration.zero,
          child: Container(
            width: AppSizes.fab + AppSizes.fabBorder * 2,
            height: AppSizes.fab + AppSizes.fabBorder * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.surface,
              boxShadow: context.shadows.fab,
            ),
            padding: const EdgeInsets.all(AppSizes.fabBorder),
            child: DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: c.fabGradient),
              child: Icon(PhosphorIconsBold.plus, color: c.onDark, size: AppSizes.fabGlyph),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom navigation: Home · Report · [FAB] · Plan · Settings (design.md §2).
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({required this.index, required this.onTap, required this.onFab, super.key});

  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onFab;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final items = [
      (PhosphorIconsFill.house, PhosphorIconsRegular.house, l.navHome),
      (PhosphorIconsFill.chartBar, PhosphorIconsRegular.chartBar, l.navReport),
      (PhosphorIconsFill.cardholder, PhosphorIconsRegular.cardholder, l.navPlan),
      (PhosphorIconsFill.gear, PhosphorIconsRegular.gear, l.navSettings),
    ];
    final bottom = MediaQuery.paddingOf(context).bottom;
    Widget item(int i) {
      final active = i == index;
      final (on, off, label) = items[i];
      return Expanded(
        child: Semantics(
          button: true,
          selected: active,
          label: label,
          excludeSemantics: true,
          child: InkResponse(
            onTap: () => onTap(i),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(active ? on : off, size: AppSizes.navIcon, color: active ? c.textPrimary : c.textTertiary),
                const SizedBox(height: AppSpace.xs),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.caption.copyWith(
                    color: active ? c.textPrimary : c.textTertiary,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: AppSizes.navHeight + bottom + AppSizes.fabRaise + AppSizes.fabBorder,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: AppSizes.navHeight + bottom,
            padding: EdgeInsets.only(bottom: bottom),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
              boxShadow: context.shadows.nav,
            ),
            child: Row(
              children: [item(0), item(1), const SizedBox(width: AppSizes.fab + AppSpace.lg), item(2), item(3)],
            ),
          ),
          Positioned(
            top: 0,
            child: GradientFab(onPressed: onFab),
          ),
        ],
      ),
    );
  }
}

/// The brand logo (assets/branding/logo.png) as a rounded square.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: context.l10n.appName,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.asset('assets/branding/logo.png', width: size, height: size),
    ),
  );
}
