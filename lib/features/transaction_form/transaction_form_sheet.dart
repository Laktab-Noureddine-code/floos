import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/money/money_formatter.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/time/local_day.dart';
import 'package:floos/core/utils/formatters.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/core/widgets/toggles.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/repositories/transactions_repository.dart';
import 'package:floos/features/common/pickers.dart';
import 'package:floos/features/recurring/recurring_config.dart';
import 'package:floos/features/transaction_form/amount_keypad.dart';
import 'package:floos/features/transaction_form/form_parts.dart';
import 'package:floos/features/transaction_form/tx_form_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Opens the add/edit transaction sheet (design.md §4.4, APP_PROMPT §6.4).
Future<void> openTransactionForm(BuildContext context, {TxFormArgs args = const TxFormArgs()}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
  sheetAnimationStyle: const AnimationStyle(duration: AppMotion.sheet),
  builder: (_) => TransactionFormSheet(args: args),
);

class TransactionFormSheet extends ConsumerStatefulWidget {
  const TransactionFormSheet({required this.args, super.key});

  final TxFormArgs args;

  @override
  ConsumerState<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<TransactionFormSheet> {
  late final TxFormController c = TxFormController(ref, widget.args);
  final _payee = TextEditingController();
  final _note = TextEditingController();
  final _toAmount = TextEditingController();
  final _rate = TextEditingController();
  bool _keypad = true;
  bool _advanced = false;

  @override
  void initState() {
    super.initState();
    c.init().then((_) {
      _payee.text = c.value.payee;
      _note.text = c.value.note;
      _toAmount.text = c.value.toExpr;
      if (mounted) setState(() => _advanced = c.value.debtId != null || c.value.goalId != null || c.value.exclude);
    });
  }

  @override
  void dispose() {
    c.dispose();
    _payee.dispose();
    _note.dispose();
    _toAmount.dispose();
    _rate.dispose();
    super.dispose();
  }

  void _showKeypad(bool v) {
    if (v) FocusScope.of(context).unfocus();
    setState(() => _keypad = v);
  }

  Future<void> _save({bool another = false}) async {
    final l = context.l10n;
    c.update((s) => s.copyWith(payee: _payee.text, note: _note.text, toExpr: _toAmount.text, rateExpr: _rate.text));
    var scope = RecurringEditScope.onlyThis;
    if (c.value.isEdit && c.value.ruleId != null) {
      final picked = await showDialog<RecurringEditScope>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(l.txRecurringScopeTitle),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x2),
              child: Text(l.txRecurringScopeMessage, style: ctx.text.bodyS),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, RecurringEditScope.onlyThis),
              child: Text(l.txScopeOnlyThis),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, RecurringEditScope.thisAndFuture),
              child: Text(l.txScopeFuture),
            ),
          ],
        ),
      );
      if (picked == null) return;
      scope = picked;
    }
    final outcome = await c.save(scope: scope);
    if (!mounted || !outcome.ok) {
      if (outcome.failure != null && c.value.errors.containsKey('amount')) _showKeypad(true);
      return;
    }
    await Haptics.light();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (another) {
      c.resetForNext();
      _payee.clear();
      _note.clear();
      _toAmount.clear();
      _rate.clear();
      _showKeypad(true);
    } else {
      Navigator.pop(context);
    }
    final isNew = !c.value.isEdit || another;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.saved),
          duration: AppMotion.undo,
          action: isNew && widget.args.editId == null
              ? SnackBarAction(label: l.undo, onPressed: () => c.undoCreate(outcome))
              : null,
        ),
      );
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final id = c.value.editId!;
    final repo = ref.read(transactionsRepoProvider);
    final snaps = (await repo.delete(id)).valueOrNull ?? const <TxSnapshot>[];
    await Haptics.light();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l.deleted),
        duration: AppMotion.undo,
        action: SnackBarAction(label: l.undo, onPressed: () => repo.restore(snaps)),
      )).closed.then((reason) {
        if (reason != SnackBarClosedReason.action) repo.finalizeDelete(snaps);
      });
  }

  void _duplicate() {
    final s = c.value;
    final nav = Navigator.of(context);
    final ctx = nav.context;
    nav.pop();
    Snack.show(ctx, context.l10n.txDuplicated);
    openTransactionForm(
      ctx,
      args: TxFormArgs(
        duplicateOf: TxDraft(
          type: s.type,
          amount: 1,
          accountId: s.accountId!,
          toAccountId: s.toAccountId,
          categoryId: s.categoryId,
          day: s.day,
          timeMinutes: s.time,
          payee: _payee.text,
          note: _note.text,
          tagIds: s.tagIds,
        ).copyWith(amount: c.amountOrZero),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(accountsStreamProvider);
    final l = context.l10n;
    final height = MediaQuery.sizeOf(context).height * 0.92;
    return ValueListenableBuilder<TxFormState>(
      valueListenable: c,
      builder: (context, s, _) {
        final accounts = ref.watch(accountsStreamProvider).value ?? const <AccountRow>[];
        if (s.loaded && accounts.isEmpty) {
          return SizedBox(
            height: height * 0.4,
            child: Center(child: Text(l.txNoAccount, style: context.text.bodyS)),
          );
        }
        return SizedBox(
          height: height,
          child: SheetFrame(
            child: Column(
              children: [
                _header(s),
                Expanded(child: _form(s, accounts)),
                if (_keypad)
                  AmountKeypad(
                    onKey: c.key,
                    onBackspace: c.backspace,
                    onClear: c.clearAmount,
                  ),
                _buttons(s),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(TxFormState s) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.sm, AppSpace.sm),
      child: Row(
        children: [
          Expanded(child: Text(s.isEdit ? l.txEdit : l.txNew, style: context.text.titleM)),
          if (s.isEdit) ...[
            CircleIconButton(icon: PhosphorIconsRegular.copy, tooltip: l.duplicate, onPressed: _duplicate),
            CircleIconButton(icon: PhosphorIconsRegular.trash, tooltip: l.delete, onPressed: _delete),
          ],
          CircleIconButton(icon: Icons.close_rounded, tooltip: l.close, onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  String _err(TxFormState s, String field) {
    final f = s.errors[field];
    return f == null ? '' : failureMessage(context.l10n, f);
  }

  String? _errOrNull(TxFormState s, String field) => s.errors[field] == null ? null : _err(s, field);

  Widget _form(TxFormState s, List<AccountRow> accounts) {
    final l = context.l10n;
    final byId = {for (final a in accounts) a.id: a};
    final cur = c.currency;
    final preview = c.preview;
    final fmt = ref.watch(formatterProvider);
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpace.lg),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          child: SegmentedToggle<String>(
            options: const ['expense', 'income', 'transfer'],
            value: s.type,
            labelOf: (t) => switch (t) {
              'expense' => l.typeExpense,
              'income' => l.typeIncome,
              _ => l.typeTransfer,
            },
            onChanged: c.setType,
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Semantics(
          label: l.amount,
          value: s.expr,
          button: true,
          child: InkWell(
            onTap: () => _showKeypad(true),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.sm),
              child: Column(
                children: [
                  FittedBox(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          s.expr.isEmpty ? '0' : s.expr,
                          style: context.text.displayL.copyWith(
                            color: s.expr.isEmpty ? context.colors.textTertiary : context.colors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Text(cur.symbol, style: context.text.titleL.copyWith(color: context.colors.textSecondary)),
                      ],
                    ),
                  ),
                  if (preview != null)
                    Text(l.txAmountPreview(fmt.format(preview, cur)), style: context.text.bodyS),
                  FieldError(_errOrNull(s, 'amount')),
                ],
              ),
            ),
          ),
        ),
        if (s.type != 'transfer') ...[
          const SizedBox(height: AppSpace.sm),
          CategoryStrip(
            kind: s.type,
            selectedId: s.categoryId,
            onSelect: (id) => c.update((x) => x.copyWith(categoryId: () => id, errors: {...x.errors}..remove('category'))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            child: FieldError(_errOrNull(s, 'category')),
          ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _dateRow(s),
              FormRow(
                icon: PhosphorIconsRegular.wallet,
                label: s.type == 'transfer' ? l.txFromAccount : l.account,
                value: byId[s.accountId]?.name,
                error: _errOrNull(s, 'account'),
                onTap: () async {
                  final id = await pickAccount(context, selectedId: s.accountId);
                  if (id != null) c.setAccount(id);
                  _toAmount.text = c.value.toExpr;
                },
              ),
              if (s.type == 'transfer')
                FormRow(
                  icon: PhosphorIconsRegular.arrowRight,
                  label: l.txToAccount,
                  value: byId[s.toAccountId]?.name,
                  error: _errOrNull(s, 'toAccount'),
                  onTap: () async {
                    final id = await pickAccount(context, excludeId: s.accountId, selectedId: s.toAccountId);
                    if (id != null) c.setToAccount(id);
                    _toAmount.text = c.value.toExpr;
                  },
                ),
              if (c.crossCurrency) _toAmountField(s),
              if (c.needsRate) _rateField(s),
              _payeeField(s),
              _textField(_note, PhosphorIconsRegular.note, l.txNoteHint, 500, (v) => c.update((x) => x.copyWith(note: v))),
              TagsField(selected: s.tagIds, onChanged: (v) => c.update((x) => x.copyWith(tagIds: v))),
              AttachmentsField(
                existing: s.attachments,
                added: s.newAttachments,
                removed: s.removedAttachments,
                onAdd: (paths) => c.update((x) => x.copyWith(newAttachments: [...x.newAttachments, ...paths])),
                onRemoveExisting: (id) => c.update((x) => x.copyWith(removedAttachments: {...x.removedAttachments, id})),
                onRemoveNew: (p) => c.update((x) => x.copyWith(newAttachments: [...x.newAttachments]..remove(p))),
              ),
              const Divider(),
              if (!s.isEdit)
                FormRow(
                  icon: PhosphorIconsRegular.repeat,
                  label: l.txRepeat,
                  value: s.recurring == null
                      ? l.txRepeatNone
                      : describeFrequency(l, s.recurring!.frequency, s.recurring!.interval, s.day,
                          weekday: s.recurring!.byWeekday, monthDay: s.recurring!.byMonthDay),
                  onTap: () async {
                    final r = await editRecurring(context, start: s.day, initial: s.recurring);
                    if (r != null) c.update((x) => x.copyWith(recurring: () => r.$1));
                  },
                ),
              _advancedSection(s),
              FieldError(_errOrNull(s, 'form')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dateRow(TxFormState s) {
    final l = context.l10n;
    final today = ref.watch(todayProvider);
    final isToday = s.day == today;
    final isYesterday = s.day == today.addDays(-1);
    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.rowHeight),
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.calendarBlank, size: AppSizes.iconGlyph, color: context.colors.textSecondary),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Wrap(
                  spacing: AppSpace.xs,
                  children: [
                    ChoicePill(label: l.today, selected: isToday, onTap: () => c.update((x) => x.copyWith(day: today))),
                    ChoicePill(
                      label: l.yesterday,
                      selected: isYesterday,
                      onTap: () => c.update((x) => x.copyWith(day: today.addDays(-1))),
                    ),
                    ChoicePill(
                      label: isToday || isYesterday ? l.txCalendar : Fmt.mediumDay(s.day),
                      selected: !isToday && !isYesterday,
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: s.day.toDateTime(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(today.year + 10),
                        );
                        if (d != null) c.update((x) => x.copyWith(day: LocalDay.fromDateTime(d)));
                      },
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () async {
                  if (s.time != null) {
                    c.update((x) => x.copyWith(time: () => null));
                    return;
                  }
                  final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (t != null) c.update((x) => x.copyWith(time: () => t.hour * 60 + t.minute));
                },
                child: Text(s.time == null ? l.txAddTime : '${Fmt.time(s.time!)} ✕', style: context.text.caption),
              ),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }

  Widget _toAmountField(TxFormState s) {
    final l = context.l10n;
    final rate = c.suggestedRateE6;
    final to = c.toCurrency!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _toAmount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onTap: () => _showKeypad(false),
            onChanged: (v) => c.update((x) => x.copyWith(toExpr: v, errors: {...x.errors}..remove('toAmount'))),
            decoration: InputDecoration(
              labelText: '${l.txToAmount} (${to.code})',
              errorText: _errOrNull(s, 'toAmount'),
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            rate == null
                ? l.txRateMissingHint(c.currency.code, to.code)
                : l.txRateLine(c.currency.code, _rateText(rate), to.code),
            style: context.text.caption,
          ),
        ],
      ),
    );
  }

  static String _rateText(int rateE6) =>
      MoneyFormatter.plain(rateE6, const Currency(code: 'R', symbol: '', digits: 6, name: ''))
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '')
          .replaceAll('.', ',');

  Widget _rateField(TxFormState s) {
    final l = context.l10n;
    final base = ref.watch(baseCurrencyProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.txRateMissingHint(c.currency.code, base.code), style: context.text.caption),
          const SizedBox(height: AppSpace.xs),
          TextField(
            controller: _rate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onTap: () => _showKeypad(false),
            onChanged: (v) => c.update((x) => x.copyWith(rateExpr: v, errors: {...x.errors}..remove('rate'))),
            decoration: InputDecoration(labelText: l.txRateField(c.currency.code, base.code), errorText: _errOrNull(s, 'rate')),
          ),
        ],
      ),
    );
  }

  Widget _payeeField(TxFormState s) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: RawAutocomplete<(String, String?, String)>(
        textEditingController: _payee,
        focusNode: FocusNode(),
        optionsBuilder: (v) async {
          if (v.text.trim().isEmpty) return const [];
          return ref.read(transactionsRepoProvider).payees(v.text.trim());
        },
        displayStringForOption: (o) => o.$1,
        onSelected: (o) => c.choosePayee(o.$1, o.$2, o.$3),
        fieldViewBuilder: (context, ctrl, focus, onSubmit) => TextField(
          controller: ctrl,
          focusNode: focus,
          maxLength: 60,
          onTap: () => _showKeypad(false),
          onChanged: (v) => c.update((x) => x.copyWith(payee: v)),
          decoration: InputDecoration(
            counterText: '',
            prefixIcon: const Icon(PhosphorIconsRegular.storefront),
            hintText: l.txPayeeHint,
            labelText: l.payee,
          ),
        ),
        optionsViewBuilder: (context, onSelected, options) => Align(
          alignment: AlignmentDirectional.topStart,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: AppSizes.maxContentWidth - AppSpace.x3),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final o in options) ListTile(title: Text(o.$1), onTap: () => onSelected(o)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, IconData icon, String hint, int max, ValueChanged<String> onChanged) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
        child: TextField(
          controller: ctrl,
          maxLength: max,
          minLines: 1,
          maxLines: 3,
          onTap: () => _showKeypad(false),
          onChanged: onChanged,
          decoration: InputDecoration(counterText: '', prefixIcon: Icon(icon), hintText: hint, labelText: context.l10n.note),
        ),
      );

  Widget _advancedSection(TxFormState s) {
    final l = context.l10n;
    final debts = (ref.watch(debtsStreamProvider).value ?? const <DebtRow>[]).where((d) => d.status == 'open').toList();
    final goals = (ref.watch(goalsStreamProvider).value ?? const <GoalRow>[]).where((g) => g.status == 'active').toList();
    return ExpansionTile(
      initiallyExpanded: _advanced,
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      title: Text(l.txAdvanced, style: context.text.bodyS.copyWith(color: context.colors.textPrimary)),
      children: [
        DropdownButtonFormField<String?>(
          initialValue: s.debtId,
          decoration: InputDecoration(labelText: l.txLinkDebt),
          items: [
            DropdownMenuItem(child: Text(l.none)),
            for (final d in debts) DropdownMenuItem(value: d.id, child: Text(d.personName)),
          ],
          onChanged: (v) => c.update((x) => x.copyWith(debtId: () => v)),
        ),
        const SizedBox(height: AppSpace.sm),
        DropdownButtonFormField<String?>(
          initialValue: s.goalId,
          decoration: InputDecoration(labelText: l.txContributeGoal),
          items: [
            DropdownMenuItem(child: Text(l.none)),
            for (final g in goals) DropdownMenuItem(value: g.id, child: Text(g.name)),
          ],
          onChanged: (v) => c.update((x) => x.copyWith(goalId: () => v)),
        ),
        SwitchRow(
          label: l.txExcludeReports,
          subtitle: l.txExcludeReportsHint,
          value: s.exclude,
          onChanged: (v) => c.update((x) => x.copyWith(exclude: v)),
        ),
        SwitchRow(
          label: l.txPinned,
          value: s.pinned,
          onChanged: (v) => c.update((x) => x.copyWith(pinned: v)),
        ),
      ],
    );
  }

  Widget _buttons(TxFormState s) {
    final l = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
        child: Row(
          children: [
            if (!s.isEdit) ...[
              Expanded(
                child: PrimaryButton(
                  label: l.txSaveAndAdd,
                  secondary: true,
                  onPressed: c.canSave ? () => _save(another: true) : null,
                ),
              ),
              const SizedBox(width: AppSpace.md),
            ],
            Expanded(
              child: PrimaryButton(label: l.save, busy: s.saving, onPressed: c.canSave ? _save : null),
            ),
          ],
        ),
      ),
    );
  }
}
