# Floos — Build Status (paused 2026-11-15)

Spec Kit workflow: constitution → specify → plan → tasks are **done**; implement is **in progress**; converge is **not started**.
Source of truth: `APP_PROMPT.md`, `design.md`, `design.png`, `logo.png`, `.specify/memory/constitution.md` (v1.1.0),
`specs/001-floos-finance-app/` (spec, plan, research, data-model, contracts, quickstart, tasks).

**Language decision:** French only (no EN/AR, no RTL). All strings in `lib/core/l10n/app_fr.arb`
(add keys with `python3 tool/arb_add.py < keys.json`, then `flutter gen-l10n`).

## How to resume
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # drift codegen (~2.5 min)
flutter gen-l10n
flutter analyze lib
flutter test test/domain test/data                          # ~105 tests, all green at pause
```
Then continue with "Remaining" below, run `/speckit-implement`, then `/speckit-converge`.

## ⚠️ Known broken at pause
- `lib/features/transactions/transactions_screen.dart` imports `filter_sheet.dart` (**not written yet**) → app does not compile until it exists
  (needs `showFilterSheet(BuildContext, TxFilter) → Future<TxFilter?>` with date presets, types, accounts, categories, tags, min/max, has attachment, pending only).
- Pending small fix in the same file: cache the `repo.watch(...)` stream in state (currently re-created on each build).
- `lib/main.dart` is still the Flutter template: bootstrap/app/router not written.
- `home_screen.dart` has a leftover no-op line `if (base.code.isEmpty) const SizedBox.shrink(),` — delete it.

## Done (tasks.md IDs)
| Area | Status | Files |
|---|---|---|
| T001–T003 setup, strict lints, Inter + Noto Arabic fonts bundled, sqlite3mc (SQLCipher) via `hooks.user_defines` | ✅ | `pubspec.yaml`, `analysis_options.yaml`, `assets/fonts/` |
| Logo: app asset + generated adaptive-icon foreground & splash glyph; launcher/splash config in pubspec (generators **not run yet**) | ✅ | `assets/branding/` |
| T004–T006 design tokens light/dark, typography, shadows, theme | ✅ | `lib/core/theme/` |
| T008 Result/AppFailure, logger, streams | ✅ | `lib/core/utils/` |
| T010–T011 shared components (AppCard, IconTile, SectionHeader, CircleIconButton, PrimaryButton, PillButton, SegmentedToggle, ChartTypeToggle, TrendChip, PeriodPill, ChoicePill, LinearProgress+hatched, RingProgress, DonutChart, BarsChart, LinesChart, ChartOrTable, TransactionTile, DateGroupHeader, InsightPill, MoneyText, GradientFab, AppBottomNav, AppLogo, EmptyState/Error/Loading, sheets, settings rows), icon registry (143) | ✅ | `lib/core/widgets/` |
| T013–T018 Drift tables, DB + FTS5 + triggers + partial indexes, encrypted connection, DAOs, seed, all repositories | ✅ | `lib/data/` |
| T019–T020 repository/DAO tests | ✅ (migration test v1→vN pending once v2 exists) | `test/data/` |
| T021–T033 Money, formatter, parser, calculator, LocalDay/Period, FX, balance, totals, budget, goal, recurring, debt, insights, reports, PIN, backup (zip + AES-GCM/PBKDF2 + safety + rotation + atomic restore), CSV export/import | ✅ | `lib/core/money`, `lib/core/time`, `lib/domain/services/` |
| T034, T065 unit tests incl. §13 edge cases, backup & CSV round trips | ✅ ~105 tests | `test/domain/` |
| App services: providers, summary, insights, alerts, notification gateway (flutter_local_notifications v23) + scheduler (64 cap), app effects (budget alerts, goal milestones/auto-complete, debt auto-settle, widget refresh), home-widget sync, CSV importer | ✅ | `lib/app/` |
| T040 transaction form (keypad calculator, categories strip + inline create, accounts, cross-currency/rate prompt, payee autocomplete, tags, attachments, repeat editor, advanced debt/goal/exclude/pin, save & add another, undo, duplicate, delete, recurring edit scope) | ✅ (untested in UI) | `lib/features/transaction_form/`, `lib/features/recurring/recurring_config.dart` |
| Pickers (account, category, currency, icon, colors), period sheet, insight text, budget colors | ✅ | `lib/features/common/` |
| T048 Home tab (header, balance, delta, eye, Your Money, pending card, insight pill, budget rings, grouped transactions, pinned/history, pull-to-refresh, empty state) | ✅ (untested in UI) | `lib/features/home/` |
| T042 All transactions screen | 🟡 written, missing filter sheet | `lib/features/transactions/` |
| CSV export/share helper | ✅ | `lib/features/backup/exporters.dart` |

## Remaining (from tasks.md)
- **Bootstrap/app/router (T009, T035):** `main.dart` (initializeDateFormatting('fr'), open DB with `openAppDatabase`, AppDirs, SharedPreferences, LocalNotificationGateway, PlatformHomeWidgetSync, image compressor via flutter_image_compress 1600px/q80, provider overrides, error handlers → error_log), splash with logo, start sequence (recurring `runDue` + summary notification if >3 items, reschedule, auto-backup if due, orphan attachment cleanup), `app.dart` (MaterialApp.router fr, themes, lock gate, privacy blur on inactive, lifecycle resume → today refresh/recurring/re-lock), go_router StatefulShellRoute + routes in `contracts/routes.md`, fade-through tabs. Instantiate `appEffectsProvider` at startup (attaches hooks).
- **T036 onboarding** (4 steps: welcome w/ logo, currency + month start day, first account, PIN/biometrics; seed fr categories; coach-mark).
- **T037 lock** (PIN pad, PinHasher in isolate, lockout 30s×attempts after 5, biometrics via local_auth, forgot PIN → biometric reset or double-confirmed wipe, re-lock timeout, FLAG_SECURE option via MethodChannel).
- **T038 settings** (profile name, base currency with missing-rate block, month/week start, theme, hide amounts default, accounts/categories/tags/rates links, notifications, security, backup & data, about + licenses + privacy + diagnostics viewer/export).
- **T044–T047** accounts list/detail(6-month chart)/form/reconcile/delete flow; categories tree/reorder/edit/delete-reassign/merge; tags; exchange rates.
- **T050–T052 Report** (period nav, Expenses/Income toggle, donut↔bars, category list with trend chips, category detail, cash flow, stats, by tag/account, insights list `/insights`, CSV + PDF export with `pdf`/`printing`).
- **T053–T057 Plan** (+ chooser, goals carousel/list/detail/form/contribute/withdraw/confetti, budgets list/detail/form, recurring list/editor/pause/skip/delete, debts tabs/detail/form/payments/settle).
- **T060–T061** notification center screen, notification settings (permission/denied state, test button, daily reminder time).
- **T064** backup & data screens (backup now + password + share, auto backup, restore flow with preview + safety backup, CSV import wizard 5 steps, delete all with "DELETE").
- **T066** Android widgets (Kotlin providers + XML layouts for `FloosSmallWidgetProvider`/`FloosMediumWidgetProvider`, deep link `floos://add`), iOS WidgetKit source.
- **T067–T071 polish**: animations, haptics/semantics/1.3× text QA, debug 10k generator, AndroidManifest (no INTERNET in release, notification/exact-alarm/biometric perms, FileProvider, receivers), iOS Info.plist strings, run `flutter_launcher_icons` + `flutter_native_splash`, diagnostics.
- **T039, T043, T049, T058, T072–T074 tests**: widget tests (form, home, rings, goal banners, lock), goldens light/dark, integration test, coverage ≥ 90 %.
- **T075–T076 docs/DoD**: README, DECISIONS.md, PROGRESS.md, grep gate, release APK permission check.

## Decisions to record in DECISIONS.md
- French only (user, 2026-11-15); seed names kept in `seed.dart` (fr/en/ar maps; only fr used).
- `sqlcipher_flutter_libs` is EOL → `sqlite3` 3.x hook `source: sqlite3mc` with `PRAGMA cipher='sqlcipher'`.
- Fonts bundled via pubspec `fonts:` instead of `google_fonts` (fully offline, deterministic tests).
- Riverpod with hand-written providers (no riverpod_generator) and hand-written immutable state (no freezed) to cut codegen time.
- Backup `data.db` built by ATTACH (KEY '') + copy instead of `VACUUM INTO`; restore = column-matched copy inside one transaction (older schemas migrate, newer refused).
- Reconcile adjustments are `exclude_from_reports`; record-only debt payments use `debt_payments` table; future-dated tx excluded from totals until due (capAt today); goal completion sticky until user reactivates.
- Linked-goal contribution from an account creates a transfer (saved = linked balance + manual contributions).
