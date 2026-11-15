import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:floos/core/money/money.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/utils/result.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/repositories/repo_base.dart';
import 'package:floos/data/repositories/transactions_repository.dart';
import 'package:floos/domain/services/recurring_engine.dart';

/// Draft for a recurring rule (template + schedule).
class RecurringDraft {
  const RecurringDraft({
    required this.template,
    required this.frequency,
    required this.start,
    this.id,
    this.name,
    this.interval = 1,
    this.byWeekday,
    this.byMonthDay,
    this.end,
    this.maxOccurrences,
    this.mode = 'auto',
    this.remindDaysBefore,
    this.remindTimeMinutes = 540,
    this.firstAlreadyCreated = false,
  });

  final String? id;
  final String? name;

  /// Transaction template (amount/type/accounts/category/payee/note/tags).
  final TxDraft template;
  final Frequency frequency;
  final int interval;
  final int? byWeekday;
  final int? byMonthDay;
  final LocalDay start;
  final LocalDay? end;
  final int? maxOccurrences;

  /// `auto` | `confirm`.
  final String mode;
  final int? remindDaysBefore;
  final int remindTimeMinutes;

  /// True when created from the transaction form: the first occurrence is
  /// the transaction being saved, so generation starts at the next one.
  final bool firstAlreadyCreated;
}

/// Summary of one recurring engine run.
class RecurringRunSummary {
  const RecurringRunSummary(this.created, this.pending);

  /// (ruleId, day, name) of created items.
  final List<(String, LocalDay, String)> created;

  /// Subset created in confirm mode.
  final List<(String, LocalDay, String)> pending;
}

class RecurringRepository extends RepoBase {
  RecurringRepository(super.db, {required this.transactions, super.clock, super.hooks});

  final TransactionsRepository transactions;

  Stream<List<RecurringRuleRow>> watchAll() => db.recurringDao.watchAll();

  Future<List<RecurringRuleRow>> getAll() => db.recurringDao.getAll();

  Future<RecurringRuleRow?> byId(String id) => db.recurringDao.byId(id);

  static Schedule scheduleOf(RecurringRuleRow r) => Schedule(
    frequency: Frequency.values.byName(r.frequency),
    start: LocalDay.fromStorage(r.startDate),
    interval: r.interval,
    byWeekday: r.byWeekday,
    byMonthDay: r.byMonthDay,
    end: r.endDate == null ? null : LocalDay.fromStorage(r.endDate!),
    maxOccurrences: r.maxOccurrences,
  );

  static TxDraft templateOf(RecurringRuleRow r, LocalDay day) => TxDraft(
    type: r.templateType,
    amount: r.templateAmount,
    accountId: r.templateAccountId,
    toAccountId: r.templateToAccountId,
    toAmount: r.templateToAmount,
    categoryId: r.templateCategoryId,
    payee: r.templatePayee,
    note: r.templateNote,
    tagIds: (jsonDecode(r.templateTagIds) as List).cast<String>(),
    day: day,
    recurringRuleId: r.id,
    pending: r.mode == 'confirm',
  );

  /// Display name: explicit name, else payee, else empty (UI falls back to
  /// the category name).
  static String displayName(RecurringRuleRow r) => r.name?.trim().isNotEmpty ?? false
      ? r.name!.trim()
      : (r.templatePayee ?? '');

