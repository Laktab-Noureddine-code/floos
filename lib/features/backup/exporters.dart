import 'dart:io';
import 'dart:typed_data';

import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/data/repositories/transactions_repository.dart';
import 'package:floos/domain/services/csv_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

/// Asks for the CSV separator (comma or semicolon).
Future<String?> pickCsvSeparator(BuildContext context) {
  final l = context.l10n;
  return showAppSheet<String>(
    context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetTitle(l.csvSeparator),
          ListTile(title: Text(l.csvComma), onTap: () => Navigator.pop(ctx, ',')),
          ListTile(title: Text(l.csvSemicolon), onTap: () => Navigator.pop(ctx, ';')),
        ],
      ),
    ),
  );
}

/// Converts views to CSV rows.
List<CsvExportRow> toCsvRows(List<TxView> views) => [
  for (final v in views)
    CsvExportRow(
      day: LocalDay.fromStorage(v.tx.date),
      timeMinutes: v.tx.timeOfDayMinutes,
      type: v.tx.type,
      amount: v.tx.amount,
      currency: Currencies.of(v.accountCurrency),
      account: v.accountName,
      toAccount: v.toAccountName,
      toAmount: v.tx.toAmount,
      toCurrency: v.toAccountCurrency == null ? null : Currencies.of(v.toAccountCurrency!),
      category: v.parentCategoryName == null ? v.categoryName : v.categoryName,
      parentCategory: v.parentCategoryName,
      payee: v.tx.payee,
      note: v.tx.note,
      tags: v.tagNames,
      id: v.tx.id,
    ),
];

/// Writes [bytes] to a temp file and opens the share sheet.
Future<void> shareBytes(BuildContext context, Uint8List bytes, String fileName, String mime) async {
  final dir = await Directory.systemTemp.createTemp('floos_share');
  final file = File(p.join(dir.path, fileName));
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: mime)], fileNameOverrides: [fileName]));
}

/// Exports transactions matching [filter] (or explicit [views]) to CSV.
Future<void> exportTransactionsCsv(BuildContext context, WidgetRef ref, {TxFilter? filter, List<TxView>? views}) async {
  final sep = await pickCsvSeparator(context);
  if (sep == null || !context.mounted) return;
  final rows = views ?? await ref.read(transactionsRepoProvider).get(filter ?? const TxFilter());
  final bytes = CsvService.export(toCsvRows(rows), separator: sep);
  final now = DateTime.now();
  final name = 'floos_transactions_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.csv';
  if (!context.mounted) return;
  await shareBytes(context, bytes, name, 'text/csv');
}
