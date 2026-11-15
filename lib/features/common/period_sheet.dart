import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/time/period_calculator.dart';
import 'package:floos/core/utils/formatters.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/core/widgets/toggles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Period picker sheet: kind toggle (week/month/year/custom) + list of
/// recent periods; respects the custom month start day (design.md §3.3).
Future<Period?> pickPeriod(
  BuildContext context, {
  required Period current,
  bool allowKinds = true,
}) => showAppSheet<Period>(
  context,
  expand: true,
  builder: (_) => _PeriodSheet(current: current, allowKinds: allowKinds),
);

class _PeriodSheet extends ConsumerStatefulWidget {
  const _PeriodSheet({required this.current, required this.allowKinds});

  final Period current;
  final bool allowKinds;

  @override
  ConsumerState<_PeriodSheet> createState() => _PeriodSheetState();
}

class _PeriodSheetState extends ConsumerState<_PeriodSheet> {
  late PeriodKind kind = widget.current.kind;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final calc = ref.watch(periodCalculatorProvider);
    final today = ref.watch(todayProvider);
    final periods = <Period>[];
    if (kind != PeriodKind.custom) {
      var p = calc.periodFor(kind, today).next();
      final n = switch (kind) {
        PeriodKind.week => 26,
        PeriodKind.month => 25,
        _ => 8,
      };
      for (var i = 0; i < n; i++) {
        periods.add(p);
        p = p.previous();
      }
    }
    return Column(
      children: [
        SheetTitle(l.periodPickTitle),
        if (widget.allowKinds)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            child: SegmentedToggle<PeriodKind>(
              options: PeriodKind.values,
              value: kind,
              labelOf: (k) => switch (k) {
                PeriodKind.week => l.periodWeek,
                PeriodKind.month => l.periodMonth,
                PeriodKind.year => l.periodYear,
                PeriodKind.custom => l.periodCustom,
              },
              onChanged: (k) async {
                if (k == PeriodKind.custom) {
                  final r = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(today.year + 5),
                    initialDateRange: DateTimeRange(
                      start: widget.current.start.toDateTime(),
                      end: widget.current.end.toDateTime(),
                    ),
                  );
                  if (r != null && context.mounted) {
                    Navigator.pop(context, Period.custom(LocalDay.fromDateTime(r.start), LocalDay.fromDateTime(r.end)));
                  }
                  return;
                }
                setState(() => kind = k);
              },
            ),
          ),
        const SizedBox(height: AppSpace.sm),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.x2),
            children: [
              for (final p in periods)
                ListTile(
                  minTileHeight: AppSizes.rowHeight,
                  contentPadding: EdgeInsets.zero,
                  title: Text(Fmt.period(p), style: context.text.bodyM),
                  subtitle: p.kind == PeriodKind.month && p.start.day != 1
                      ? Text(Fmt.monthYear(p.end), style: context.text.caption)
                      : null,
                  trailing: p == widget.current ? Icon(Icons.check_rounded, color: context.colors.primary) : null,
                  onTap: () => Navigator.pop(context, p),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Period navigator: ‹ label › (Report).
class PeriodNavigator extends StatelessWidget {
  const PeriodNavigator({required this.period, required this.onChanged, required this.onPick, super.key});

  final Period period;
  final ValueChanged<Period> onChanged;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l.a11yPrevious,
          onPressed: () => onChanged(period.previous()),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Flexible(child: PeriodPill(label: Fmt.period(period), onTap: onPick)),
        IconButton(
          tooltip: l.a11yNext,
          onPressed: () => onChanged(period.next()),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}
