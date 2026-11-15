<!--
Sync Impact Report
- Version change: 1.0.0 → 1.1.0 (MINOR: Principle IX redefined — French-only UI per user decision
  2026-11-15; EN/AR and RTL removed; l10n infrastructure kept with a single French ARB)
- Previous: template → 1.0.0 (initial ratification)
- Principles added: I Completeness · II Offline & Privacy First · III Money Correctness ·
  IV Design Fidelity · V Architecture Discipline · VI UX Laws · VII Data Safety ·
  VIII Test Discipline · IX Localization & Accessibility · X Security
- Sections added: Technology & Platform Constraints · Development Workflow & Quality Gates · Governance
- Sources: APP_PROMPT.md (Part A + §2, §9–§16, §20), design.md (all), design.png (visual reference)
- Templates: plan/spec/tasks templates read the constitution at runtime — no edits required ✅
- Deferred TODOs: none
-->

# Floos Constitution

Floos is a private, offline personal finance tracker built with Flutter + SQLite (Drift).
The full product requirements live in `APP_PROMPT.md`; the visual source of truth lives in
`design.md` and the reference image `design.png`. This constitution distills their
non-negotiable rules. When this document and any spec/plan/task disagree, this document wins.

## Core Principles

### I. Completeness (NON-NEGOTIABLE)

- The app MUST be built as **one complete, production-quality product**, not a prototype, MVP,
  or demo. Every feature, screen, state and edge case in `APP_PROMPT.md` MUST be implemented,
  wired to the database, tested and reachable from the UI.
- Forbidden in shipped code: "coming soon", disabled placeholder buttons, `TODO`, `FIXME`,
  `UnimplementedError`, placeholder text, fake/demo data in production screens. A grep for these
  MUST return zero hits in `lib/` (debug-only demo generator excluded from release is allowed).
- A feature is done only when it has: UI + state + persistence + validation + empty, loading and
  error states + l10n strings (FR) + tests.
- Ambiguity MUST NOT cause a skip: choose the most reasonable behavior, implement it, and record it
  in `DECISIONS.md`.

Rationale: the product's value is in its coverage; partial features erode trust in a money app.

### II. Offline & Privacy First (NON-NEGOTIABLE)

- The app MUST work 100% offline. No network permission in the Android release manifest, no
  analytics, no ads, no accounts, no cloud SDKs, no runtime font fetching
  (`GoogleFonts.config.allowRuntimeFetching = false`; Inter is bundled as assets).
- All data lives in a local **encrypted** SQLite database (SQLCipher). The user owns it and MUST be
  able to export, back up, restore and delete it.
- Amounts, notes, payees and any personal data MUST NOT be logged in release builds.
  The diagnostics log MUST contain no personal data.

Rationale: privacy is the core promise — "Your data never leaves your device".

### III. Money Correctness (NON-NEGOTIABLE)

- Money is stored and computed as `int` **minor units**. `double` MUST NOT be used for money in the
  DB, calculations, or state; the only exceptions are final display formatting and chart geometry.
- Amounts are stored **positive**; direction comes from `type` (`expense`/`income`/`transfer`).
- Balances are **never stored**; they derive from `initial_balance` + transactions (a cache is
  allowed only if rebuildable from source and covered by tests).
- One central `Money` class performs all arithmetic. Mixing currencies throws. Currency conversion
  uses an explicit rate stored in the DB (`rate_e6`) with **banker's rounding** to the minor unit.
- Dates are stored as **UTC ms since epoch**; a transaction date is a **local calendar day**
  (local midnight → UTC, plus optional `time_of_day_minutes`). Grouping by day/period uses the
  device local time zone and MUST stay correct across DST and time-zone changes.
- Pending and `exclude_from_reports` transactions are excluded from totals; transfers are never
  income or expense; future-dated transactions are excluded from "spent so far".

Rationale: a finance app that mis-rounds or double-counts is worse than no app.

### IV. Design Fidelity

