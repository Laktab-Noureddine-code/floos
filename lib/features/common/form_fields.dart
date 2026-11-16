import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/utils/formatters.dart';
import 'package:floos/core/utils/result.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/features/common/pickers.dart';
import 'package:flutter/material.dart';

/// Icon tile (opens icon picker) + colour swatches, used by account,
/// category, goal and tag forms.
class IconColorField extends StatelessWidget {
  const IconColorField({
    required this.icon,
    required this.color,
    required this.onIcon,
    required this.onColor,
    super.key,
  });

  final String icon;
  final String color;
  final ValueChanged<String> onIcon;
  final ValueChanged<String> onColor;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () async {
                final k = await pickIcon(context, selected: icon, color: color);
                if (k != null) onIcon(k);
              },
              child: IconTile.keyed(icon, color),
            ),
            const SizedBox(width: AppSpace.md),
            Text(l.icon, style: context.text.bodyM),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        ColorSwatches(selected: color, onChanged: onColor),
      ],
    );
  }
}

/// Shows a failure as a snackbar.
void showFailure(BuildContext context, AppFailure? failure) {
  final l = context.l10n;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failureMessage(l, failure))));
}

/// Formats minor units as an editable decimal string ("12,50").
String editableAmount(int minor, int digits, int factor) =>
    (minor / factor).toStringAsFixed(digits).replaceAll('.', ',');

/// Date field: shows [day] and opens the date picker.
class DateField extends StatelessWidget {
  const DateField({required this.label, required this.day, required this.onChanged, super.key, this.onClear});

  final String label;
  final LocalDay? day;
  final ValueChanged<LocalDay> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: () async {
      final now = DateTime.now();
      final d = await showDatePicker(
        context: context,
        initialDate: day?.toDateTime() ?? now,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (d != null) onChanged(LocalDay(d.year, d.month, d.day));
    },
    child: Row(
      children: [
        Expanded(child: Text('$label · ${day == null ? context.l10n.none : Fmt.mediumDay(day!)}', style: context.text.bodyM)),
        if (onClear != null && day != null) IconButton(icon: const Icon(Icons.close_rounded), onPressed: onClear),
      ],
    ),
  );
}
