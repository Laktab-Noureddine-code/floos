import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/utils/formatters.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/core/widgets/toggles.dart';
import 'package:floos/domain/services/recurring_engine.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

/// Schedule + mode + reminder chosen in the recurring editor.
@immutable
class RecurringConfig {
  const RecurringConfig({
    this.frequency = Frequency.monthly,
    this.interval = 1,
    this.byWeekday,
    this.byMonthDay,
    this.end,
    this.maxOccurrences,
    this.mode = 'auto',
    this.remindDaysBefore,
    this.remindTimeMinutes = 540,
    this.name,
  });

  final Frequency frequency;
  final int interval;
  final int? byWeekday;
  final int? byMonthDay;
  final LocalDay? end;
  final int? maxOccurrences;
  final String mode;
  final int? remindDaysBefore;
  final int remindTimeMinutes;
  final String? name;

  RecurringConfig copyWith({
    Frequency? frequency,
    int? interval,
    int? Function()? byWeekday,
    int? Function()? byMonthDay,
    LocalDay? Function()? end,
    int? Function()? maxOccurrences,
    String? mode,
    int? Function()? remindDaysBefore,
    int? remindTimeMinutes,
    String? name,
  }) => RecurringConfig(
    frequency: frequency ?? this.frequency,
    interval: interval ?? this.interval,
    byWeekday: byWeekday != null ? byWeekday() : this.byWeekday,
    byMonthDay: byMonthDay != null ? byMonthDay() : this.byMonthDay,
    end: end != null ? end() : this.end,
    maxOccurrences: maxOccurrences != null ? maxOccurrences() : this.maxOccurrences,
    mode: mode ?? this.mode,
    remindDaysBefore: remindDaysBefore != null ? remindDaysBefore() : this.remindDaysBefore,
    remindTimeMinutes: remindTimeMinutes ?? this.remindTimeMinutes,
    name: name ?? this.name,
  );
}

/// "Chaque mois le 5" etc.
String describeFrequency(AppLocalizations l, Frequency f, int interval, LocalDay start, {int? weekday, int? monthDay}) {
  switch (f) {
    case Frequency.daily:
      return l.recEveryDay(interval);
    case Frequency.weekly:
      final wd = weekday ?? start.weekday;
      final d = start.addDays((wd - start.weekday + 7) % 7);
      return l.recEveryWeek(interval, Fmt.weekday(d));
    case Frequency.monthly:
      return l.recEveryMonth(interval, monthDay ?? start.day);
    case Frequency.yearly:
      return l.recEveryYear(interval, Fmt.shortDay(LocalDay(start.year, start.month, monthDay ?? start.day)));
  }
}

String frequencyLabel(AppLocalizations l, Frequency f) => switch (f) {
  Frequency.daily => l.freqDaily,
  Frequency.weekly => l.freqWeekly,
  Frequency.monthly => l.freqMonthly,
  Frequency.yearly => l.freqYearly,
};

/// Opens the inline recurring editor. Returns null when cancelled; returns
/// `(null)` record when the user chose "do not repeat".
Future<(RecurringConfig?,)?> editRecurring(BuildContext context, {required LocalDay start, RecurringConfig? initial}) =>
    showAppSheet<(RecurringConfig?,)>(
      context,
      expand: true,
      builder: (_) => RecurringEditor(start: start, initial: initial ?? const RecurringConfig()),
    );

class RecurringEditor extends StatefulWidget {
  const RecurringEditor({required this.start, required this.initial, super.key, this.showRemove = true});

  final LocalDay start;
  final RecurringConfig initial;
  final bool showRemove;

  @override
  State<RecurringEditor> createState() => _RecurringEditorState();
}

class _RecurringEditorState extends State<RecurringEditor> {
  late RecurringConfig c = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      children: [
        SheetTitle(l.recTitle),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            children: [
              RecurringFields(start: widget.start, value: c, onChanged: (v) => setState(() => c = v)),
              const SizedBox(height: AppSpace.x2),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.lg),
          child: Row(
            children: [
              if (widget.showRemove) ...[
                Expanded(
                  child: PrimaryButton(label: l.recRemove, secondary: true, onPressed: () => Navigator.pop(context, (null,))),
                ),
                const SizedBox(width: AppSpace.md),
              ],
              Expanded(child: PrimaryButton(label: l.apply, onPressed: () => Navigator.pop(context, (c,)))),
            ],
          ),
        ),
      ],
    );
  }
}

/// The schedule/mode/reminder fields (shared by the sheet and the full form).
class RecurringFields extends StatelessWidget {
  const RecurringFields({required this.start, required this.value, required this.onChanged, super.key});