- `design.md` is the visual source of truth (tokens, colors, typography, radii, shadows,
  components, layouts, motion); `design.png` is the reference image. Implementation MUST match
  them, including the fixes listed in design.md §0 "Issues found" (e.g. goal card `saved / target`,
  budgets = spending limits, real minus sign U+2212, locale grouping, account currency symbol,
  FAB bottom padding `navBarHeight + 40`, `#6E6E73` secondary text, labelled icon buttons).
- Widgets MUST NOT hard-code colors, sizes, or text styles; all values come from theme/token
  classes (`AppColors`, `AppText`, `AppSpace`, `AppRadius`, `AppShadows`, `CategoryColor`).
- Light **and** dark themes MUST both be complete (design.md §5).
- Screens not specified in design.md MUST reuse its shared components (§3) and tokens so they look
  native to the same app. Numbers use tabular figures; decimals are de-emphasized at 50% opacity
  where design.md specifies.

Rationale: consistency is what makes the app feel crafted and trustworthy.

### V. Architecture Discipline

- Feature-first clean architecture: UI → controllers (Riverpod) → repositories → Drift DAOs.
  Widgets MUST NOT touch the DB directly.
- Business rules (money, periods, balances, totals, budgets, goals, recurring, debts, FX, insights,
  reports, CSV, backup) live in **pure Dart services** with no Flutter imports, and are unit-tested.
- Repositories return `Result<T, AppFailure>` with failure types `validation`, `notFound`,
  `conflict`, `storage`, `crypto`, `importFormat`, `permissionDenied`.
- Every DB schema change MUST have a versioned migration and a migration test.
- `flutter analyze` MUST report **zero** issues under strict lints (`very_good_analysis` or
  `flutter_lints` + strict mode). Aggregations MUST be SQL (`SUM … GROUP BY`), not Dart loops over
  all rows. Lists MUST use builders/slivers with pagination.
- Small widgets (≈ ≤150 lines), `const` where possible, no magic numbers, doc comments on public
  services, controllers expose immutable state.

Rationale: testable pure domain + thin UI keeps a large app maintainable.

### VI. UX Laws

- Quick add in ≤ 5 seconds: FAB → amount (keypad already open) → category → Save.
- Every destructive action has a confirmation or an **Undo** SnackBar (5 s).
- Every list has an empty state: illustration/icon, one sentence, one primary action.
- No dead ends: every screen has back navigation; every error has a recovery action.
- Respect system text scaling up to 1.3× with no overflow.
- Light haptic feedback on save, delete and toggle. Touch targets ≥ 44×44.
- Validation errors appear inline (not dialogs).

Rationale: speed and forgiveness drive daily logging habits.

### VII. Data Safety

- Before restore, import, or "delete all data", the app MUST automatically create a safety backup.
- Restores and imports MUST be atomic (transaction-wrapped); on failure roll back completely and
  show the error.
- Optional automatic local backups with rotation (keep last N). Backups refuse newer schemas and
  migrate older ones. Password backups use AES-GCM with PBKDF2-HMAC-SHA256 (310k iterations).

Rationale: users' financial history is irreplaceable.

### VIII. Test Discipline

- Domain services: unit tests for every rule listed in APP_PROMPT §15, coverage ≥ 90%.
- DAO tests with in-memory Drift; migration tests v1 → latest.
- Widget tests (transaction form, Home empty/populated, ring colors, goal banners, lock screen),
  golden tests (key components in light and dark), and the integration test
  (onboarding → add expense → Home → budget alert → backup → wipe → restore → data back).
- Every edge case in APP_PROMPT §13 has a test. `flutter test` MUST be green after every phase.

Rationale: correctness claims about money must be proven, not asserted.

### IX. Localization & Accessibility

- The app ships in **French only** (user decision 2026-11-15, supersedes APP_PROMPT §1/§9 EN/AR).
  Every user-facing string lives in the ARB file `app_fr.arb` (gen-l10n) with ICU plurals; zero
  hard-coded strings in widgets, so more languages can be added later without code changes.