  Future<Result<String>> save(RecurringDraft d) => guard(() async {
    final t = d.template;
    final v = await transactions.validate(t.copyWith(day: d.start));
    if (v case Err(:final failure)) return Err(failure);
    if (d.interval < 1) return const Err(AppFailure.validation('interval_invalid'));
    if (d.byMonthDay != null && (d.byMonthDay! < 1 || d.byMonthDay! > 31)) {
      return const Err(AppFailure.validation('month_day_invalid'));
    }
    if (d.end != null && d.end! < d.start) return const Err(AppFailure.validation('end_before_start'));
    if (d.remindDaysBefore != null && (d.remindDaysBefore! < 0 || d.remindDaysBefore! > 7)) {
      return const Err(AppFailure.validation('remind_invalid'));
    }
    if (t.amount >= kMaxMinorUnits) return const Err(AppFailure.validation('amount_too_large'));
    final schedule = Schedule(
      frequency: d.frequency,
      start: d.start,
      interval: d.interval,
      byWeekday: d.byWeekday,
      byMonthDay: d.byMonthDay,
      end: d.end,
      maxOccurrences: d.maxOccurrences,
    );
    final existing = d.id == null ? null : await db.recurringDao.byId(d.id!);
    final now = nowMs;
    final id = d.id ?? newId();
    LocalDay nextDue;
    var count = existing?.occurrencesCount ?? 0;
    if (existing == null) {
      final first = schedule.first();
      if (d.firstAlreadyCreated) {
        nextDue = schedule.nextAfter(first);
        count = 1;
      } else {
        nextDue = first;
      }
    } else {
      // Keep progress; re-align to the (possibly new) schedule.
      final last = LocalDay.fromStorage(existing.nextDueDate).addDays(-1);
      nextDue = schedule.firstOnOrAfter(LocalDay.max(last.addDays(1), d.start));
    }
    final active = schedule.isWithinEnd(nextDue, count);
    await db.recurringDao.upsert(
      RecurringRulesCompanion(
        id: Value(id),
        createdAt: Value(existing?.createdAt ?? now),
        updatedAt: Value(now),
        name: Value(d.name?.trim().isEmpty ?? true ? null : d.name!.trim()),
        templateType: Value(t.type),
        templateAmount: Value(t.amount),
        templateAccountId: Value(t.accountId),
        templateToAccountId: Value(t.type == 'transfer' ? t.toAccountId : null),
        templateToAmount: Value(t.type == 'transfer' ? t.toAmount : null),
        templateCategoryId: Value(t.type == 'transfer' ? null : t.categoryId),
        templatePayee: Value(t.payee?.trim().isEmpty ?? true ? null : t.payee!.trim()),
        templateNote: Value(t.note?.trim().isEmpty ?? true ? null : t.note!.trim()),
        templateTagIds: Value(jsonEncode(t.tagIds)),
        frequency: Value(d.frequency.name),
        interval: Value(d.interval),
        byWeekday: Value(d.frequency == Frequency.weekly ? (d.byWeekday ?? d.start.weekday) : null),
        byMonthDay: Value(
          d.frequency == Frequency.monthly || d.frequency == Frequency.yearly
              ? (d.byMonthDay ?? d.start.day)
              : null,
        ),
        startDate: Value(d.start.toStorage()),
        endDate: Value(d.end?.toStorage()),
        maxOccurrences: Value(d.maxOccurrences),
        occurrencesCount: Value(count),
        nextDueDate: Value(nextDue.toStorage()),
        mode: Value(d.mode),
        remindDaysBefore: Value(d.remindDaysBefore),
        remindTimeMinutes: Value(d.remindTimeMinutes),
        active: Value(existing == null ? active : (existing.active && active)),
      ),
    );
    await hooks.onDataChanged();
    return Ok(id);
  });

  Future<Result<void>> setActive(String id, {required bool active}) => guard(() async {
    final r = await db.recurringDao.byId(id);
    if (r == null) return const Err(AppFailure.notFound('rule_not_found'));
    var next = LocalDay.fromStorage(r.nextDueDate);
    if (active) {
      // Resuming never floods past items: start from today.
      final today = clock.today();
      if (next < today) next = scheduleOf(r).firstOnOrAfter(today);
      if (!scheduleOf(r).isWithinEnd(next, r.occurrencesCount)) {
        return const Err(AppFailure.validation('rule_ended'));
      }
    }
    await (db.update(db.recurringRules)..where((x) => x.id.equals(id))).write(
      RecurringRulesCompanion(
        active: Value(active),
        nextDueDate: Value(next.toStorage()),
        updatedAt: Value(nowMs),
      ),
    );
    await hooks.onDataChanged();
    return const Ok(null);
  });

  /// Skips the next occurrence.
  Future<Result<void>> skipNext(String id) => guard(() async {
    final r = await db.recurringDao.byId(id);
    if (r == null) return const Err(AppFailure.notFound('rule_not_found'));
    final s = scheduleOf(r);
    final next = s.nextAfter(LocalDay.fromStorage(r.nextDueDate));
    final count = r.occurrencesCount + 1;
    await (db.update(db.recurringRules)..where((x) => x.id.equals(id))).write(
      RecurringRulesCompanion(
        nextDueDate: Value(next.toStorage()),
        occurrencesCount: Value(count),
        active: Value(r.active && s.isWithinEnd(next, count)),
        updatedAt: Value(nowMs),
      ),
    );
    await hooks.onDataChanged();
    return const Ok(null);
  });

