# Implementation Plan: Floos — Complete Offline Personal Finance Tracker

**Branch**: `001-floos-finance-app` | **Date**: 2026-11-15 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-floos-finance-app/spec.md`, plus normative annexes
`APP_PROMPT.md`, `design.md`, `design.png`.

## Summary

Build the entire Floos app (APP_PROMPT §1–§20) as one Flutter project: an encrypted local SQLite
(Drift + SQLCipher) data layer, a pure-Dart domain layer (money, periods, balances, budgets, goals,
recurring, debts, FX, insights, reports, CSV, backup), Riverpod controllers, go_router 4-tab shell
with a center gradient FAB, and every screen styled from design.md tokens (light/dark, French UI only).
Delivery follows APP_PROMPT §19 phases 1→15 with `flutter analyze` + `flutter test` gates per phase.

## Technical Context

**Language/Version**: Dart 3.x (Flutter 3.47 stable, Material 3)

**Primary Dependencies**: flutter_riverpod + riverpod_annotation/generator, go_router, drift +
drift_flutter + sqlcipher_flutter_libs, freezed + json_serializable, google_fonts (bundled Inter, no
runtime fetch), phosphor_flutter, fl_chart + CustomPainters, intl + gen-l10n,
flutter_local_notifications + timezone + flutter_timezone, local_auth, flutter_secure_storage,
path_provider, file_picker, share_plus, archive, csv, crypto, cryptography, image_picker,
flutter_image_compress, home_widget, pdf, printing, flutter_svg, uuid, collection,
package_info_plus, shared_preferences. Exact versions pinned in `pubspec.lock` (see research.md R1).

**Storage**: Encrypted SQLite via Drift (SQLCipher, 32-byte key in secure storage), FTS5 table for
payee/note search, attachments as JPEG files under `<appDocs>/attachments/`, backups as `.floos` zip
under `<appDocs>/backups/`; UI-only prefs in shared_preferences; secrets (DB key, PIN hash/salt) in
flutter_secure_storage.

**Testing**: flutter_test, mocktail, Drift `NativeDatabase.memory()` (host sqlite3), golden tests
(light/dark/RTL), integration_test (runs on Linux desktop host and Android device/emulator).

**Target Platform**: Android (minSdk 23+, as required by plugins) and iOS 13+; portrait phone;
tablets centered max width 600. Linux desktop target kept only as a dev/test host.

**Project Type**: mobile-app (single Flutter project).

**Performance Goals**: cold start → Home < 1.5 s with 10k transactions; 60 fps list scrolling;
search debounce 250 ms; SQL aggregations; memoized chart data per period.

**Constraints**: 100% offline, no INTERNET permission in release manifest; int minor units only;
no hard-coded colors/sizes/strings; zero analyzer issues; no TODO/placeholder.

**Scale/Scope**: ~45 screens/sheets, 16 tables + FTS, 12 domain services, 3 locales, ~600 French l10n keys.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Gate | Status |
|---|---|---|
| I Completeness | Every APP_PROMPT section maps to tasks; PROGRESS.md checklist; grep gate for TODO/placeholder | PASS |
| II Offline & Privacy | No network packages; fonts bundled; release manifest strips INTERNET; release log guard | PASS |
| III Money Correctness | `Money` (int minor) + `Currency`; rates `rate_e6`; banker's rounding; derived balances; local-day dates | PASS |
| IV Design Fidelity | `core/theme` tokens from design.md §1/§5/§7.3; shared components §3; design.md §0 fixes applied | PASS |
| V Architecture | UI→controllers→repositories→DAOs; pure-Dart `domain/services`; `Result<T, AppFailure>`; migrations + tests; very_good_analysis | PASS |
| VI UX Laws | Quick-add sheet with keypad autofocus; Undo SnackBars; empty states; haptics; 1.3× text | PASS |
| VII Data Safety | Safety backup before restore/import/wipe; transactional restore/import; rotation | PASS |
| VIII Tests | Unit/DAO/migration/widget/golden/integration suites planned per §15 + §13 | PASS |
| IX L10n & A11y | Single French ARB (gen-l10n), fr formats, Semantics, "View as table" | PASS |
| X Security | Secure-storage DB key; PBKDF2 PIN; lockout; switcher privacy; obfuscated release | PASS |

Post-design re-check (after data-model/contracts): PASS — no violations; see Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/001-floos-finance-app/
├── plan.md              # This file
├── research.md          # Phase 0 decisions
├── data-model.md        # Phase 1 schema + validation + state transitions
├── quickstart.md        # Phase 1 validation guide
├── contracts/           # Phase 1 UI/route, backup, CSV, notification, widget contracts
│   ├── routes.md
│   ├── backup-format.md
│   ├── csv-format.md
│   ├── notifications.md
│   └── domain-services.md
├── checklists/requirements.md
└── tasks.md             # /speckit-tasks output
```

### Source Code (repository root)

```text
lib/
  main.dart                     # bootstrap: error handlers, DB key, DB open, tz, notifications, ProviderScope
  app.dart                      # MaterialApp.router, themes, locale, lock gate, privacy overlay
  core/
    theme/                      # app_colors.dart, app_text.dart, tokens.dart, app_theme.dart, category_color.dart
    widgets/                    # AppCard, IconTile, MonthPicker, CircleIconButton, SegmentedToggle,
                                # ChartTypeToggle, TrendChip, LinearProgress(+hatched), RingProgress,
                                # SectionHeader, InsightPill, TransactionTile, DateGroupHeader, MoneyText,
                                # GradientFab, AppBottomNav, EmptyState, AppButton, SettingsGroup, ...
    money/                      # money.dart, currency.dart (bundled ISO table), money_formatter.dart,
                                # amount_input_parser.dart, calculator.dart
    time/                       # period.dart, period_calculator.dart, clock.dart, local_day.dart
    utils/                      # result.dart, app_failure.dart, debouncer.dart, extensions, logger
    router/                     # app_router.dart, routes.dart
    l10n/                       # app_fr.arb (+ generated)
  data/
    db/                         # app_database.dart, tables/*.dart, daos/*.dart, migrations/, seed.dart, db_key.dart
    repositories/               # accounts, categories, transactions, tags, attachments, budgets, goals,
                                # recurring, debts, rates, settings, notifications_log
  domain/
    services/                   # balance, totals, budget, goal, recurring_engine, insight_engine, report,
                                # debt, fx, backup, csv, notification_scheduler, pin_hasher, home_widget_sync
  features/
    onboarding/ lock/ home/ transactions/ transaction_form/ accounts/ categories/ report/ plan/
    goals/ budgets/ recurring/ debts/ tags/ rates/ search/ settings/ backup/ notifications/ shell/
test/
  domain/ data/ widgets/ goldens/ features/
integration_test/
  app_flow_test.dart
assets/
  fonts/ (Inter 400/500/600/700) illustrations/ (SVG)
```

**Structure Decision**: Single Flutter mobile project following APP_PROMPT §3 exactly (feature-first
clean architecture). Linux platform folder exists only to run integration tests on the dev host.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Extra `debt_payments` table for record-only payments | Spec requires "don't affect balances" payments while balances derive from transactions | Storing them as transactions would change balances; flags on transactions would pollute every total query |
| Extra `pinned` + `edited_at`-style columns on transactions | Home pinned/history toggles (APP_PROMPT §6.3) | Separate table adds joins on the hottest query |
| Linux desktop platform folder | Running integration/golden tests on dev host without device | Emulator-only testing is slow on this 4-core host |
