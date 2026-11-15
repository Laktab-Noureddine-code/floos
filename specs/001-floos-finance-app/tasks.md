# Tasks: Floos — Complete Offline Personal Finance Tracker

**Input**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md
**Organization**: Phases follow APP_PROMPT §19 (constitution workflow). `[P]` = parallelizable
(different files, no dependency). `[USn]` = spec user story. Gate after every phase:
`flutter analyze` (0 issues) + `flutter test` (green).

## Phase 1: Foundation (Setup)

- [ ] T001 Configure pubspec (deps, sqlite3mc hook user_define, assets, fonts, l10n `generate: true`) in pubspec.yaml
- [ ] T002 [P] Strict lints (very_good_analysis, generated excludes) in analysis_options.yaml
- [ ] T003 [P] Bundle Inter 400/500/600/700 TTF in assets/fonts/ and disable runtime fetching
- [ ] T004 [P] Design tokens: AppColors (light/dark), CategoryColor, AppSpace, AppRadius, AppShadows, AppDurations in lib/core/theme/tokens.dart, app_colors.dart
- [ ] T005 [P] Typography tokens (displayL…micro, tabular figures, letter spacing) in lib/core/theme/app_text.dart
- [ ] T006 Light + dark ThemeData + ThemeExtension `FloosTheme` in lib/core/theme/app_theme.dart
- [ ] T007 [P] l10n scaffolding l10n.yaml + lib/core/l10n/app_fr.arb (French only)
- [ ] T008 [P] Result/AppFailure, logger (release-safe), debouncer, extensions in lib/core/utils/
- [ ] T009 Router with StatefulShellRoute (Home/Report/Plan/Settings) + redirect gates in lib/core/router/
- [ ] T010 Shared components per design.md §3 in lib/core/widgets/ (AppCard, IconTile, MonthPicker pill, CircleIconButton, SegmentedToggle, ChartTypeToggle, TrendChip, LinearProgress + hatched, RingProgress, SectionHeader, InsightPill, TransactionTile, DateGroupHeader, MoneyText, GradientFab, AppBottomNav, EmptyState, PrimaryButton, SettingsGroup/Row, AppSheet, DonutChart)
- [ ] T011 [P] Icon registry (~120 Phosphor icons keyed by string) in lib/core/widgets/icon_registry.dart
- [ ] T012 [P] Original SVG illustrations (onboarding×3, empty states×6, success, lock) in assets/illustrations/

## Phase 2: Data layer (Foundational)

- [ ] T013 Drift tables per data-model.md in lib/data/db/tables/
- [ ] T014 AppDatabase with migration strategy, FTS5 + triggers, indexes, foreign keys in lib/data/db/app_database.dart
- [ ] T015 Encrypted connection (sqlite3mc, PRAGMA key from secure storage) in lib/data/db/db_connection.dart, db_key.dart
- [ ] T016 [P] DAOs: accounts, categories, transactions (+FTS, paging, aggregates), tags, attachments, budgets, goals, recurring, debts, rates, settings, notifications_log, error_log in lib/data/db/daos/
- [ ] T017 Localized seed (categories + system categories) in lib/data/db/seed.dart
- [ ] T018 Repositories returning Result in lib/data/repositories/
- [ ] T019 [P] DAO tests (in-memory) in test/data/
- [ ] T020 [P] Migration test v1 schema + framework in test/data/migration_test.dart

## Phase 3: Domain services

- [ ] T021 [P] Currency table + Money (half-even) in lib/core/money/currency.dart, money.dart
- [ ] T022 [P] MoneyFormatter (U+2212, split, mask, locale, western digits) in lib/core/money/money_formatter.dart
- [ ] T023 [P] AmountInputParser + Calculator in lib/core/money/
- [ ] T024 [P] LocalDay, Period, PeriodCalculator, Clock in lib/core/time/
- [ ] T025 [P] FxService in lib/domain/services/fx_service.dart
- [ ] T026 BalanceService + TotalsService in lib/domain/services/
- [ ] T027 BudgetService (rollover ≤12 periods, levels, per-day, projection, thresholds) in lib/domain/services/budget_service.dart
- [ ] T028 GoalService in lib/domain/services/goal_service.dart
- [ ] T029 RecurringEngine (schedule math + idempotent runner) in lib/domain/services/recurring_engine.dart
- [ ] T030 DebtService in lib/domain/services/debt_service.dart
- [ ] T031 InsightEngine (8 rules + backup warning, ranking, dismissals) in lib/domain/services/insight_engine.dart
- [ ] T032 ReportService in lib/domain/services/report_service.dart
- [ ] T033 PinHasher in lib/domain/services/pin_hasher.dart
- [ ] T034 Unit tests for T021–T033 incl. §13 edge cases in test/domain/

## Phase 4: Onboarding + lock + settings basics [US1, US10, US12]

- [ ] T035 [US1] Bootstrap & splash sequence (FR-001) in lib/main.dart, lib/app.dart, lib/features/shell/
- [ ] T036 [US1] Onboarding 4 steps + seed + coach-mark in lib/features/onboarding/
- [ ] T037 [US10] Lock screen, PIN setup/change, biometrics, lockout, re-lock timer, privacy overlay, forgot PIN in lib/features/lock/
- [ ] T038 [US12] Settings tab + General/Profile/Security screens in lib/features/settings/
- [ ] T039 [US10] Lock + onboarding widget tests in test/features/

## Phase 5: Transactions [US1, US2]

