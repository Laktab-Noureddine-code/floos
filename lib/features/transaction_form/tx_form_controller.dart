import 'package:floos/app/providers.dart';
import 'package:floos/core/money/calculator.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/money/money.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/utils/result.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/repositories/recurring_repository.dart';
import 'package:floos/data/repositories/transactions_repository.dart';
import 'package:floos/domain/services/fx_service.dart';
import 'package:floos/features/recurring/recurring_config.dart';
import 'package:floos/features/transaction_form/amount_keypad.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How the form was opened.
@immutable
class TxFormArgs {
  const TxFormArgs({this.editId, this.duplicateOf, this.type, this.day, this.accountId, this.goalId, this.debtId});

  final String? editId;
  final TxDraft? duplicateOf;
  final String? type;
  final LocalDay? day;
  final String? accountId;
  final String? goalId;
  final String? debtId;
}

/// Immutable form state.
@immutable
class TxFormState {
  const TxFormState({
    required this.type,
    required this.day,
    this.expr = '',
    this.toExpr = '',
    this.rateExpr = '',
    this.accountId,
    this.toAccountId,
    this.categoryId,
    this.time,
    this.payee = '',
    this.note = '',
    this.tagIds = const [],
    this.newAttachments = const [],
    this.attachments = const [],
    this.removedAttachments = const {},
    this.recurring,
    this.debtId,
    this.goalId,
    this.exclude = false,
    this.pinned = false,
    this.errors = const {},
    this.saving = false,
    this.editId,
    this.ruleId,
    this.loaded = false,
  });

  final String type;
  final LocalDay day;
  final String expr;
  final String toExpr;
  final String rateExpr;
  final String? accountId;
  final String? toAccountId;
  final String? categoryId;
  final int? time;
  final String payee;
  final String note;
  final List<String> tagIds;
  final List<String> newAttachments;
  final List<AttachmentRow> attachments;
  final Set<String> removedAttachments;
  final RecurringConfig? recurring;
  final String? debtId;
  final String? goalId;
  final bool exclude;
  final bool pinned;

  /// field → failure code (shown inline in red).
  final Map<String, AppFailure> errors;
  final bool saving;
  final String? editId;
  final String? ruleId;
  final bool loaded;

  bool get isEdit => editId != null;

  TxFormState copyWith({
    String? type,
    LocalDay? day,
    String? expr,
    String? toExpr,
    String? rateExpr,
    String? Function()? accountId,
    String? Function()? toAccountId,
    String? Function()? categoryId,
    int? Function()? time,
    String? payee,
    String? note,
    List<String>? tagIds,
    List<String>? newAttachments,
    List<AttachmentRow>? attachments,
    Set<String>? removedAttachments,
    RecurringConfig? Function()? recurring,
    String? Function()? debtId,
    String? Function()? goalId,
    bool? exclude,
    bool? pinned,
    Map<String, AppFailure>? errors,
    bool? saving,
    String? Function()? editId,
    String? Function()? ruleId,
    bool? loaded,
  }) => TxFormState(
    type: type ?? this.type,
    day: day ?? this.day,
    expr: expr ?? this.expr,
    toExpr: toExpr ?? this.toExpr,
    rateExpr: rateExpr ?? this.rateExpr,
    accountId: accountId != null ? accountId() : this.accountId,
    toAccountId: toAccountId != null ? toAccountId() : this.toAccountId,
    categoryId: categoryId != null ? categoryId() : this.categoryId,
    time: time != null ? time() : this.time,
    payee: payee ?? this.payee,
    note: note ?? this.note,
    tagIds: tagIds ?? this.tagIds,
    newAttachments: newAttachments ?? this.newAttachments,
    attachments: attachments ?? this.attachments,
    removedAttachments: removedAttachments ?? this.removedAttachments,
    recurring: recurring != null ? recurring() : this.recurring,
    debtId: debtId != null ? debtId() : this.debtId,
    goalId: goalId != null ? goalId() : this.goalId,
    exclude: exclude ?? this.exclude,
    pinned: pinned ?? this.pinned,
    errors: errors ?? this.errors,
    saving: saving ?? this.saving,
    editId: editId != null ? editId() : this.editId,
    ruleId: ruleId != null ? ruleId() : this.ruleId,
    loaded: loaded ?? this.loaded,
  );
}

/// Result of a save.
@immutable
class TxSaveOutcome {
  const TxSaveOutcome({this.txId, this.createdRuleId, this.failure});
  final String? txId;
  final String? createdRuleId;
  final AppFailure? failure;
  bool get ok => txId != null;
}

