import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/money_formatter.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Pill segmented control with sliding thumb (design.md §3.5).
class SegmentedToggle<T> extends StatelessWidget {
  const SegmentedToggle({
    required this.options,
    required this.value,
    required this.onChanged,
    required this.labelOf,
    super.key,
  });

  final List<T> options;
  final T value;
  final ValueChanged<T> onChanged;
  final String Function(T) labelOf;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final index = options.indexOf(value).clamp(0, options.length - 1);
    return Container(
      constraints: const BoxConstraints(minHeight: AppSizes.segmentedHeight),
      padding: const EdgeInsets.all(AppSpace.xs),
      decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(AppRadius.full)),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth / options.length;
          return Stack(
            children: [
              AnimatedPositionedDirectional(
                duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.segment,
                curve: AppMotion.segmentCurve,
                start: w * index,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    boxShadow: context.shadows.floating,
                  ),
                ),
              ),
              Row(
                children: [
                  for (final o in options)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: o == value,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          onTap: () {
                            if (o != value) {
                              Haptics.light();
                              onChanged(o);
                            }
                          },
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: AppSizes.segmentedHeight - AppSpace.sm),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
                                child: Text(
                                  labelOf(o),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.text.bodyS.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: o == value ? c.textPrimary : c.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Bar | donut toggle (design.md §3.6).
class ChartTypeToggle extends StatelessWidget {
  const ChartTypeToggle({required this.donut, required this.onChanged, super.key});

  final bool donut;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget btn(bool isDonut, IconData icon, String label) {
      final active = donut == isDonut;
      return Semantics(
        button: true,
        selected: active,
        label: label,
        child: InkResponse(
          onTap: () => onChanged(isDonut),
          radius: AppSizes.minTouch / 2,
          child: Container(
            width: AppSizes.chartToggleButton,
            height: AppSizes.chartToggleButton,
            decoration: BoxDecoration(color: active ? c.primary : null, shape: BoxShape.circle),
            child: Icon(icon, size: AppSizes.iconGlyphSmall, color: active ? c.onDark : c.textSecondary),
          ),
        ),
      );
    }

    return Container(
      height: AppSizes.chartToggleHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxs),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: context.shadows.floating,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(false, PhosphorIconsFill.chartBar, context.l10n.a11yBarChart),
          btn(true, PhosphorIconsFill.chartDonut, context.l10n.a11yDonutChart),
        ],
      ),
    );
  }
}

/// `+12%` / `−6%` chip (design.md §3.7). For expenses an increase is bad.
class TrendChip extends StatelessWidget {
  const TrendChip({required this.percent, super.key, this.increaseIsBad = true, this.label});

  final int percent;
  final bool increaseIsBad;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bad = percent > 0 ? increaseIsBad : (percent < 0 && !increaseIsBad);
    final fg = percent == 0 ? c.textSecondary : (bad ? c.danger : c.income);
    final bg = percent == 0 ? c.surfaceMuted : (bad ? c.dangerTint : c.successTint);
    final text = const MoneyFormatter(locale: appLocaleName).percent(percent, signed: true);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: AppSizes.trendChipHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm - 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.full)),
          child: Text(text, style: context.text.caption.copyWith(color: fg, fontWeight: FontWeight.w600)),
        ),
        if (label != null) ...[
          const SizedBox(width: AppSpace.xs),
          Flexible(child: Text(label!, style: context.text.caption, overflow: TextOverflow.ellipsis)),
        ],
      ],
    );
  }
}

/// Month/period picker pill (design.md §3.3).
class PeriodPill extends StatelessWidget {
  const PeriodPill({required this.label, required this.onTap, super.key, this.onPurple = false});

  final String label;
  final VoidCallback onTap;
  final bool onPurple;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = onPurple ? c.onDark : c.textPrimary;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
        child: Center(
          child: Material(
            color: onPurple ? c.onDark.withValues(alpha: AppOpacity.onPurpleFill) : c.surface,
            shape: const StadiumBorder(),
            child: Container(
              decoration: onPurple
                  ? null
                  : BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.full), boxShadow: context.shadows.floating),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onTap,
                child: Container(
                  height: AppSizes.monthPickerHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.caption.copyWith(color: fg, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Icon(Icons.keyboard_arrow_down_rounded, size: AppSizes.iconGlyphSmall, color: fg),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selectable chip used in filters and threshold pickers.
class ChoicePill extends StatelessWidget {
  const ChoicePill({required this.label, required this.selected, required this.onTap, super.key, this.onRemove});

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
        child: Center(
          child: Material(
            color: selected ? c.primaryTint : c.surfaceMuted,
            shape: StadiumBorder(side: selected ? BorderSide(color: c.primary) : BorderSide.none),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm - 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: context.text.caption.copyWith(
                        color: selected ? c.primary : c.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (onRemove != null) ...[
                      const SizedBox(width: AppSpace.xs),
                      InkResponse(
                        onTap: onRemove,
                        child: Icon(Icons.close_rounded, size: AppSizes.iconGlyphSmall, color: c.primary),
                      ),
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