- [ ] T040 [US1] Transaction form sheet: tabs, amount keypad/calculator, category grid + all-categories sheet + inline create, account pickers, transfer to-amount + rate prompt, date/time, payee autocomplete, note, tags, attachments, repeat editor, advanced debt/goal, validation, save/save&add/undo/duplicate/delete, recurring edit scope in lib/features/transaction_form/
- [ ] T041 [US2] Attachment service (pick, compress, hash, store, delete, preview) in lib/features/transaction_form/attachments/
- [ ] T042 [US2] All transactions: search (FTS + amount ops, debounce), filter sheet, chips, footer totals, paging 50, grouped, multi-select bulk actions, CSV of selection in lib/features/transactions/
- [ ] T043 [US1] Transaction form widget tests (validation, calculator, save) in test/features/transaction_form_test.dart

## Phase 6: Accounts, categories, tags, rates [US3, US12]

- [ ] T044 [US3] Accounts list (reorder, archived section, totals), form, detail (6-month chart, reconcile, transfer, archive, delete rules) in lib/features/accounts/
- [ ] T045 [US12] Categories tree tabs, reorder, form (icon/color pickers), delete re-assign/archive, merge in lib/features/categories/
- [ ] T046 [P] [US12] Tags management in lib/features/tags/
- [ ] T047 [P] [US12] Exchange rates screen (pairs, history, add) + base currency change guard in lib/features/rates/

## Phase 7: Home tab [US4]

- [ ] T048 [US4] Home header (avatar, month picker, bell dot, balance, delta, eye), Your Money cards, pending card, insight pill, budget rings snapshot, transactions grouped + pinned/history + period chip, pull-to-refresh, empty state in lib/features/home/
- [ ] T049 [US4] Home widget tests (empty + populated) in test/features/home_test.dart

## Phase 8: Report tab [US5]

- [ ] T050 [US5] Report: period picker, toggles, donut (tap/tooltip/scroll), bar variant, category list, cash flow, stats, by tag/account, insights list, view-as-table in lib/features/report/
- [ ] T051 [US5] Category detail screen in lib/features/report/category_detail/
- [ ] T052 [US5] CSV + PDF report export in lib/features/report/export/

## Phase 9: Plan tab [US6, US7, US8, US9]

- [ ] T053 Plan screen with "+" chooser, goals carousel, budgets list, recurring, debts sections in lib/features/plan/
- [ ] T054 [US7] Goals list/detail/form/contribution/withdraw/confetti in lib/features/goals/
- [ ] T055 [US6] Budgets list/detail/form + alert checks after writes in lib/features/budgets/
- [ ] T056 [US8] Recurring list/editor/actions + pending confirm flow in lib/features/recurring/
- [ ] T057 [US9] Debts tabs/detail/form/payments/settle in lib/features/debts/
- [ ] T058 Ring color + goal banner widget tests in test/widgets/

## Phase 10: Notifications [US13]

- [ ] T059 [US13] NotificationScheduler (channels, permission, zoned scheduling, iOS 64 cap, hide amounts) in lib/domain/services/notification_scheduler.dart + platform adapter
- [ ] T060 [US13] Notification center screen + bell dot + tap routing in lib/features/notifications/
- [ ] T061 [US13] Settings › Notifications (toggles, daily time, test, denied state)

## Phase 11: Backup / restore / CSV / delete all [US11]

- [ ] T062 [US11] BackupService (zip, manifest, sha256, AES-GCM/PBKDF2, rotation, safety backup, restore swap+migrate) in lib/domain/services/backup_service.dart
- [ ] T063 [US11] CsvService export/import planning in lib/domain/services/csv_service.dart
- [ ] T064 [US11] Backup & Data screens: backup now (+password, share), auto backup, restore flow with preview, CSV export, CSV import wizard (5 steps), delete all in lib/features/backup/
- [ ] T065 [US11] Backup + CSV round-trip tests in test/domain/

## Phase 12: Home screen widgets [US14]

- [ ] T066 [US14] home_widget sync service + Android small/medium widgets (Kotlin + XML) + iOS WidgetKit source + deep link floos://add

## Phase 13: Polish

- [ ] T067 Motion per design.md §1.7 (fade-through tabs, donut sweep, progress animations, FAB scale, balance tween) with reduced-motion
- [ ] T068 Haptics, semantics labels, 44×44 targets, text scale 1.3 QA
- [ ] T069 Debug-only 10k demo generator + performance pass
- [ ] T070 Android manifest (permissions, no INTERNET in release, FileProvider, widget receivers, FLAG_SECURE option), iOS Info.plist usage strings, launcher icons, native splash
- [ ] T071 Diagnostics: global error handlers, error_log, viewer + export

## Phase 14: Testing completion

- [ ] T072 Golden tests key components light/dark in test/goldens/
- [ ] T073 Integration test onboarding → expense → Home → budget alert → backup → wipe → restore in integration_test/app_flow_test.dart
- [ ] T074 Coverage check domain ≥ 90%

## Phase 15: Docs

- [ ] T075 README.md (setup, architecture, tests, backups), DECISIONS.md, PROGRESS.md (all ticked)
- [ ] T076 Final DoD verification (analyze, tests, grep gate, release APK permissions)

## Dependencies

Phase 1 → 2 → 3 → (4..12 in order; 6 may overlap 5) → 13 → 14 → 15.
US1 (P1) is the MVP after Phase 5; all stories are required for Definition of Done.
