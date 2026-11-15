import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:floos/app/services/csv_importer.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/data/repositories/transactions_repository.dart';
import 'package:floos/domain/services/backup_service.dart';
import 'package:floos/domain/services/csv_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_db.dart';

void main() {
  late TestEnv env;
  late Directory dir;
  late BackupService backups;

  setUp(() async {
    env = TestEnv();
    await env.seed();
    dir = await Directory.systemTemp.createTemp('floos_test');
    backups = BackupService(
      db: env.db,
      attachmentsDir: Directory('${dir.path}/attachments'),
      backupsDir: Directory('${dir.path}/backups'),
      appVersion: '1.0.0+1',
      clock: env.clock,
    );
  });
  tearDown(() async {
    await env.dispose();
    await dir.delete(recursive: true);
  });

  Future<List<String>> snapshot() async => [
    for (final t in await env.transactions.get(const TxFilter(includePending: true)))
      '${t.tx.id}|${t.tx.type}|${t.tx.amount}|${t.tx.toAmount}|${t.tx.date}|${t.tx.payee}|${t.tx.note}|${t.tagNames.join(',')}',
  ]..sort();

  group('backup', () {
    test('round trip without password restores data and attachments', () async {
      final cash = await env.account(initial: 1000);
      final tx = await env.expense(cash, 4500, payee: 'Marjane', note: 'courses');
      final tag = (await env.tags.ensure('Maison')).requireValue;
      await env.transactions.addTag([tx], tag);
      await Directory('${dir.path}/attachments').create(recursive: true);
      await File('${dir.path}/attachments/a1.jpg').writeAsBytes([1, 2, 3]);
      final before = await snapshot();
      final file = (await backups.create(baseCurrency: 'MAD')).requireValue;
      expect(file.path.endsWith('.floos'), isTrue);
      await env.db.wipeAll();
      await File('${dir.path}/attachments/a1.jpg').delete();
      expect(await snapshot(), isEmpty);
      final preview = (await backups.inspect(file)).requireValue;
      expect(preview.manifest.counts['transactions'], 1);
      expect(preview.manifest.encrypted, isFalse);
      expect((await backups.restore(preview)).isOk, isTrue);
      expect(await snapshot(), before);
      expect(await File('${dir.path}/attachments/a1.jpg').readAsBytes(), [1, 2, 3]);
      final search = await env.transactions.get(const TxFilter(text: 'marj'));
      expect(search.length, 1, reason: 'FTS rebuilt after restore');
    });

    test('password backup: wrong password refused, right one restores', () async {
      final cash = await env.account();
      await env.expense(cash, 100);
      final before = await snapshot();
      final file = (await backups.create(password: 'secret', iterationsOverride: 1000)).requireValue;
      final preview = (await backups.inspect(file)).requireValue;
      expect(preview.manifest.encrypted, isTrue);
      expect((await backups.restore(preview, password: 'nope')).failureOrNull?.code, 'backup_wrong_password');
      expect(await snapshot(), before, reason: 'unchanged on failure');
      await env.db.wipeAll();
      expect((await backups.restore(preview, password: 'secret')).isOk, isTrue);
      expect(await snapshot(), before);
    });

    test('corrupted, foreign and newer-schema files are refused (edge case 8)', () async {
      final file = (await backups.create()).requireValue;
      final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
      final tampered = Archive();
      for (final f in archive.files) {
        final bytes = f.readBytes()!;
        tampered.addFile(ArchiveFile.bytes(f.name, f.name == 'data.db' ? (Uint8List.fromList(bytes)..[100] ^= 0xff) : bytes));
      }
      final bad = File('${dir.path}/bad.floos')..writeAsBytesSync(ZipEncoder().encodeBytes(tampered));
      expect((await backups.inspect(bad)).failureOrNull?.code, 'backup_checksum');
      final garbage = File('${dir.path}/x.floos')..writeAsStringSync('not a zip');
      expect((await backups.inspect(garbage)).failureOrNull?.code, 'backup_invalid');
      final newer = Archive();
      for (final f in archive.files) {
        var bytes = f.readBytes()!;
        if (f.name == 'manifest.json') {
          bytes = Uint8List.fromList(String.fromCharCodes(bytes).replaceFirst('"schema_version":1', '"schema_version":99').codeUnits);
        }
        newer.addFile(ArchiveFile.bytes(f.name, bytes));
      }
      final nf = File('${dir.path}/n.floos')..writeAsBytesSync(ZipEncoder().encodeBytes(newer));
      expect((await backups.inspect(nf)).failureOrNull?.code, 'backup_newer_schema');
    });

    test('rotation keeps newest N and isDue', () async {
      await Directory('${dir.path}/backups').create(recursive: true);
      for (var i = 1; i <= 5; i++) {
        File('${dir.path}/backups/floos_backup_2026010${i}_1200.floos').writeAsStringSync('x');
      }
      await backups.rotate(2);
      final left = await backups.list();
      expect(left.length, 2);
      expect(left.first.path.contains('20260105'), isTrue);
      final now = DateTime(2026, 1, 10, 12);
      expect(BackupService.isDue('off', null, now), isFalse);
      expect(BackupService.isDue('daily', null, now), isTrue);
      expect(BackupService.isDue('daily', DateTime(2026, 1, 9, 13), now), isTrue);
      expect(BackupService.isDue('weekly', DateTime(2026, 1, 9, 12), now), isFalse);
      expect(BackupService.isDue('monthly', DateTime(2025, 12, 1), now), isTrue);
    });
  });

  group('csv', () {
    test('export → import round trip reproduces transactions', () async {
      final cash = await env.account();
      final eur = await env.account(name: 'Euro', currency: 'EUR');
      final t1 = await env.expense(cash, 35425, payee: 'Café "Paris", centre', note: 'ligne1');
      final tag = (await env.tags.ensure('Voyage')).requireValue;
      await env.transactions.addTag([t1], tag);
      await env.income(cash, 1000000);
      await env.transactions.save(TxDraft(type: 'transfer', amount: 10800, accountId: cash, toAccountId: eur, toAmount: 1000, day: env.today));
      final views = await env.transactions.get(const TxFilter());
      final rows = [
        for (final v in views)
          CsvExportRow(
            day: LocalDay.fromStorage(v.tx.date),
            type: v.tx.type,
            amount: v.tx.amount,
            currency: Currencies.of(v.accountCurrency),
            account: v.accountName,
            toAccount: v.toAccountName,
            toAmount: v.tx.toAmount,
            toCurrency: v.toAccountCurrency == null ? null : Currencies.of(v.toAccountCurrency!),
            category: v.categoryName,
            payee: v.tx.payee,
            note: v.tx.note,
            tags: v.tagNames,
            id: v.tx.id,
          ),
      ];
      final bytes = CsvService.export(rows, separator: ';');
      expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
      final before = await snapshot();
      await env.db.customStatement('DELETE FROM transactions');
      final det = CsvService.detect(bytes).requireValue;
      expect(det.delimiter, ';');
      final table = CsvService.parse(det.text, det.delimiter);
      final mapping = CsvService.autoMap(table.first);
      expect(mapping.length, csvColumns.length);
      final opts = CsvImportOptions(mapping: mapping, dateFormat: CsvService.detectDateFormat(table.skip(1).map((r) => r[0])));
      final (parsed, errors) = CsvService.parseRows(table, opts);
      expect(errors, isEmpty);
      final importer = CsvImporter(env.db, env.transactions, clock: env.clock);
      final plan = await importer.plan(parsed, errors, 'MAD');
      expect(plan.unknownAccounts, isEmpty);
      expect(plan.unknownCategories, isEmpty);
      final report = (await importer.run(plan, accountRes: {}, categoryRes: {}, baseCurrency: 'MAD')).requireValue;
      expect(report.imported, 3);
      expect(await snapshot(), before);
      final again = await importer.plan(parsed, errors, 'MAD');
      expect(again.duplicates.length, 3);
      final r2 = (await importer.run(again, accountRes: {}, categoryRes: {}, baseCurrency: 'MAD')).requireValue;
      expect(r2.skipped, 3);
    });

    test('foreign file: FR headers, signed amounts, decimal comma, unknown names', () async {
      const text = 'Date;Montant;Catégorie;Compte;Libellé\n'
          '12/01/2026;-45,50;Boulangerie;Carte;Paul\n'
          '13/01/2026;1 200,00;Salaire;Carte;Employeur\n'
          'bad;10;x;Carte;y\n'
          '14/01/2026;abc;x;Carte;y\n';
      final det = CsvService.detect(Uint8List.fromList(text.codeUnits)).requireValue;
      final table = CsvService.parse(det.text, det.delimiter);
      final map = CsvService.autoMap(table.first);
      expect(map[CsvField.payee], 4);
      final fmt = CsvService.detectDateFormat(table.skip(1).take(2).map((r) => r[0]));
      expect(fmt, 'dd/MM/yyyy');
      final (rows, errors) = CsvService.parseRows(
        table,
        CsvImportOptions(mapping: map, dateFormat: fmt, decimalComma: true, amountMode: AmountMode.signed),
      );
      expect(rows.length, 2);
      expect(errors.map((e) => e.rowNumber), [4, 5]);
      expect(rows.first.type, 'expense');
      expect(rows.first.amountText, '45.50');
      final importer = CsvImporter(env.db, env.transactions, clock: env.clock);
      final plan = await importer.plan(rows, errors, 'MAD');
      expect(plan.unknownAccounts.keys, ['Carte']);
      expect(plan.unknownCategories, {'Boulangerie': 'expense', 'Salaire': 'income'});
      final report = (await importer.run(
        plan,
        accountRes: {'Carte': const CreateNew()},
        categoryRes: {'Boulangerie': const CreateNew(), 'Salaire': MapToExisting(await env.categoryId('Salary'))},
        baseCurrency: 'MAD',
      )).requireValue;
      expect(report.imported, 2);
      expect(report.errors.length, 2);
      final card = (await env.accounts.getAll()).single;
      expect(await env.accounts.balanceOf(card.id, LocalDay(2026, 1, 31)), 120000 - 4550);
    });

    test('detect latin-1, empty file, tab delimiter, date parsing', () {
      expect(CsvService.detect(Uint8List(0)).failureOrNull?.code, 'csv_empty');
      final latin = CsvService.detect(Uint8List.fromList([0x63, 0x61, 0x66, 0xE9, 0x09, 0x31, 0x0A])).requireValue;
      expect(latin.encoding, 'latin-1');
      expect(latin.delimiter, '\t');
      expect(CsvService.parseDate('2026-02-30', 'yyyy-MM-dd'), isNull);
      expect(CsvService.parseDate('01/12/2026', 'MM/dd/yyyy'), LocalDay(2026, 1, 12));
      expect(CsvService.parseDate('12.01.2026', 'dd.MM.yyyy'), LocalDay(2026, 1, 12));
      expect(CsvService.parseDate('2026-01-12T10:00', 'yyyy-MM-dd'), LocalDay(2026, 1, 12));
      expect(CsvService.normalizeAmount('1.234,56', decimalComma: true), '1234.56');
      expect(CsvService.normalizeAmount('1,234.56', decimalComma: false), '1234.56');
      expect(CsvService.normalizeAmount('MAD', decimalComma: false), isNull);
      expect(CsvService.duplicateKey(LocalDay(2026, 1, 1), 5, ' Uber ', 'a'), '2026-01-01|5|uber|a');
    });
  });
}
