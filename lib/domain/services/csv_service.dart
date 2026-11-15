import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:floos/core/money/amount_input_parser.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/money/money_formatter.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/utils/formatters.dart';
import 'package:floos/core/utils/result.dart';

/// Export columns (contracts/csv-format.md), fixed order.
const csvColumns = [
  'date',
  'time',
  'type',
  'amount',
  'currency',
  'account',
  'to_account',
  'to_amount',
  'category',
  'parent_category',
  'payee',
  'note',
  'tags',
  'id',
];

/// One exported row (already resolved names).
class CsvExportRow {
  const CsvExportRow({
    required this.day,
    required this.type,
    required this.amount,
    required this.currency,
    required this.account,
    required this.id,
    this.timeMinutes,
    this.toAccount,
    this.toAmount,
    this.toCurrency,
    this.category,
    this.parentCategory,
    this.payee,
    this.note,
    this.tags = const [],
  });

  final LocalDay day;
  final int? timeMinutes;
  final String type;
  final int amount;
  final Currency currency;
  final String account;
  final String? toAccount;
  final int? toAmount;
  final Currency? toCurrency;
  final String? category;
  final String? parentCategory;
  final String? payee;
  final String? note;
  final List<String> tags;
  final String id;
}

/// Fields that can be mapped during import.
enum CsvField { date, time, type, amount, currency, account, toAccount, toAmount, category, parentCategory, payee, note, tags, id }

/// How amounts are expressed in the imported file.
enum AmountMode { signed, typeColumn }

/// Date formats supported by the import wizard.
const csvDateFormats = ['yyyy-MM-dd', 'dd/MM/yyyy', 'MM/dd/yyyy', 'dd.MM.yyyy', 'dd-MM-yyyy', 'yyyy/MM/dd'];

/// Detected file properties.
class CsvDetection {
  const CsvDetection({required this.text, required this.delimiter, required this.encoding});
  final String text;
  final String delimiter;

  /// `utf-8` or `latin-1`.
  final String encoding;
}

/// Import options chosen in the wizard.
class CsvImportOptions {
  const CsvImportOptions({
    required this.mapping,
    required this.dateFormat,
    this.decimalComma = false,
    this.amountMode = AmountMode.typeColumn,
    this.hasHeader = true,
  });

  final Map<CsvField, int> mapping;
  final String dateFormat;
  final bool decimalComma;
  final AmountMode amountMode;
  final bool hasHeader;
}

/// A parsed, not-yet-resolved import row.
class CsvImportRow {
  const CsvImportRow({
    required this.rowNumber,
    required this.day,
    required this.type,
    required this.amountText,
    this.timeMinutes,
    this.currency,
    this.account,
    this.toAccount,
    this.toAmountText,
    this.category,
    this.parentCategory,
    this.payee,
    this.note,
    this.tags = const [],
    this.id,
  });

  final int rowNumber;
  final LocalDay day;
  final int? timeMinutes;
  final String type;

  /// Positive amount with `.` decimal separator, e.g. `354.25`.
  final String amountText;
  final String? currency;
  final String? account;
  final String? toAccount;
  final String? toAmountText;
  final String? category;
  final String? parentCategory;
  final String? payee;
  final String? note;
  final List<String> tags;
  final String? id;

  /// Converts [amountText] to minor units for [c].
  Result<int> minor(Currency c) => AmountInputParser.parse(amountText, c);
  Result<int>? toMinor(Currency c) => toAmountText == null ? null : AmountInputParser.parse(toAmountText!, c);
}

/// Error on a specific CSV row.
class CsvRowError {
  const CsvRowError(this.rowNumber, this.code);
  final int rowNumber;
  final String code;
}

/// CSV export/import logic (APP_PROMPT §7.2–7.3).
abstract final class CsvService {
  static const _bom = [0xEF, 0xBB, 0xBF];

  /// UTF-8 with BOM, `,` or `;` separator, CRLF, decimal point, no grouping.
  static Uint8List export(List<CsvExportRow> rows, {String separator = ','}) {
    final data = <List<Object?>>[
      csvColumns,
      for (final r in rows)
        [
          r.day.toIso(),
          r.timeMinutes == null ? '' : Fmt.time(r.timeMinutes!),
          r.type,
          MoneyFormatter.plain(r.amount, r.currency),
          r.currency.code,
          r.account,
          r.toAccount ?? '',
          r.toAmount == null ? '' : MoneyFormatter.plain(r.toAmount!, r.toCurrency ?? r.currency),
          r.category ?? '',
          r.parentCategory ?? '',
          r.payee ?? '',
          r.note ?? '',
          r.tags.join('|'),
          r.id,
        ],
    ];
    final text = Csv(fieldDelimiter: separator, autoDetect: false).encode(data);
    return Uint8List.fromList([..._bom, ...utf8.encode(text)]);
  }

