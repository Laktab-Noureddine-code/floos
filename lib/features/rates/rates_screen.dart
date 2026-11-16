import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/utils/formatters.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/features/common/form_fields.dart';
import 'package:floos/features/common/pickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _ratesProvider = StreamProvider<List<RateRow>>((ref) => ref.watch(ratesRepoProvider).watchAll());

String formatRate(int rateE6) {
  var s = (rateE6 / 1000000).toStringAsFixed(6);
  s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return s.replaceAll('.', ',');
}

/// Exchange rates: latest per pair, history, add / delete.
class RatesScreen extends ConsumerWidget {
  const RatesScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    var from = ref.read(prefsProvider).baseCurrency == 'USD' ? 'EUR' : 'USD';
    var to = ref.read(prefsProvider).baseCurrency;
    final value = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(l.rateAdd),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('${l.rateFrom} · $from'),
                onTap: () async {
                  final c = await pickCurrency(ctx, selected: from);
                  if (c != null) set(() => from = c);
                },
              ),
              ListTile(
                title: Text('${l.rateTo} · $to'),
                onTap: () async {
                  final c = await pickCurrency(ctx, selected: to);
                  if (c != null) set(() => to = c);
                },
              ),
              TextField(
                controller: value,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l.rateValue),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.save)),
          ],
        ),
      ),
    );
    final text = value.text.replaceAll(',', '.').trim();
    value.dispose();
    if (ok != true || !context.mounted) return;
    final d = double.tryParse(text);
    final e6 = d == null ? 0 : (d * 1000000).round();
    final r = await ref.read(ratesRepoProvider).add(from, to, e6, ref.read(todayProvider));
    if (context.mounted && r.isErr) showFailure(context, r.failureOrNull);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final rows = ref.watch(_ratesProvider).value ?? const <RateRow>[];
    return Scaffold(
      appBar: AppBar(title: Text(l.ratesTitle)),
      floatingActionButton: FloatingActionButton(tooltip: l.rateAdd, onPressed: () => _add(context, ref), child: const Icon(Icons.add_rounded)),
      body: rows.isEmpty
          ? Padding(padding: const EdgeInsets.all(AppSpace.x2), child: Center(child: Text(l.ratesEmpty, textAlign: TextAlign.center)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSizes.scrollBottomPadding),
              children: [
                for (final r in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.sm),
                    child: AppCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.rateLine(r.fromCode, formatRate(r.rateE6), r.toCode), style: context.text.bodyM),
                                Text(Fmt.mediumDay(LocalDay.fromStorage(r.date)), style: context.text.caption),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: l.delete,
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () => ref.read(ratesRepoProvider).delete(r.id),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