/// Scope chosen when editing a recurring-generated transaction.
enum RecurringEditScope { onlyThis, thisAndFuture }

/// Form logic (validation, calculator, persistence). The sheet only renders.
class TxFormController extends ValueNotifier<TxFormState> {
  TxFormController(this.ref, this.args)
    : super(TxFormState(type: args.type ?? 'expense', day: args.day ?? ref.read(todayProvider)));

  final WidgetRef ref;
  final TxFormArgs args;

  Map<String, AccountRow> get _accounts => {
    for (final a in ref.read(accountsStreamProvider).value ?? const <AccountRow>[]) a.id: a,
  };

  Currency currencyOf(String? accountId) =>
      Currencies.of(_accounts[accountId]?.currencyCode ?? ref.read(prefsProvider).baseCurrency);

  Currency get currency => currencyOf(value.accountId);
  Currency? get toCurrency => value.toAccountId == null ? null : currencyOf(value.toAccountId);
  Currency get base => ref.read(baseCurrencyProvider);
  FxService get _fx => ref.read(fxProvider);

  bool get crossCurrency => value.type == 'transfer' && toCurrency != null && toCurrency!.code != currency.code;

  /// Expense/income in a non-base currency with no stored rate → ask.
  bool get needsRate =>
      value.type != 'transfer' &&
      value.accountId != null &&
      currency.code != base.code &&
      !_fx.hasRateOnOrBefore(currency.code, base.code, value.day) &&
      !_fx.hasAnyRate(currency.code, base.code);

  Future<void> init() async {
    final ui = ref.read(uiPrefsProvider);
    final accounts = (ref.read(accountsStreamProvider).value ?? const <AccountRow>[]).where((a) => !a.archived).toList();
    if (args.editId != null) {
      final repo = ref.read(transactionsRepoProvider);
      final row = await repo.byId(args.editId!);
      if (row != null) {
        final draft = TxDraft.fromRow(row, await repo.tagIds(row.id));
        _fromDraft(draft, editId: row.id);
        value = value.copyWith(attachments: await ref.read(attachmentStoreProvider).forTransaction(row.id));
      }
    } else if (args.duplicateOf != null) {
      _fromDraft(args.duplicateOf!.copyWith(day: ref.read(todayProvider)));
      value = value.copyWith(ruleId: () => null);
    } else {
      final lastType = ui.getString(UiKeys.lastTxType);
      final lastAccount = ui.getString(UiKeys.lastAccount);
      final accountId = args.accountId ??
          (accounts.any((a) => a.id == lastAccount) ? lastAccount : (accounts.isEmpty ? null : accounts.first.id));
      value = value.copyWith(
        type: args.type ?? lastType ?? 'expense',
        accountId: () => accountId,
        goalId: () => args.goalId,
        debtId: () => args.debtId,
      );
    }
    value = value.copyWith(loaded: true);
  }

  void _fromDraft(TxDraft d, {String? editId}) {
    final c = currencyOf(d.accountId);
    value = value.copyWith(
      type: d.type,
      day: d.day,
      expr: _exprOf(d.amount, c),
      toExpr: d.toAmount == null ? '' : _exprOf(d.toAmount!, currencyOf(d.toAccountId)),
      accountId: () => d.accountId,
      toAccountId: () => d.toAccountId,
      categoryId: () => d.categoryId,
      time: () => d.timeMinutes,
      payee: d.payee ?? '',
      note: d.note ?? '',
      tagIds: d.tagIds,
      debtId: () => d.debtId,
      goalId: () => d.goalId,
      exclude: d.excludeFromReports,
      pinned: d.pinned,
      editId: () => editId,
      ruleId: () => d.recurringRuleId,
    );
  }

  static String _exprOf(int minor, Currency c) {
    if (c.digits == 0) return '$minor';
    final major = minor ~/ c.factor;
    final frac = (minor % c.factor).toString().padLeft(c.digits, '0').replaceFirst(RegExp(r'0+$'), '');
    return frac.isEmpty ? '$major' : '$major,$frac';
  }

  void update(TxFormState Function(TxFormState s) f) {
    value = f(value);
  }

  void clearError(String field) {
    if (!value.errors.containsKey(field)) return;
    value = value.copyWith(errors: {...value.errors}..remove(field));
  }