  /// Detects encoding (UTF-8 with/without BOM, else Latin-1) and delimiter.
  static Result<CsvDetection> detect(Uint8List bytes) {
    if (bytes.isEmpty) return const Err(AppFailure.importFormat('csv_empty'));
    var b = bytes;
    if (b.length >= 3 && b[0] == _bom[0] && b[1] == _bom[1] && b[2] == _bom[2]) b = b.sublist(3);
    String text;
    var encoding = 'utf-8';
    try {
      text = utf8.decode(b);
    } on FormatException {
      text = latin1.decode(b);
      encoding = 'latin-1';
    }
    if (text.trim().isEmpty) return const Err(AppFailure.importFormat('csv_empty'));
    final lines = const LineSplitter().convert(text).where((l) => l.trim().isNotEmpty).take(5).toList();
    var best = ',';
    var bestScore = -1;
    for (final d in const [',', ';', '\t', '|']) {
      final counts = lines.map((l) => d.allMatches(_stripQuoted(l)).length).toList();
      if (counts.isEmpty || counts.first == 0) continue;
      final consistent = counts.every((c) => c == counts.first);
      final score = counts.first * (consistent ? 10 : 1);
      if (score > bestScore) {
        bestScore = score;
        best = d;
      }
    }
    return Ok(CsvDetection(text: text, delimiter: best, encoding: encoding));
  }

  static String _stripQuoted(String line) => line.replaceAll(RegExp('"[^"]*"'), '');

  static List<List<String>> parse(String text, String delimiter) {
    final rows = Csv(fieldDelimiter: delimiter, autoDetect: false).decode(text);
    return [
      for (final r in rows) [for (final c in r) '${c ?? ''}'.trim()],
    ];
  }

  static const _synonyms = <CsvField, List<String>>{
    CsvField.date: ['date', 'day', 'jour', 'date opération', 'date operation'],
    CsvField.time: ['time', 'heure'],
    CsvField.type: ['type', 'kind', 'nature', 'sens'],
    CsvField.amount: ['amount', 'montant', 'value', 'valeur', 'somme', 'débit/crédit'],
    CsvField.currency: ['currency', 'devise', 'monnaie'],
    CsvField.account: ['account', 'compte', 'wallet', 'portefeuille'],
    CsvField.toAccount: ['to_account', 'to account', 'compte destination', 'vers'],
    CsvField.toAmount: ['to_amount', 'to amount', 'montant reçu', 'montant destination'],
    CsvField.category: ['category', 'catégorie', 'categorie'],
    CsvField.parentCategory: ['parent_category', 'parent category', 'catégorie parente', 'categorie parente'],
    CsvField.payee: ['payee', 'bénéficiaire', 'beneficiaire', 'tiers', 'merchant', 'commerçant', 'libellé', 'libelle'],
    CsvField.note: ['note', 'notes', 'memo', 'mémo', 'remarque', 'description', 'commentaire'],
    CsvField.tags: ['tags', 'étiquettes', 'etiquettes', 'labels'],
    CsvField.id: ['id', 'uuid'],
  };

  /// Auto-matches columns by header name (EN and FR synonyms).
  static Map<CsvField, int> autoMap(List<String> header) {
    final out = <CsvField, int>{};
    for (var i = 0; i < header.length; i++) {
      final h = header[i].trim().toLowerCase();
      for (final e in _synonyms.entries) {
        if (!out.containsKey(e.key) && e.value.contains(h)) {
          out[e.key] = i;
          break;
        }
      }
    }
    return out;
  }

  /// Picks the first date format that parses every sample.
  static String detectDateFormat(Iterable<String> samples) {
    final s = samples.where((x) => x.trim().isNotEmpty).take(50).toList();
    for (final f in csvDateFormats) {
      if (s.isNotEmpty && s.every((x) => parseDate(x, f) != null)) return f;
    }
    return csvDateFormats.first;
  }

  /// Parses [s] with one of [csvDateFormats] (strict, ignores a time suffix).
  static LocalDay? parseDate(String s, String format) {
    final v = s.trim().split(RegExp(r'[ T]')).first;
    final parts = v.split(RegExp(r'[-/.]'));
    if (parts.length != 3 || parts.any((p) => int.tryParse(p) == null)) return null;
    final n = parts.map(int.parse).toList();
    final (y, m, d) = switch (format) {
      'yyyy-MM-dd' || 'yyyy/MM/dd' => (n[0], n[1], n[2]),
      'MM/dd/yyyy' => (n[2], n[0], n[1]),
      _ => (n[2], n[1], n[0]),
    };
    final sep = format.contains('/') ? '/' : format.contains('.') ? '.' : '-';
    if (!v.contains(sep)) return null;
    if (y < 1900 || y > 2200 || m < 1 || m > 12 || d < 1 || d > LocalDay.daysInMonth(y, m)) return null;
    if (format.startsWith('yyyy') ? parts[0].length != 4 : parts[2].length != 4) return null;
    return LocalDay(y, m, d);
  }

