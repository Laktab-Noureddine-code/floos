import 'package:floos/core/l10n/gen/app_localizations.dart';
import 'package:floos/core/utils/result.dart';
import 'package:flutter/widgets.dart';

export 'package:floos/core/l10n/gen/app_localizations.dart';

/// App locale (French only, constitution IX).
const appLocale = Locale('fr');
const appLocaleName = 'fr';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Localized, user-friendly message for a failure code.
String failureMessage(AppLocalizations l, AppFailure? f) {
  if (f == null) return l.errorGeneric;
  String arg(String k) => '${f.args[k] ?? ''}';
  return switch (f.code) {
    'amount_empty' => l.errAmountEmpty,
    'amount_negative' => l.errAmountNegative,
    'amount_invalid' => l.errAmountInvalid,
    'amount_too_many_decimals' => l.errAmountTooManyDecimals((f.args['digits'] as int?) ?? 2),
    'amount_too_large' => l.errAmountTooLarge,
    'amount_division_zero' => l.errDivisionZero,
    'amount_zero' => l.errAmountZero,
    'account_name_length' => l.errAccountNameLength,
    'account_type_invalid' => l.errAccountTypeInvalid,
    'currency_invalid' => l.errCurrencyInvalid,
    'account_name_taken' => l.errAccountNameTaken,
    'account_not_found' => l.errAccountNotFound,
    'account_has_transactions' => l.errAccountHasTransactions,
    'category_name_length' => l.errCategoryNameLength,
    'category_parent_self' => l.errCategoryParentSelf,
    'category_not_found' => l.errCategoryNotFound,
    'category_max_depth' => l.errCategoryMaxDepth,
    'category_kind_mismatch' || 'category_kind_invalid' => l.errCategoryKindMismatch,
    'category_has_children' => l.errCategoryHasChildren,
    'category_system' => l.errCategorySystem,
    'category_in_use' => l.errCategoryInUse,
    'category_merge_same' => l.errCategoryMergeSame,
    'tag_name_length' => l.errTagNameLength,
    'tag_name_taken' => l.errTagNameTaken,
    'rate_same_currency' => l.errRateSameCurrency,
    'rate_invalid' => l.errRateInvalid,
    'rate_missing' => l.errRateMissing(arg('from'), arg('to')),
    'account_required' => l.errAccountRequired,
    'payee_too_long' => l.errPayeeTooLong,
    'note_too_long' => l.errNoteTooLong,
    'time_invalid' => l.errTimeInvalid,
    'to_account_required' => l.errToAccountRequired,
    'same_account' => l.errSameAccount,
    'to_amount_required' => l.errToAmountRequired,
    'category_required' => l.errCategoryRequired,
    'custom_range_invalid' => l.errCustomRange,
    'budget_exists' => l.errBudgetExists,
    'goal_name_length' => l.errGoalNameLength,
    'deadline_before_start' => l.errDeadlineBeforeStart,
    'linked_account_required' => l.errLinkedAccountRequired,
    'transfer_currency_mismatch' => l.errTransferCurrencyMismatch,
    'interval_invalid' => l.errIntervalInvalid,
    'month_day_invalid' => l.errMonthDayInvalid,
    'end_before_start' => l.errEndBeforeStart,
    'remind_invalid' => l.errRemindInvalid,
    'rule_ended' => l.errRuleEnded,
    'person_name_length' => l.errPersonNameLength,
    'due_before_start' => l.errDueBeforeStart,
    'attachment_failed' => l.errAttachmentFailed,
    'backup_invalid' => l.errBackupInvalid,
    'backup_checksum' => l.errBackupChecksum,
    'backup_newer_schema' => l.errBackupNewerSchema,
    'backup_wrong_password' => l.errBackupWrongPassword,
    'backup_failed' => l.errBackupFailed,
    'csv_empty' => l.errCsvEmpty,
    'csv_mapping' => l.errCsvMapping,
    'pin_mismatch' => l.errPinMismatch,
    'pin_invalid' => l.errPinInvalid,
    'base_currency_rates' => l.errBaseCurrencyRates(arg('currency'), arg('codes')),
    _ => switch (f.kind) {
      FailureKind.notFound => l.errNotFound,
      FailureKind.storage => l.errStorage,
      FailureKind.permissionDenied => l.errPermissionDenied,
      _ => l.errorGeneric,
    },
  };
}