  void setType(String type) {
    final keepCategory = value.categoryId != null && _categoryKind(value.categoryId!) == type;
    value = value.copyWith(
      type: type,
      categoryId: keepCategory ? null : () => null,
      toAccountId: type == 'transfer' ? null : () => null,
      errors: const {},
    );
  }

  String? _categoryKind(String id) => ref.read(categoriesMapProvider)[id]?.kind;

  void setAccount(String id) {
    value = value.copyWith(accountId: () => id, errors: {...value.errors}..remove('account'));
    _suggestToAmount();
  }

  void setToAccount(String id) {
    value = value.copyWith(toAccountId: () => id, errors: {...value.errors}..remove('toAccount'));
    _suggestToAmount();
  }

  /// Pre-fills the "to amount" from the latest stored rate.
  void _suggestToAmount() {
    if (!crossCurrency) return;
    final amount = Calculator.evaluate(value.expr, currency).valueOrNull;
    if (amount == null || amount <= 0) return;
    final converted = _fx.convertMinor(amount, currency.code, toCurrency!.code, value.day).valueOrNull;
    if (converted != null) value = value.copyWith(toExpr: _exprOf(converted, toCurrency!));
  }

  /// Suggested rate text for a cross-currency transfer, or null.
  int? get suggestedRateE6 => crossCurrency ? _fx.rateE6(currency.code, toCurrency!.code, value.day) : null;

  void key(String k) {
    value = value.copyWith(
      expr: applyKey(value.expr, k, maxDecimals: currency.digits),
      errors: {...value.errors}..remove('amount'),
    );
  }

  void backspace() {
    if (value.expr.isEmpty) return;
    value = value.copyWith(expr: value.expr.substring(0, value.expr.length - 1));
  }

  void clearAmount() => value = value.copyWith(expr: '');

  /// Live preview when the expression contains an operator.
  int? get preview => Calculator.hasOperator(value.expr) ? Calculator.evaluate(value.expr, currency).valueOrNull : null;

  /// Evaluated amount or 0 (for duplicates).
  int get amountOrZero => Calculator.evaluate(value.expr, currency).valueOrNull ?? 0;

  bool get canSave => value.expr.isNotEmpty && !value.saving;

  /// Choosing a known payee suggests its last category.
  void choosePayee(String payee, String? categoryId, String type) {
    value = value.copyWith(payee: payee);
    if (categoryId != null && type == value.type && value.type != 'transfer') {
      value = value.copyWith(categoryId: () => categoryId, errors: {...value.errors}..remove('category'));
    }
  }