  static int? _parseTime(String s) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(s.trim());
    if (m == null) return null;
    final h = int.parse(m[1]!);
    final mm = int.parse(m[2]!);
    if (h > 23 || mm > 59) return null;
    return h * 60 + mm;
  }

  static String _type(String s) {
    final v = s.trim().toLowerCase();
    if (const ['income', 'revenu', 'revenus', 'credit', 'crédit', 'in', 'entrée'].contains(v)) return 'income';
    if (const ['transfer', 'virement', 'transfert'].contains(v)) return 'transfer';
    if (const ['expense', 'dépense', 'depense', 'debit', 'débit', 'out', 'sortie'].contains(v)) return 'expense';
    return '';
  }

  /// Normalizes an amount to `-?digits(.digits)?` according to options.
  static String? normalizeAmount(String raw, {required bool decimalComma}) {
    var s = AmountInputParser.normalizeDigits(raw)
        .replaceAll(RegExp(r'[\s  ]'), '')
        .replaceAll('−', '-')
        .replaceAll(RegExp(r'[^\d,.\-+]'), '');
    if (s.isEmpty) return null;
    if (decimalComma) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else {
      s = s.replaceAll(',', '');
    }
    if (!RegExp(r'^[+-]?\d*\.?\d+$').hasMatch(s) && !RegExp(r'^[+-]?\d+\.?$').hasMatch(s)) return null;
    return s.replaceFirst('+', '');
  }

  /// Parses rows with [o]; returns valid rows and per-row errors.
  static (List<CsvImportRow>, List<CsvRowError>) parseRows(List<List<String>> table, CsvImportOptions o) {
    final rows = <CsvImportRow>[];
    final errors = <CsvRowError>[];
    String? cell(List<String> r, CsvField f) {
      final i = o.mapping[f];
      if (i == null || i >= r.length) return null;
      final v = r[i].trim();
      return v.isEmpty ? null : v;
    }

    for (var i = o.hasHeader ? 1 : 0; i < table.length; i++) {
      final r = table[i];
      final rowNumber = i + 1;
      if (r.every((c) => c.trim().isEmpty)) continue;
      final day = parseDate(cell(r, CsvField.date) ?? '', o.dateFormat);
      if (day == null) {
        errors.add(CsvRowError(rowNumber, 'date'));
        continue;
      }
      final amount = normalizeAmount(cell(r, CsvField.amount) ?? '', decimalComma: o.decimalComma);
      if (amount == null) {
        errors.add(CsvRowError(rowNumber, 'amount'));
        continue;
      }
      var type = _type(cell(r, CsvField.type) ?? '');
      final negative = amount.startsWith('-');
      final abs = negative ? amount.substring(1) : amount;
      if (o.amountMode == AmountMode.signed || type.isEmpty) {
        if (type != 'transfer') type = negative ? 'expense' : 'income';
      }
      if (RegExp(r'^0*\.?0*$').hasMatch(abs)) {
        errors.add(CsvRowError(rowNumber, 'amount'));
        continue;
      }
      final toAmount = cell(r, CsvField.toAmount);
      rows.add(CsvImportRow(
        rowNumber: rowNumber,
        day: day,
        timeMinutes: _parseTime(cell(r, CsvField.time) ?? ''),
        type: type,
        amountText: abs,
        currency: cell(r, CsvField.currency)?.toUpperCase(),
        account: cell(r, CsvField.account),
        toAccount: cell(r, CsvField.toAccount),
        toAmountText: toAmount == null ? null : normalizeAmount(toAmount, decimalComma: o.decimalComma)?.replaceFirst('-', ''),
        category: cell(r, CsvField.category),
        parentCategory: cell(r, CsvField.parentCategory),
        payee: cell(r, CsvField.payee),
        note: cell(r, CsvField.note),
        tags: (cell(r, CsvField.tags) ?? '').split('|').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
        id: cell(r, CsvField.id),
      ));
    }
    return (rows, errors);
  }

  /// Duplicate key: same local date + amount + payee + account.
  static String duplicateKey(LocalDay day, int amount, String? payee, String accountId) =>
      '${day.toIso()}|$amount|${(payee ?? '').trim().toLowerCase()}|$accountId';
}
