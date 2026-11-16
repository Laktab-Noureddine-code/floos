import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/time/period.dart';
import 'package:floos/core/utils/formatters.dart';
import 'package:floos/data/repositories/transactions_repository.dart';
import 'package:floos/features/backup/exporters.dart';
import 'package:floos/features/report/report_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// CSV of every transaction in [period].
Future<void> exportReportCsv(BuildContext context, WidgetRef ref, Period period) =>
    exportTransactionsCsv(context, ref, filter: TxFilter(startMs: period.startMs, endExclusiveMs: period.endExclusiveMs));

/// One-page PDF: totals, category breakdown and stats for the period.
Future<void> exportReportPdf(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final d = await ref.read(reportDataProvider.future);
  final base = ref.read(baseCurrencyProvider);
  final fmt = ref.read(formatterProvider);
  final cats = ref.read(categoriesMapProvider);
  String money(int v) => fmt.format(v, base);
  final type = ref.read(reportTypeProvider);
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (_) => [
        pw.Text('${l.appName} · ${l.reportTitle}', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.Text(Fmt.period(d.period)),
        pw.SizedBox(height: 16),
        pw.Text('${l.incomes}: ${money(d.current.income)}'),
        pw.Text('${l.expenses}: ${money(d.current.expense)}'),
        pw.Text('${l.reportCashFlowNet}: ${money(d.current.net)}'),
        pw.SizedBox(height: 16),
        pw.Text(type == 'expense' ? l.expenses : l.incomes, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.TableHelper.fromTextArray(
          data: [
            [l.category, l.amount],
            for (final i in d.items) [cats[i.key]?.name ?? l.reportUncategorized, money(i.total)],
          ],
        ),
      ],
    ),
  );
  final bytes = await doc.save();
  if (!context.mounted) return;
  await shareBytes(context, bytes, 'floos_report_${d.period.start.toIso()}.pdf', 'application/pdf');
}
