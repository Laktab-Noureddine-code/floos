import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/time/period.dart';
import 'package:floos/data/db/seed.dart';
import 'package:floos/data/repositories/accounts_repository.dart';
import 'package:floos/data/repositories/budgets_repository.dart';
import 'package:floos/data/repositories/categories_repository.dart';
import 'package:floos/data/repositories/debts_repository.dart';
import 'package:floos/data/repositories/goals_repository.dart';
import 'package:floos/data/repositories/recurring_repository.dart';
import 'package:floos/data/repositories/settings_repository.dart';
import 'package:floos/data/repositories/transactions_repository.dart';
import 'package:floos/domain/services/recurring_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_db.dart';

LocalDay d(int y, int m, int day) => LocalDay(y, m, day);

void main() {
  late TestEnv env;

  setUp(() async {
    env = TestEnv();
    await env.seed();
  });
  tearDown(() => env.dispose());

  group('seed', () {
    test('localized, idempotent, with system categories', () async {
      final all = await env.categories.getAll();
      expect(all.where((c) => c.kind == 'expense').length, 20);
      expect(all.where((c) => c.kind == 'income').length, 8);
      expect(all.where((c) => c.isSystem).length, 3);
      await seedCategories(env.db, 'fr', 0);
      expect((await env.categories.getAll()).length, all.length);
      final fr = TestEnv();
      await fr.seed(locale: 'fr');
      expect((await fr.categories.getAll()).any((c) => c.name == 'Alimentation'), isTrue);
      await fr.dispose();
    });
  });

  group('accounts & balances', () {
    test('validation and unique names among active accounts', () async {
      final a = await env.account();
      final dup = await env.accounts.save(
        const AccountDraft(name: 'cash', type: 'cash', currencyCode: 'MAD', initialBalance: 0, color: 'blue', icon: 'wallet'),
      );
      expect(dup.failureOrNull?.code, 'account_name_taken');
      expect(
        (await env.accounts.save(const AccountDraft(name: '', type: 'cash', currencyCode: 'MAD', initialBalance: 0, color: 'b', icon: 'w'))).failureOrNull?.code,
        'account_name_length',
      );
      expect(
        (await env.accounts.save(const AccountDraft(name: 'X', type: 'cash', currencyCode: 'QQQ', initialBalance: 0, color: 'b', icon: 'w'))).failureOrNull?.code,
        'currency_invalid',
      );
      await env.accounts.setArchived(a, archived: true);
      expect((await env.accounts.save(
        const AccountDraft(name: 'Cash', type: 'cash', currencyCode: 'MAD', initialBalance: 0, color: 'blue', icon: 'wallet'),
      )).isOk, isTrue);
      expect((await env.accounts.setArchived(a, archived: false)).failureOrNull?.code, 'account_name_taken');
    });

    test('balance = initial + income − expense ± transfers, pending and future excluded', () async {
      final cash = await env.account(initial: 10000);
      final bank = await env.account(name: 'Bank', initial: 5000);
      await env.income(cash, 2000);
      await env.expense(cash, 1500);
      await env.transactions.save(TxDraft(type: 'transfer', amount: 3000, accountId: cash, toAccountId: bank, day: env.today));
      await env.transactions.save(
        TxDraft(type: 'expense', amount: 999, accountId: cash, categoryId: await env.categoryId('Food & Groceries'), day: env.today, pending: true),
      );
      await env.expense(cash, 777, day: env.today.addDays(3));
      final list = await env.accounts.withBalances(env.today);
      final byId = {for (final a in list) a.account.id: a.balance};
      expect(byId[cash], 10000 + 2000 - 1500 - 3000);
      expect(byId[bank], 8000);
      expect(await env.accounts.balanceOf(cash, env.today.addDays(5)), 7500 - 777);
    });

    test('cross-currency transfer uses to_amount', () async {
      final mad = await env.account();
      final eur = await env.account(name: 'Euro', currency: 'EUR');
      final missing = await env.transactions.save(TxDraft(type: 'transfer', amount: 1000, accountId: mad, toAccountId: eur, day: env.today));
      expect(missing.failureOrNull?.code, 'to_amount_required');
      await env.transactions.save(TxDraft(type: 'transfer', amount: 1080, accountId: mad, toAccountId: eur, toAmount: 100, day: env.today));
      expect(await env.accounts.balanceOf(eur, env.today), 100);
      expect(await env.accounts.balanceOf(mad, env.today), -1080);
    });

    test('running balance via window function', () async {
      final cash = await env.account(initial: 1000);
      final t1 = await env.expense(cash, 100, day: d(2026, 1, 10));
      final t2 = await env.income(cash, 50, day: d(2026, 1, 11));
      final t3 = await env.expense(cash, 30, day: d(2026, 1, 11));
      final flows = await env.transactions.runningFlows({cash}, {t1, t2, t3});
      expect(flows[t1], -100);
      expect(flows[t2], -50);
      expect(flows[t3], -80);
    });

    test('reconcile creates an excluded adjustment', () async {
      final cash = await env.account(initial: 1000);
      final r = await env.transactions.reconcile(cash, 1000, 1250, env.today);
      expect(r.valueOrNull, isNotNull);
      expect(await env.accounts.balanceOf(cash, env.today), 1250);
      final tx = await env.transactions.byId(r.valueOrNull!);
      expect(tx!.excludeFromReports, isTrue);
      expect((await env.transactions.reconcile(cash, 5, 5, env.today)).valueOrNull, isNull);
    });

    test('delete rules: conflict, move, delete-all, goal unlinked (edge case 5)', () async {
      final a = await env.account();
      final b = await env.account(name: 'B');
      await env.expense(a, 100);
      expect((await env.accounts.delete(a)).failureOrNull?.code, 'account_has_transactions');
      final goal = (await env.goals.save(
        GoalDraft(name: 'G', target: 100, start: env.today, icon: 'target', color: 'blue', trackingMode: 'linked', linkedAccountId: a),
      )).requireValue;
      expect((await env.accounts.delete(a, deletion: MoveTransactionsTo(b))).isOk, isTrue);
      expect(await env.accounts.balanceOf(b, env.today), -100);
      final g = await env.goals.byId(goal);
      expect(g!.trackingMode, 'manual');
      expect(g.linkedAccountId, isNull);
      expect((await env.accounts.delete(b, deletion: const DeleteTransactions())).isOk, isTrue);
      expect(await env.db.transactionsDao.count(), 0);
      final empty = await env.account(name: 'Empty');
      expect((await env.accounts.delete(empty)).isOk, isTrue);
    });

    test('reorder', () async {
      final a = await env.account();
      final b = await env.account(name: 'B');
      await env.accounts.reorder([b, a]);
      expect((await env.accounts.getAll()).first.id, b);
    });
  });

  group('transactions', () {
    test('validation', () async {
      final cash = await env.account();
      final food = await env.categoryId('Food & Groceries');
      final salary = await env.categoryId('Salary');
      Future<String?> code(TxDraft t) async => (await env.transactions.save(t)).failureOrNull?.code;
      expect(await code(TxDraft(type: 'expense', amount: 0, accountId: cash, categoryId: food, day: env.today)), 'amount_zero');
      expect(await code(TxDraft(type: 'expense', amount: 10000000000000, accountId: cash, categoryId: food, day: env.today)), 'amount_too_large');
      expect(await code(TxDraft(type: 'expense', amount: 1, accountId: cash, day: env.today)), 'category_required');
      expect(await code(TxDraft(type: 'expense', amount: 1, accountId: cash, categoryId: salary, day: env.today)), 'category_kind_mismatch');
      expect(await code(TxDraft(type: 'transfer', amount: 1, accountId: cash, toAccountId: cash, day: env.today)), 'same_account');
      expect(await code(TxDraft(type: 'transfer', amount: 1, accountId: cash, day: env.today)), 'to_account_required');
      expect(await code(TxDraft(type: 'expense', amount: 1, accountId: 'nope', categoryId: food, day: env.today)), 'account_required');
      expect(await code(TxDraft(type: 'expense', amount: 1, accountId: cash, categoryId: food, day: env.today, payee: 'x' * 61)), 'payee_too_long');
      expect(await code(TxDraft(type: 'expense', amount: 1, accountId: cash, categoryId: food, day: env.today, note: 'x' * 501)), 'note_too_long');
      expect(await code(TxDraft(type: 'expense', amount: 1, accountId: cash, categoryId: food, day: env.today, timeMinutes: 1440)), 'time_invalid');
      expect(await code(TxDraft(type: 'nope', amount: 1, accountId: cash, day: env.today)), 'tx_type_invalid');
    });

    test('FTS search, amount ops and filters', () async {
      final cash = await env.account();
      await env.expense(cash, 4500, payee: 'Marjane Market', note: 'weekly groceries');
      await env.expense(cash, 12000, payee: 'Café Paris', category: 'Restaurants & Cafes');
      await env.expense(cash, 999, payee: 'Other', day: d(2025, 12, 1));
      Future<int> n(TxFilter f) async => (await env.transactions.get(f)).length;
      expect(await n(const TxFilter(text: 'marj')), 1);
      expect(await n(const TxFilter(text: 'groceries')), 1);
      expect(await n(const TxFilter(text: 'cafe')), 1, reason: 'diacritics removed');
      expect(await n(const TxFilter(amountOp: AmountOp.eq, amountValue: 4500)), 1);
      expect(await n(const TxFilter(amountOp: AmountOp.gt, amountValue: 1000)), 2);
      expect(await n(TxFilter(startMs: d(2026, 1, 1).toStorage())), 2);
      expect(await n(TxFilter(categoryIds: {await env.categoryId('Restaurants & Cafes')})), 1);
      expect(await n(const TxFilter(minAmount: 1000, maxAmount: 5000)), 1);
      expect(await n(const TxFilter(text: '"*()')), 3, reason: 'garbage query ignored');
      final paged = await env.transactions.get(const TxFilter(), limit: 2, offset: 2);
      expect(paged.length, 1);
    });

    test('tags, pin, delete with undo, bulk ops', () async {
      final cash = await env.account();
      final b = await env.account(name: 'B');
      final tag = (await env.tags.ensure('Work')).requireValue;
      expect((await env.tags.ensure('work')).requireValue, tag);
      final id = (await env.transactions.save(
        TxDraft(type: 'expense', amount: 100, accountId: cash, categoryId: await env.categoryId('Food & Groceries'), day: env.today, tagIds: [tag]),
      )).requireValue;
      final view = await env.transactions.view(id);
      expect(view!.tagNames, ['Work']);
      expect((await env.transactions.get(TxFilter(tagIds: {tag}))).length, 1);
      await env.transactions.setPinned(id, pinned: true);
      expect((await env.transactions.get(const TxFilter(pinnedOnly: true))).length, 1);
      final snaps = (await env.transactions.delete(id)).requireValue;
      expect(await env.db.transactionsDao.count(), 0);
      await env.transactions.restore(snaps);
      expect((await env.transactions.view(id))!.tagNames, ['Work']);
      await env.transactions.changeCategory([id], await env.categoryId('Transport'));
      expect((await env.transactions.byId(id))!.categoryId, await env.categoryId('Transport'));
      await env.transactions.changeAccount([id], b);
      expect((await env.transactions.byId(id))!.accountId, b);
      final tag2 = (await env.tags.ensure('Trip')).requireValue;
      await env.transactions.addTag([id], tag2);
      expect((await env.transactions.tagIds(id)).toSet(), {tag, tag2});
      await env.transactions.deleteMany([id]);
      expect(await env.db.transactionsDao.count(), 0);
    });

    test('payee autocomplete suggests last category', () async {
      final cash = await env.account();
      await env.expense(cash, 100, payee: 'Uber', category: 'Transport', day: d(2026, 1, 1));
      await env.expense(cash, 100, payee: 'uber', category: 'Travel', day: d(2026, 1, 5));
      final list = await env.transactions.payees('ub');
      expect(list.length, 1);
      expect(list.first.$2, await env.categoryId('Travel'));
    });

    test('totals stream and aggregate exclude transfers, pending, excluded', () async {
      final cash = await env.account();
      final b = await env.account(name: 'B');
      await env.expense(cash, 100);
      await env.income(cash, 500);
      await env.transactions.save(TxDraft(type: 'transfer', amount: 50, accountId: cash, toAccountId: b, day: env.today));
      await env.transactions.save(TxDraft(
        type: 'expense', amount: 70, accountId: cash, categoryId: await env.categoryId('Health'), day: env.today, excludeFromReports: true,
      ));
      final p = Period.month(env.today, 1);
      final exp = await env.transactions.aggregate(type: 'expense', period: p);
      expect(exp.fold<int>(0, (a, r) => a + r.sum), 100);
      final byCat = await env.transactions.aggregate(type: 'expense', period: p, key: AggKey.category);
      expect(byCat.single.key, await env.categoryId('Food & Groceries'));
      final totals = await env.transactions.watchTotals(const TxFilter()).first;
      expect(totals.map((t) => t.$2).toSet(), {'expense', 'income', 'transfer'});
    });
  });

  group('categories', () {
    test('depth, delete with reassign, system protection, merge, budget archived (edge case 4)', () async {
      final food = await env.categoryId('Food & Groceries');
      final sub = (await env.categories.save(CategoryDraft(name: 'Bakery', kind: 'expense', icon: 'cake', color: 'orange', parentId: food))).requireValue;
      expect(
        (await env.categories.save(CategoryDraft(name: 'Deep', kind: 'expense', icon: 'x', color: 'x', parentId: sub))).failureOrNull?.code,
        'category_max_depth',
      );
      expect(
        (await env.categories.save(CategoryDraft(name: 'Wrong', kind: 'income', icon: 'x', color: 'x', parentId: food))).failureOrNull?.code,
        'category_kind_mismatch',
      );
      final cash = await env.account();
      await env.expense(cash, 100, category: 'Bakery');
      final budget = (await env.budgets.save(BudgetDraft(amount: 1000, period: 'monthly', categoryId: sub))).requireValue;
      expect((await env.categories.delete(sub)).failureOrNull?.code, 'category_in_use');
      final other = await env.categoryId('Other');
      expect((await env.categories.delete(other)).failureOrNull?.code, 'category_system');
      final res = (await env.categories.delete(sub, replacementId: food)).requireValue;
      expect(res.archivedBudgets, 1);
      expect((await env.budgets.byId(budget))!.archived, isTrue);
      final txs = await env.transactions.get(const TxFilter());
      expect(txs.single.tx.categoryId, food);
      final cafes = await env.categoryId('Restaurants & Cafes');
      expect((await env.categories.merge(food, cafes)).isOk, isTrue);
      expect((await env.transactions.get(const TxFilter())).single.tx.categoryId, cafes);
      expect((await env.categories.merge(cafes, await env.categoryId('Salary'))).failureOrNull?.code, 'category_kind_mismatch');
      expect((await env.categories.setArchived(other, archived: true)).failureOrNull?.code, 'category_system');
    });
  });

  group('budgets', () {
    test('one active per category+period, alerts once per threshold, past periods silent (edge case 6)', () async {
      final cash = await env.account();
      final food = await env.categoryId('Food & Groceries');
      final id = (await env.budgets.save(BudgetDraft(amount: 2000, period: 'monthly', categoryId: food))).requireValue;
      expect((await env.budgets.save(BudgetDraft(amount: 1, period: 'monthly', categoryId: food))).failureOrNull?.code, 'budget_exists');
      expect((await env.budgets.save(const BudgetDraft(amount: 0, period: 'monthly'))).failureOrNull?.code, 'amount_zero');
      expect((await env.budgets.save(const BudgetDraft(amount: 5, period: 'custom'))).failureOrNull?.code, 'custom_range_invalid');
      final prefs = await env.settings.load();
      final fx = await env.rates.fx();
      await env.expense(cash, 1640);
      var alerts = await env.budgets.newAlerts(prefs, fx, {env.today.toStorage()});
      expect(alerts.map((a) => a.$2), [80]);
      alerts = await env.budgets.newAlerts(prefs, fx, {env.today.toStorage()});
      expect(alerts, isEmpty);
      await env.expense(cash, 600);
      alerts = await env.budgets.newAlerts(prefs, fx, {env.today.toStorage()});
      expect(alerts.map((a) => a.$2), [100]);
      final view = await env.budgets.evaluate((await env.budgets.byId(id))!, prefs, fx, historyPeriods: 6);
      expect(view.status.percent, 112);
      expect(view.history.length, 6);
      // Editing last month must not alert.
      await env.expense(cash, 5000, day: d(2025, 12, 20));
      alerts = await env.budgets.newAlerts(prefs, fx, {d(2025, 12, 20).toStorage()});
      expect(alerts, isEmpty);
    });

    test('subcategories included when enabled; future-dated excluded (edge case 2)', () async {
      final cash = await env.account();
      final food = await env.categoryId('Food & Groceries');
      await env.categories.save(CategoryDraft(name: 'Bakery', kind: 'expense', icon: 'cake', color: 'orange', parentId: food));
      await env.expense(cash, 100, category: 'Bakery');
      await env.expense(cash, 900, day: env.today.addDays(2));
      final id = (await env.budgets.save(BudgetDraft(amount: 1000, period: 'monthly', categoryId: food))).requireValue;
      final prefs = await env.settings.load();
      final fx = await env.rates.fx();
      final v = await env.budgets.evaluate((await env.budgets.byId(id))!, prefs, fx);
      expect(v.status.spent, 100);
      final overall = (await env.budgets.save(const BudgetDraft(amount: 1000, period: 'weekly'))).requireValue;
      expect((await env.budgets.evaluate((await env.budgets.byId(overall))!, prefs, fx)).status.spent, 100);
    });
  });

  group('goals', () {
    test('contributions, withdrawals, completion, linked transfer', () async {
      final cash = await env.account(initial: 100000);
      final savings = await env.account(name: 'Savings');
      final id = (await env.goals.save(GoalDraft(name: 'House', target: 1000, start: env.today, icon: 'house', color: 'coral'))).requireValue;
      expect((await env.goals.contribute(id, 0, env.today)).failureOrNull?.code, 'amount_zero');
      await env.goals.contribute(id, 600, env.today);
      await env.goals.contribute(id, -100, env.today);
      final prefs = await env.settings.load();
      final fx = await env.rates.fx();
      final contributions = await env.db.goalsDao.allContributions();
      var view = env.goals.evaluate((await env.goals.byId(id))!, contributions, {}, prefs, fx);
      expect(view.status.saved, 500);
      await env.goals.contribute(id, 500, env.today);
      view = env.goals.evaluate((await env.goals.byId(id))!, await env.db.goalsDao.allContributions(), {}, prefs, fx);
      expect(await env.goals.autoComplete([view]), [id]);
      expect((await env.goals.byId(id))!.status, 'completed');
      final linked = (await env.goals.save(GoalDraft(
        name: 'Car', target: 5000, start: env.today, icon: 'car', color: 'blue', trackingMode: 'linked', linkedAccountId: savings,
      ))).requireValue;
      await env.goals.contribute(linked, 2000, env.today, fromAccountId: cash);
      expect(await env.accounts.balanceOf(savings, env.today), 2000);
      final balances = {for (final a in await env.accounts.withBalances(env.today)) a.account.id: (a.balance, a.account.currencyCode)};
      final lv = env.goals.evaluate((await env.goals.byId(linked))!, await env.db.goalsDao.allContributions(), balances, prefs, fx);
      expect(lv.status.saved, 2000);
      expect((await env.goals.save(GoalDraft(name: 'X', target: 1, start: env.today, deadline: env.today, icon: 'x', color: 'x'))).failureOrNull?.code, 'deadline_before_start');
    });

    test('transaction goal link creates a contribution', () async {
      final cash = await env.account();
      final id = (await env.goals.save(GoalDraft(name: 'Trip', target: 1000, start: env.today, icon: 'airplane', color: 'blue'))).requireValue;
      final tx = (await env.transactions.save(TxDraft(
        type: 'expense', amount: 300, accountId: cash, categoryId: await env.categoryId('Travel'), day: env.today, goalId: id,
      ))).requireValue;
      expect((await env.db.goalsDao.contributions(id)).single.amount, 300);
      await env.transactions.delete(tx);
      expect(await env.db.goalsDao.contributions(id), isEmpty);
    });
  });

  group('recurring', () {
    Future<String> rule({String mode = 'auto', LocalDay? start, int? max}) async {
      final cash = (await env.accounts.getAll()).isEmpty ? await env.account() : (await env.accounts.getAll()).first.id;
      return (await env.recurring.save(RecurringDraft(
        template: TxDraft(type: 'expense', amount: 5000, accountId: cash, categoryId: await env.categoryId('Rent / Housing'), day: env.today, payee: 'Rent'),
        frequency: Frequency.monthly,
        start: start ?? d(2025, 7, 31),
        byMonthDay: start == null ? 31 : null,
        mode: mode,
        maxOccurrences: max,
      ))).requireValue;
    }

    test('catch-up is idempotent with clamping (edge cases 1, 12)', () async {
      await rule();
      final s1 = await env.recurring.runDue();
      expect(s1.created.map((c) => c.$2), [
        d(2025, 7, 31), d(2025, 8, 31), d(2025, 9, 30), d(2025, 10, 31), d(2025, 11, 30), d(2025, 12, 31),
      ]);
      final s2 = await env.recurring.runDue();
      expect(s2.created, isEmpty);
      expect(await env.db.transactionsDao.count(), 6);
      final r = (await env.recurring.getAll()).single;
      expect(LocalDay.fromStorage(r.nextDueDate), d(2026, 1, 31));
      expect(r.occurrencesCount, 6);
    });

    test('confirm mode creates pending items excluded from balances', () async {
      await rule(mode: 'confirm', start: d(2026, 1, 10));
      final s = await env.recurring.runDue();
      expect(s.pending.length, 1);
      final cash = (await env.accounts.getAll()).first.id;
      expect(await env.accounts.balanceOf(cash, env.today), 0);
      final pending = await env.transactions.get(const TxFilter(pendingOnly: true));
      await env.transactions.confirmPending(pending.single.tx.id, amount: 4800);
      expect(await env.accounts.balanceOf(cash, env.today), -4800);
    });

    test('max occurrences deactivates; pause/resume; skip; delete keep/delete past', () async {
      final id = await rule(max: 2);
      await env.recurring.runDue();
      expect((await env.recurring.byId(id))!.active, isFalse);
      expect((await env.recurring.setActive(id, active: true)).failureOrNull?.code, 'rule_ended');
      final id2 = await rule(start: d(2026, 2, 1));
      await env.recurring.skipNext(id2);
      expect(LocalDay.fromStorage((await env.recurring.byId(id2))!.nextDueDate), d(2026, 3, 1));
      await env.recurring.setActive(id2, active: false);
      expect((await env.recurring.byId(id2))!.active, isFalse);
      await env.recurring.delete(id, deletePast: false);
      expect(await env.db.transactionsDao.count(), 2);
      final id3 = await rule(start: d(2026, 1, 1));
      await env.recurring.runDue();
      final before = await env.db.transactionsDao.count();
      await env.recurring.delete(id3, deletePast: true);
      expect(await env.db.transactionsDao.count(), before - 1);
    });

    test('created from a transaction starts at the next occurrence', () async {
      final cash = await env.account();
      final id = (await env.recurring.save(RecurringDraft(
        template: TxDraft(type: 'expense', amount: 100, accountId: cash, categoryId: await env.categoryId('Subscriptions'), day: env.today),
        frequency: Frequency.weekly,
        start: env.today,
        firstAlreadyCreated: true,
      ))).requireValue;
      final r = (await env.recurring.byId(id))!;
      expect(LocalDay.fromStorage(r.nextDueDate), env.today.addDays(7));
      expect(r.occurrencesCount, 1);
    });
  });

  group('debts', () {
    test('payments (linked and record-only), remaining, auto-settle', () async {
      final cash = await env.account(initial: 10000);
      final id = (await env.debts.save(DebtDraft(
        direction: 'i_owe', personName: 'Ahmed', amount: 500, currencyCode: 'MAD', start: env.today, due: env.today.addDays(1),
      ))).requireValue;
      final fx = await env.rates.fx();
      await env.debts.addPayment(id, 200, env.today, accountId: cash, fx: fx);
      expect(await env.accounts.balanceOf(cash, env.today), 9800);
      await env.debts.addPayment(id, 300, env.today);
      expect(await env.accounts.balanceOf(cash, env.today), 9800);
      final v = (await env.debts.views(fx)).single;
      expect(v.status.remaining, 0);
      await env.debts.autoSettle(fx);
      expect((await env.debts.byId(id))!.status, 'settled');
      expect((await env.debts.save(DebtDraft(direction: 'x', personName: 'A', amount: 1, currencyCode: 'MAD', start: env.today))).failureOrNull?.code, 'direction_invalid');
    });
  });

  group('settings & rates', () {
    test('typed prefs defaults and setters', () async {
      var p = await env.settings.load();
      expect(p.baseCurrency, 'MAD');
      expect(p.monthStartDay, 1);
      expect(p.westernDigits, isTrue);
      await env.settings.setAll({SettingKeys.monthStartDay: 31, SettingKeys.lockEnabled: true, SettingKeys.weekStartDay: 3});
      p = await env.settings.load();
      expect(p.monthStartDay, 28);
      expect(p.lockEnabled, isTrue);
      expect(p.weekStartDay, 1);
      await env.settings.dismissInsight('month:2026-01-01', 'savingsRate');
      expect((await env.settings.load()).dismissedInsights['month:2026-01-01'], ['savingsRate']);
    });

    test('missing rates block base currency change (edge case 7)', () async {
      await env.account(name: 'Euro', currency: 'EUR');
      expect(await env.rates.missingRatesFor('MAD'), {'EUR'});
      await env.rates.add('EUR', 'MAD', 10800000, env.today);
      expect(await env.rates.missingRatesFor('MAD'), isEmpty);
      expect((await env.rates.add('MAD', 'MAD', 1, env.today)).failureOrNull?.code, 'rate_same_currency');
    });
  });

  test('wipeAll clears data', () async {
    final cash = await env.account();
    await env.expense(cash, 5);
    await env.db.wipeAll();
    expect(await env.db.transactionsDao.count(), 0);
    expect(await env.db.categoriesDao.count(), 0);
    expect(await env.db.customSelect('SELECT count(*) AS c FROM transactions_fts').getSingle().then((r) => r.read<int>('c')), 0);
  });
}