- Number and date formatting use the `fr` locale (`intl` `DateFormat`, e.g. "Lundi 12 janvier 2026").
- Semantics on every interactive element and chart (semantic summary + "View as table"); amounts
  read naturally by screen readers; AA contrast in both themes; never color alone (rings show %,
  amounts show signs); honor reduced motion (`MediaQuery.disableAnimations`).

Rationale: the target users are French speakers, including assistive-technology users.

### X. Security

- DB key: 32 random bytes generated on first run, stored in `flutter_secure_storage`.
- PIN: 4–6 digits, salted hash (PBKDF2 / SHA-256 × 100k) in secure storage, never in the DB;
  escalating delay after 5 wrong attempts; re-lock after `lock_timeout_seconds` in background.
- `hide_amounts` privacy mode app-wide (including notifications and home widgets); app-switcher
  privacy screen; optional `FLAG_SECURE`.
- Release builds are obfuscated (`--obfuscate --split-debug-info`). No `print` of personal data.

Rationale: a finance app on a phone is a high-value target.

## Technology & Platform Constraints

- Flutter stable, Dart 3, null safety, Material 3. State: `flutter_riverpod` (+ generator).
  Navigation: `go_router` with a `StatefulShellRoute` for 4 tabs (Home · Report · [FAB] · Plan ·
  Settings). DB: `drift` + SQLCipher. Models: `freezed` + `json_serializable`. Charts: `fl_chart`
  + custom painters (donut, rings, hatched bar). Icons: `phosphor_flutter`. Font: Inter bundled.
  Notifications: `flutter_local_notifications` + `timezone`. Files: `path_provider`,
  `file_picker`, `share_plus`, `archive`, `csv`, `crypto`, `cryptography`, `pdf`, `printing`.
  Home widget: `home_widget`. Testing: `flutter_test`, `mocktail`, `NativeDatabase.memory()`,
  `integration_test`.
- Where a mandated package is unavailable or incompatible with the toolchain, a functionally
  equivalent offline alternative MAY be used, and the substitution MUST be recorded in
  `DECISIONS.md`.
- Platforms: Android (minSdk ≥ 23) and iOS, portrait phone; tablets centered at max width 600.
- Performance: cold start to Home < 1.5 s with 10,000 transactions; smooth scrolling; reactive
  Drift `watch()` streams; search debounced 250 ms; chart data memoized per period; debug-only
  "Generate 10k demo transactions" action.

## Development Workflow & Quality Gates

- The whole app is delivered as **one feature specification** covering all of APP_PROMPT.md, built
  in the phase order of APP_PROMPT §19 without stopping between phases for permission.
- After every phase: `flutter analyze` (0 issues) and `flutter test` (all green); fix before moving on.
- `PROGRESS.md` tracks every feature as a checklist; `DECISIONS.md` records every ambiguity
  resolution; `README.md` documents setup, architecture, tests and backups.
- Git with conventional commits per phase (e.g. `feat(budgets): …`).
- Definition of Done = APP_PROMPT §20: all sections implemented and ticked; analyze clean; tests +
  integration tests pass; runs offline on Android/iOS release; light/dark (French) render without
  overflow at 1.0 and 1.3 text scale; 10k-row performance; cross-device backup restore; UI matches
  design.md; no TODO/FIXME/placeholder/UnimplementedError.

## Governance

- This constitution supersedes all other practices, specs, plans and tasks. `APP_PROMPT.md` and
  `design.md` are its normative annexes; any conflict between them is resolved in favor of
  APP_PROMPT for behavior and design.md for visuals, and recorded in `DECISIONS.md`.
- Amendments require: a written rationale, a version bump, and a review of dependent artifacts
  (spec, plan, tasks). Versioning: MAJOR for removed/redefined principles, MINOR for added or
  materially expanded principles/sections, PATCH for clarifications.
- Every plan MUST contain a Constitution Check gate; every review/converge pass MUST verify
  compliance with Principles I–X. Unjustified complexity is rejected.

**Version**: 1.1.0 | **Ratified**: 2026-11-15 | **Last Amended**: 2026-11-15