  /// Validates and persists. [scope] applies to recurring-generated edits.
  Future<TxSaveOutcome> save({RecurringEditScope scope = RecurringEditScope.onlyThis}) async {
    final s = value;
    final errors = <String, AppFailure>{};
    final amount = Calculator.evaluate(s.expr, currency);
    final amountMinor = amount.valueOrNull;
    if (amountMinor == null) {
      errors['amount'] = amount.failureOrNull!;
    } else if (amountMinor <= 0) {
      errors['amount'] = const AppFailure.validation('amount_zero');
    } else if (amountMinor >= kMaxMinorUnits) {
      errors['amount'] = const AppFailure.validation('amount_too_large');
    }
    if (s.accountId == null) errors['account'] = const AppFailure.validation('account_required');
    int? toMinor;
    if (s.type == 'transfer') {
      if (s.toAccountId == null) {
        errors['toAccount'] = const AppFailure.validation('to_account_required');
      } else if (s.toAccountId == s.accountId) {
        errors['toAccount'] = const AppFailure.validation('same_account');
      } else if (crossCurrency) {
        final r = Calculator.evaluate(s.toExpr, toCurrency!);
        toMinor = r.valueOrNull;
        if (toMinor == null || toMinor <= 0) errors['toAmount'] = const AppFailure.validation('to_amount_required');
      }
    } else if (s.categoryId == null) {
      errors['category'] = const AppFailure.validation('category_required');
    }
    int? rateE6;
    if (needsRate) {
      final r = Calculator.evaluate(s.rateExpr, const Currency(code: 'RATE', symbol: '', digits: 6, name: ''));
      rateE6 = r.valueOrNull;
      if (rateE6 == null || rateE6 <= 0) {
        errors['rate'] = AppFailure.validation('rate_missing', args: {'from': currency.code, 'to': base.code});
      }
    }
    if (errors.isNotEmpty) {
      value = s.copyWith(errors: errors);
      return TxSaveOutcome(failure: errors.values.first);
    }
    value = s.copyWith(saving: true, errors: const {});
    try {
      if (rateE6 != null) {
        await ref.read(ratesRepoProvider).add(currency.code, base.code, rateE6, s.day);
      }
      // Remember the implied rate of a cross-currency transfer when none exists.
      if (crossCurrency && toMinor != null && suggestedRateE6 == null) {
        await ref.read(ratesRepoProvider).add(
          currency.code,
          toCurrency!.code,
          FxService.impliedRateE6(amountMinor!, currency, toMinor, toCurrency!),
          s.day,
        );
      }
      final draft = TxDraft(
        id: s.editId,
        type: s.type,
        amount: amountMinor!,
        accountId: s.accountId!,
        toAccountId: s.type == 'transfer' ? s.toAccountId : null,
        toAmount: toMinor,
        categoryId: s.type == 'transfer' ? null : s.categoryId,
        day: s.day,
        timeMinutes: s.time,
        payee: s.payee,
        note: s.note,
        tagIds: s.tagIds,
        recurringRuleId: s.ruleId,
        debtId: s.debtId,
        goalId: s.goalId,
        excludeFromReports: s.exclude,
        pinned: s.pinned,
      );
      String? createdRule;
      var finalDraft = draft;
      if (!s.isEdit && s.recurring != null) {
        final rc = s.recurring!;
        final r = await ref.read(recurringRepoProvider).save(
          RecurringDraft(
            template: draft,
            name: rc.name,
            frequency: rc.frequency,
            interval: rc.interval,
            byWeekday: rc.byWeekday,
            byMonthDay: rc.byMonthDay,
            start: s.day,
            end: rc.end,
            maxOccurrences: rc.maxOccurrences,
            mode: rc.mode,
            remindDaysBefore: rc.remindDaysBefore,
            remindTimeMinutes: rc.remindTimeMinutes,
            firstAlreadyCreated: true,
          ),
        );
        if (r case Err(:final failure)) return _fail(failure);
        createdRule = r.valueOrNull;
        finalDraft = TxDraft(
          type: draft.type,
          amount: draft.amount,
          accountId: draft.accountId,
          toAccountId: draft.toAccountId,
          toAmount: draft.toAmount,
          categoryId: draft.categoryId,
          day: draft.day,
          timeMinutes: draft.timeMinutes,
          payee: draft.payee,
          note: draft.note,
          tagIds: draft.tagIds,
          recurringRuleId: createdRule,
          debtId: draft.debtId,
          goalId: draft.goalId,
          excludeFromReports: draft.excludeFromReports,
          pinned: draft.pinned,
        );
      }
      final saved = await ref.read(transactionsRepoProvider).save(finalDraft);
      if (saved case Err(:final failure)) return _fail(failure);
      final id = saved.requireValue;
      if (s.isEdit && s.ruleId != null && scope == RecurringEditScope.thisAndFuture) {
        await ref.read(recurringRepoProvider).applyTemplate(s.ruleId!, finalDraft);
      }
      final store = ref.read(attachmentStoreProvider);
      for (final a in s.removedAttachments) {
        await store.remove(a);
      }
      for (final path in s.newAttachments) {
        await store.add(id, path);
      }
      final ui = ref.read(uiPrefsProvider);
      await ui.setString(UiKeys.lastTxType, s.type);
      await ui.setString(UiKeys.lastAccount, s.accountId!);
      value = value.copyWith(saving: false);
      return TxSaveOutcome(txId: id, createdRuleId: createdRule);
    } on Object {
      return _fail(const AppFailure.storage('storage_error'));
    }
  }

  TxSaveOutcome _fail(AppFailure f) {
    value = value.copyWith(saving: false, errors: {'form': f});
    return TxSaveOutcome(failure: f);
  }

  /// Resets for "Save & add another" (keeps date, account and type).
  void resetForNext() {
    value = TxFormState(
      type: value.type,
      day: value.day,
      accountId: value.accountId,
      toAccountId: value.toAccountId,
      loaded: true,
    );
  }

  /// Undo for a newly created transaction.
  Future<void> undoCreate(TxSaveOutcome o) async {
    final repo = ref.read(transactionsRepoProvider);
    final snaps = await repo.delete(o.txId!);
    await repo.finalizeDelete(snaps.valueOrNull ?? const []);
    if (o.createdRuleId != null) {
      await ref.read(recurringRepoProvider).delete(o.createdRuleId!, deletePast: false);
    }
  }
}