  /// Deletes a rule; optionally deletes its past generated transactions.
  Future<Result<void>> delete(String id, {required bool deletePast}) => guard(() async {
    final days = <int>{};
    await db.transaction(() async {
      if (deletePast) {
        final rows = await (db.select(db.transactions)..where((t) => t.recurringRuleId.equals(id))).get();
        days.addAll(rows.map((r) => r.date));
        await (db.delete(db.transactions)..where((t) => t.recurringRuleId.equals(id))).go();
      } else {
        await (db.update(db.transactions)..where((t) => t.recurringRuleId.equals(id)))
            .write(const TransactionsCompanion(recurringRuleId: Value(null)));
      }
      await db.recurringDao.deleteById(id);
    });
    await hooks.onTransactionsChanged(days);
    return const Ok(null);
  });

  /// Updates the rule template from an edited transaction ("This and future").
  Future<Result<void>> applyTemplate(String ruleId, TxDraft t) => guard(() async {
    await (db.update(db.recurringRules)..where((r) => r.id.equals(ruleId))).write(
      RecurringRulesCompanion(
        templateType: Value(t.type),
        templateAmount: Value(t.amount),
        templateAccountId: Value(t.accountId),
        templateToAccountId: Value(t.toAccountId),
        templateToAmount: Value(t.toAmount),
        templateCategoryId: Value(t.categoryId),
        templatePayee: Value(t.payee),
        templateNote: Value(t.note),
        templateTagIds: Value(jsonEncode(t.tagIds)),
        updatedAt: Value(nowMs),
      ),
    );
    // Future pending items of this rule follow the new template.
    final today = clock.today().toStorage();
    await db.customUpdate(
      '''UPDATE transactions SET amount = ?, account_id = ?, category_id = ?, payee = ?, note = ?, updated_at = ?
          WHERE recurring_rule_id = ? AND is_pending = 1 AND date >= ?''',
      variables: [
        Variable(t.amount),
        Variable(t.accountId),
        Variable(t.categoryId),
        Variable(t.payee),
        Variable(t.note),
        Variable(nowMs),
        Variable(ruleId),
        Variable(today),
      ],
      updates: {db.transactions},
    );
    return const Ok(null);
  });

  /// Catch-up: materializes every occurrence due on or before today,
  /// idempotently, then advances `next_due_date` (APP_PROMPT §5.7).
  Future<RecurringRunSummary> runDue() async {
    final today = clock.today();
    final created = <(String, LocalDay, String)>[];
    final pending = <(String, LocalDay, String)>[];
    final days = <int>{};
    final rules = await db.recurringDao.active();
    for (final r in rules) {
      final s = scheduleOf(r);
      final due = RecurringEngine.due(s, LocalDay.fromStorage(r.nextDueDate), r.occurrencesCount, today);
      if (due.days.isEmpty && !due.deactivate) continue;
      final account = await db.accountsDao.byId(r.templateAccountId);
      await db.transaction(() async {
        for (final day in due.days) {
          if (account == null) break;
          final t = templateOf(r, day);
          final id = newId();
          final now = nowMs;
          final inserted = await db.transactionsDao.insertIgnore(
            TransactionsCompanion.insert(
              id: id,
              createdAt: now,
              updatedAt: now,
              type: t.type,
              amount: t.amount,
              accountId: t.accountId,
              toAccountId: Value(t.toAccountId),
              toAmount: Value(t.toAmount),
              categoryId: Value(t.categoryId),
              date: day.toStorage(),
              payee: Value(t.payee),
              note: Value(t.note),
              recurringRuleId: Value(r.id),
              isPending: Value(t.pending),
            ),
          );
          final changes = await db.customSelect('SELECT changes() AS c').getSingle();
          if (inserted > 0 && changes.read<int>('c') > 0) {
            await db.transactionsDao.setTags(id, t.tagIds);
            final entry = (r.id, day, displayName(r));
            created.add(entry);
            if (t.pending) pending.add(entry);
            days.add(day.toStorage());
          }
        }
        await (db.update(db.recurringRules)..where((x) => x.id.equals(r.id))).write(
          RecurringRulesCompanion(
            nextDueDate: Value(due.nextDue.toStorage()),
            occurrencesCount: Value(r.occurrencesCount + due.days.length),
            active: Value(!due.deactivate),
            updatedAt: Value(nowMs),
          ),
        );
      });
    }
    if (days.isNotEmpty) await hooks.onTransactionsChanged(days);
    return RecurringRunSummary(created, pending);
  }
}