  final LocalDay start;
  final RecurringConfig value;
  final ValueChanged<RecurringConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = value;
    final weekdays = [for (var i = 0; i < 7; i++) LocalDay(2024, 1, 1).addDays(i)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedToggle<Frequency>(
          options: Frequency.values,
          value: c.frequency,
          labelOf: (f) => frequencyLabel(l, f),
          onChanged: (f) => onChanged(c.copyWith(frequency: f)),
        ),
        const SizedBox(height: AppSpace.md),
        Text(
          describeFrequency(l, c.frequency, c.interval, start, weekday: c.byWeekday, monthDay: c.byMonthDay),
          style: context.text.bodyM,
        ),
        const SizedBox(height: AppSpace.md),
        _Stepper(
          label: l.recInterval,
          value: c.interval,
          min: 1,
          max: 99,
          onChanged: (v) => onChanged(c.copyWith(interval: v)),
        ),
        if (c.frequency == Frequency.weekly) ...[
          Text(l.recWeekday, style: context.text.caption),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.xs,
            children: [
              for (final d in weekdays)
                ChoicePill(
                  label: Fmt.weekday(d).substring(0, 3),
                  selected: (c.byWeekday ?? start.weekday) == d.weekday,
                  onTap: () => onChanged(c.copyWith(byWeekday: () => d.weekday)),
                ),
            ],
          ),
        ],
        if (c.frequency == Frequency.monthly || c.frequency == Frequency.yearly) ...[
          _Stepper(
            label: l.recMonthDay,
            value: c.byMonthDay ?? start.day,
            min: 1,
            max: 31,
            onChanged: (v) => onChanged(c.copyWith(byMonthDay: () => v)),
          ),
          Text(l.recMonthDayHint, style: context.text.caption),
        ],
        const SizedBox(height: AppSpace.lg),
        Text(l.recEnds, style: context.text.caption),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          spacing: AppSpace.sm,
          children: [
            ChoicePill(
              label: l.recEndsNever,
              selected: c.end == null && c.maxOccurrences == null,
              onTap: () => onChanged(c.copyWith(end: () => null, maxOccurrences: () => null)),
            ),
            ChoicePill(
              label: c.end == null ? l.recEndsOn : '${l.recEndsOn} ${Fmt.mediumDay(c.end!)}',
              selected: c.end != null,
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  firstDate: start.toDateTime(),
                  lastDate: DateTime(start.year + 50),
                  initialDate: (c.end ?? start.addMonths(12)).toDateTime(),
                );
                if (d != null) onChanged(c.copyWith(end: () => LocalDay.fromDateTime(d), maxOccurrences: () => null));
              },
            ),
            ChoicePill(
              label: c.maxOccurrences == null ? l.recEndsAfter : '${l.recEndsAfter} ${l.recOccurrences(c.maxOccurrences!)}',
              selected: c.maxOccurrences != null,
              onTap: () => onChanged(c.copyWith(maxOccurrences: () => c.maxOccurrences ?? 12, end: () => null)),
            ),
          ],
        ),
        if (c.maxOccurrences != null)
          _Stepper(
            label: l.recEndsAfter,
            value: c.maxOccurrences!,
            min: 1,
            max: 999,
            onChanged: (v) => onChanged(c.copyWith(maxOccurrences: () => v)),
          ),
        const SizedBox(height: AppSpace.lg),
        Text(l.recMode, style: context.text.caption),
        const SizedBox(height: AppSpace.sm),
        SegmentedToggle<String>(
          options: const ['auto', 'confirm'],
          value: c.mode,
          labelOf: (m) => m == 'auto' ? l.recModeAuto : l.recModeConfirm,
          onChanged: (m) => onChanged(c.copyWith(mode: m)),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(c.mode == 'auto' ? l.recModeAutoHint : l.recModeConfirmHint, style: context.text.caption),
        const SizedBox(height: AppSpace.lg),
        Text(l.recReminder, style: context.text.caption),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          spacing: AppSpace.xs,
          children: [
            ChoicePill(
              label: l.recReminderOff,
              selected: c.remindDaysBefore == null,
              onTap: () => onChanged(c.copyWith(remindDaysBefore: () => null)),
            ),
            for (final n in const [0, 1, 2, 3, 7])
              ChoicePill(
                label: l.recReminderDays(n),
                selected: c.remindDaysBefore == n,
                onTap: () => onChanged(c.copyWith(remindDaysBefore: () => n)),
              ),
          ],
        ),
        if (c.remindDaysBefore != null)
          SettingsRow(
            label: l.recReminderTime,
            value: Fmt.time(c.remindTimeMinutes),
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: c.remindTimeMinutes ~/ 60, minute: c.remindTimeMinutes % 60),
              );
              if (t != null) onChanged(c.copyWith(remindTimeMinutes: t.hour * 60 + t.minute));
            },
          ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.value, required this.min, required this.max, required this.onChanged});

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label, style: context.text.bodyS.copyWith(color: context.colors.textPrimary))),
      IconButton(
        tooltip: '−',
        onPressed: value > min ? () => onChanged(value - 1) : null,
        icon: const Icon(Icons.remove_circle_outline_rounded),
      ),
      SizedBox(width: AppSpace.x3, child: Text('$value', textAlign: TextAlign.center, style: context.text.bodyM)),
      IconButton(
        tooltip: '+',
        onPressed: value < max ? () => onChanged(value + 1) : null,
        icon: const Icon(Icons.add_circle_outline_rounded),
      ),
    ],
  );
}
