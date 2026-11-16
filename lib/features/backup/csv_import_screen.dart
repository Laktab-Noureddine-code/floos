import 'package:file_picker/file_picker.dart';
import 'package:floos/app/providers.dart';
import 'package:floos/app/services/csv_importer.dart';
import 'package:floos/app/services_providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/utils/result.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/domain/services/csv_service.dart';
import 'package:floos/features/common/form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// CSV import wizard: file → columns → review → import (APP_PROMPT §7.3).
class CsvImportScreen extends ConsumerStatefulWidget {
  const CsvImportScreen({super.key});

  @override
  ConsumerState<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends ConsumerState<CsvImportScreen> {
  int _step = 0;
  List<List<String>> _table = const [];
  Map<CsvField, int> _mapping = {};
  String _dateFormat = csvDateFormats.first;
  bool _decimalComma = false;
  bool _hasHeader = true;
  ImportPlan? _plan;
  bool _importDuplicates = false;
  ImportReport? _report;
  bool _busy = false;

  String _fieldLabel(AppLocalizations l, CsvField f) => switch (f) {
    CsvField.date => l.csvFieldDate,
    CsvField.time => l.csvFieldTime,
    CsvField.type => l.csvFieldType,
    CsvField.amount => l.csvFieldAmount,
    CsvField.currency => l.csvFieldCurrency,
    CsvField.account => l.csvFieldAccount,
    CsvField.toAccount => l.csvFieldToAccount,
    CsvField.toAmount => l.csvFieldToAmount,
    CsvField.category => l.csvFieldCategory,
    CsvField.parentCategory => l.csvFieldParentCategory,
    CsvField.payee => l.csvFieldPayee,
    CsvField.note => l.csvFieldNote,
    CsvField.tags => l.csvFieldTags,
    CsvField.id => l.csvFieldId,
  };

  Future<void> _pick() async {
    final f = await FilePicker.pickFile();
    if (f == null || !mounted) return;
    final det = CsvService.detect(await f.readAsBytes());
    if (det.isErr) return showFailure(context, det.failureOrNull);
    final d = det.valueOrNull!;
    final table = CsvService.parse(d.text, d.delimiter);
    if (table.isEmpty) return showFailure(context, const AppFailure.importFormat('csv_empty'));
    final mapping = CsvService.autoMap(table.first);
    final dateCol = mapping[CsvField.date];
    setState(() {
      _table = table;
      _mapping = mapping;
      if (dateCol != null) _dateFormat = CsvService.detectDateFormat(table.skip(1).map((r) => dateCol < r.length ? r[dateCol] : ''));
      _step = 1;
    });
  }

  CsvImportOptions get _options => CsvImportOptions(
    mapping: _mapping,
    dateFormat: _dateFormat,
    decimalComma: _decimalComma,
    amountMode: _mapping.containsKey(CsvField.type) ? AmountMode.typeColumn : AmountMode.signed,
    hasHeader: _hasHeader,
  );

  Future<void> _review() async {
    if (!_mapping.containsKey(CsvField.date) || !_mapping.containsKey(CsvField.amount)) {
      return showFailure(context, const AppFailure.importFormat('csv_mapping'));
    }
    setState(() => _busy = true);
    final (rows, errors) = CsvService.parseRows(_table, _options);
    final plan = await ref.read(csvImporterProvider).plan(rows, errors, ref.read(prefsProvider).baseCurrency);
    if (!mounted) return;
    setState(() {
      _plan = plan;
      _step = 2;
      _busy = false;
    });
    if (rows.isEmpty) showFailure(context, AppFailure.importFormat(errors.isEmpty ? 'csv_empty' : 'csv_mapping'));
  }

  Future<void> _run() async {
    final plan = _plan!;
    final accounts = ref.read(accountsStreamProvider).value ?? const [];
    setState(() => _busy = true);
    final r = await ref
        .read(csvImporterProvider)
        .run(
          plan,
          accountRes: {for (final n in plan.unknownAccounts.keys) n: const CreateNew()},
          categoryRes: {for (final n in plan.unknownCategories.keys) n: const CreateNew()},
          baseCurrency: ref.read(prefsProvider).baseCurrency,
          fallbackAccountId: accounts.isEmpty ? null : accounts.first.id,
          importDuplicates: _importDuplicates,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.isErr) return showFailure(context, r.failureOrNull);
    setState(() {
      _report = r.valueOrNull;
      _step = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final header = _table.isEmpty ? <String>[] : _table.first;
    final body = switch (_step) {
      0 => [PrimaryButton(label: l.csvPickFile, onPressed: _pick)],
      1 => [
        for (final f in CsvField.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: DropdownButtonFormField<int?>(
              initialValue: _mapping[f],
              decoration: InputDecoration(labelText: _fieldLabel(l, f)),
              items: [
                DropdownMenuItem<int?>(child: Text(l.csvNotMapped)),
                for (var i = 0; i < header.length; i++) DropdownMenuItem<int?>(value: i, child: Text(header[i].isEmpty ? '#${i + 1}' : header[i])),
              ],
              onChanged: (v) => setState(() => v == null ? _mapping.remove(f) : _mapping[f] = v),
            ),
          ),
        DropdownButtonFormField<String>(
          initialValue: _dateFormat,
          decoration: InputDecoration(labelText: l.csvDateFormat),
          items: [for (final f in csvDateFormats) DropdownMenuItem(value: f, child: Text(f))],
          onChanged: (v) => setState(() => _dateFormat = v ?? _dateFormat),
        ),
        SwitchRow(label: l.csvDecimalComma, value: _decimalComma, onChanged: (v) => setState(() => _decimalComma = v)),
        const SizedBox(height: AppSpace.md),
        PrimaryButton(label: l.next, busy: _busy, onPressed: _review),
      ],
      2 => [
        if (_plan != null) ...[
          AppCard(child: Text(l.csvRows(_plan!.rows.length, _plan!.errors.length, _plan!.duplicates.length), style: context.text.bodyM)),
          if (_plan!.unknownAccounts.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            Text(l.csvUnknownAccounts, style: context.text.titleM),
            for (final n in _plan!.unknownAccounts.keys) Text('• $n', style: context.text.bodyS),
          ],
          if (_plan!.unknownCategories.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            Text(l.csvUnknownCategories, style: context.text.titleM),
            for (final n in _plan!.unknownCategories.keys) Text('• $n', style: context.text.bodyS),
          ],
          SwitchRow(label: l.csvImportDuplicates, value: _importDuplicates, onChanged: (v) => setState(() => _importDuplicates = v)),
          const SizedBox(height: AppSpace.md),
          PrimaryButton(label: l.csvDoImport, busy: _busy, onPressed: _plan!.rows.isEmpty ? null : _run),
        ],
      ],
      _ => [
        if (_report != null) AppCard(child: Text(l.csvReport(_report!.imported, _report!.skipped, _report!.errors.length), style: context.text.bodyM)),
        const SizedBox(height: AppSpace.md),
        PrimaryButton(label: l.done, onPressed: () => Navigator.of(context).maybePop()),
      ],
    };
    return Scaffold(
      appBar: AppBar(title: Text(l.dataImportCsv)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen, vertical: AppSpace.sm),
            child: Row(
              children: [
                for (final (i, s) in [l.csvStepFile, l.csvStepMapping, l.csvStepReview, l.csvStepImport].indexed)
                  Expanded(
                    child: Text(
                      s,
                      textAlign: TextAlign.center,
                      style: context.text.caption.copyWith(color: i == _step ? context.colors.primary : context.colors.textTertiary, fontWeight: i == _step ? FontWeight.w700 : FontWeight.w400),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: ListView(padding: const EdgeInsets.all(AppSpace.screen), children: body)),
        ],
      ),
    );
  }
}
