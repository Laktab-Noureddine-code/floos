# MASTER BUILD PROMPT — "Floos" Personal Finance Tracker (Flutter · Offline · SQLite)

> **How to use this file**
> 1. Put this file and `design.md` at the root of an empty folder.
> 2. Give both to your AI coding agent (Claude Code, Cursor, …) with the instruction: **"Read APP_PROMPT.md and design.md completely, then build the whole app following them. Do not stop until the Definition of Done (§20) is fully satisfied."**
> 3. "Floos" is a placeholder app name. Replace it everywhere if you want another name.

---

## PART A — THE CONSTITUTION (rules that override everything else)

You are a **senior Flutter engineer and product designer**. You are building a **complete, production-quality** personal finance app, not a prototype, MVP or demo. Every feature in this document must be fully implemented, wired to the database, tested, and reachable from the UI.

### Article 1 — Completeness
1.1 Implement **every** feature, screen, state and edge case listed here. No "coming soon", no disabled buttons, no `TODO`, no `UnimplementedError`, no fake data in production screens.
1.2 If something is ambiguous, choose the most reasonable behavior, implement it, and record the decision in `DECISIONS.md`. Do **not** skip it.
1.3 Each feature counts as done only when it has: UI + state + persistence + validation + empty, loading and error states + l10n strings + tests.

### Article 2 — Offline and privacy first
2.1 The app works **100% offline**. No network permission, no analytics, no ads, no accounts, no cloud SDKs.
2.2 All data lives in a local SQLite database on the device. The user owns it and can export, back up, restore and delete it.
2.3 Never log amounts, notes or other personal data to the console in release builds.

### Article 3 — Money correctness (non-negotiable)
3.1 **Money is stored as `int` minor units** (cents/centimes). `double` must never be used for money: not in the DB, not in calculations, not in state. The only exception is the final display formatting and chart geometry.
3.2 Amounts are always stored **positive**. The direction comes from the `type` column (`expense` / `income` / `transfer`).
3.3 **Balances are never stored.** They are always derived from `initial_balance` + transactions. (An optional cache is allowed only if it's rebuilt from source and covered by tests.)
3.4 Every currency conversion uses an explicit rate stored in the DB, with banker's rounding to the minor unit. One central `Money` class does all the arithmetic.
3.5 Dates are stored as **UTC milliseconds since epoch**, interpreted in the device's local time zone for display and period grouping. A transaction "date" is a **local calendar day** (store the local midnight converted to UTC, plus `time_of_day_minutes` if the user sets a time).

### Article 4 — Design fidelity
4.1 `design.md` is the **visual source of truth**: tokens, colors, typography, radii, shadows, components, screen layouts and motion. Implement it exactly.
4.2 No hard-coded colors, sizes or text styles in widgets. Everything comes from theme / token classes.
4.3 Light **and** dark themes, both complete.
4.4 Any screen not specified in `design.md` must reuse its components and tokens, so it looks native to the same app.

### Article 5 — Architecture discipline
5.1 Feature-first clean architecture (see §3). UI → controllers (Riverpod) → repositories → Drift DAOs. Widgets never touch the DB directly.
5.2 Business rules (balances, periods, budgets, goals, recurring, insights) live in **pure Dart services** with no Flutter imports, and they are unit-tested.
5.3 Every DB schema change has a **versioned migration** and a migration test.
5.4 `flutter analyze` has **zero** issues. Lints: `very_good_analysis` (or `flutter_lints` + strict mode).

### Article 6 — UX laws
6.1 **Quick add in ≤ 5 seconds**: FAB → amount (keypad already open) → category → Save.
6.2 Every destructive action has a **confirmation or an Undo** (a SnackBar with Undo for 5 s).
6.3 Every list has an **empty state** with an illustration/icon, one sentence, and a primary action.
6.4 No dead ends: every screen has back navigation, and every error has a recovery action.
6.5 Respect system text scaling up to 1.3× with no overflow, and support RTL (Arabic).
6.6 Haptic feedback (light) on save, delete and toggle.

### Article 7 — Data safety
7.1 Before restore, import or "delete all data", **automatically create a safety backup**.
7.2 Restores and imports are **atomic** (transaction-wrapped). On failure, roll back completely and show the error.
7.3 Optional automatic local backups with rotation (keep the last N).

### Article 8 — Working method for the agent
8.1 Build in the phase order of §19. After each phase, run `flutter analyze` and `flutter test`, fix everything, then continue. **Do not stop between phases to ask for permission.**
8.2 Keep `PROGRESS.md` updated with a checklist of every feature in this file, ticked when it's done.
8.3 At the end, produce `README.md` (setup, architecture, how to run tests, how backups work).

---

## PART B — PRODUCT SPECIFICATION

## 1. Product summary
A private, offline app to record **expenses, incomes and transfers** across multiple **accounts**, organize them in **categories** and **tags**, control spending with **budgets (limits)**, save toward **goals (objectifs)**, automate **recurring** items and **bill reminders**, track **debts/loans**, and understand money through **reports and insights**. Data is protected by an **app lock** and portable through **backup / restore / CSV**.

Supported languages: **English, French, Arabic (RTL)**. Supported platforms: **Android and iOS** (portrait phone; tablets get the same layout, centered, max width 600).

## 2. Tech stack (use the latest stable versions)
| Concern | Choice |
|---|---|
| Framework | Flutter stable, Dart 3, null safety, `useMaterial3: true` |
| State | `flutter_riverpod` + `riverpod_annotation` / `riverpod_generator` |
| Navigation | `go_router` (a `StatefulShellRoute` for the 4 tabs) |
| Database | `drift` + `drift_flutter` + `sqlcipher_flutter_libs` (encrypted DB; the key is stored in `flutter_secure_storage`) |
| Models | `freezed` + `json_serializable` |
| Fonts / Icons | `google_fonts` (Inter, bundled offline as assets; **no runtime fetching**: set `GoogleFonts.config.allowRuntimeFetching = false`) · `phosphor_flutter` |
| Charts | `fl_chart` (bar / line) + custom painters (donut, rings, hatched bar) |
| i18n | `flutter_localizations` + `intl` + `gen-l10n` (ARB files) |
| Notifications | `flutter_local_notifications` + `timezone` + `flutter_timezone` |
| Security | `local_auth`, `flutter_secure_storage` |
| Files | `path_provider`, `file_picker`, `share_plus`, `archive` (zip), `csv`, `crypto` (SHA-256), `cryptography` (AES-GCM for password backups) |
| Images | `image_picker`, `flutter_image_compress` (receipts) |
| Home widget | `home_widget` (quick-add widget + month summary) |
| Misc | `uuid`, `collection`, `package_info_plus`, `shared_preferences` (UI-only prefs) |
| Testing | `flutter_test`, `mocktail`, `drift` in-memory (`NativeDatabase.memory()`), `integration_test` |

## 3. Project structure
```
lib/
  main.dart                     # bootstrap: DB key, DB open, timezone, notifications, ProviderScope
  app.dart                      # MaterialApp.router, themes, locale, lock gate
  core/
    theme/                      # app_colors.dart, app_text.dart, tokens.dart, app_theme.dart (light/dark)
    widgets/                    # every shared component from design.md §3
    money/                      # money.dart, currency.dart, money_formatter.dart, amount_input_parser.dart
    time/                       # period.dart, period_calculator.dart, clock.dart (injectable)
    utils/                      # result.dart, debouncer.dart, extensions
    router/                     # app_router.dart, routes.dart
    l10n/                       # arb files + generated
  data/
    db/                         # app_database.dart, tables/*.dart, daos/*.dart, migrations/, seed.dart
    repositories/               # one per aggregate
  domain/
    services/                   # balance_service, budget_service, goal_service, recurring_engine,
                                # insight_engine, report_service, debt_service, fx_service,
                                # backup_service, csv_service, notification_scheduler
  features/
    onboarding/ lock/ home/ transactions/ transaction_form/ accounts/ categories/
    report/ plan/ goals/ budgets/ recurring/ debts/ tags/ search/ settings/ backup/
test/  integration_test/
assets/ fonts/ illustrations/
```

## 4. Data model (Drift)
All tables have `id TEXT PRIMARY KEY` (UUID v4), `created_at INT`, and `updated_at INT`. Use foreign keys with `PRAGMA foreign_keys = ON`. Add the indexes listed.

### 4.1 `accounts`
| col | type | notes |
|---|---|---|
| name | text (1–40) | unique among non-archived |
| type | text | `cash`, `bank`, `card`, `savings`, `ewallet`, `other` |
| currency_code | text(3) | ISO 4217 |
| initial_balance | int | minor units, can be negative (credit card) |
| color | text | a CategoryColor enum name |
| icon | text | icon key |
| include_in_total | bool | default true |
| sort_order | int | |
| archived | bool | default false |

### 4.2 `categories`
| col | type | notes |
|---|---|---|
| name | text (1–30) | |
| kind | text | `expense` or `income` |
| parent_id | text? → categories | **max 1 level** of nesting |
| icon, color | text | |
| sort_order | int | |
| archived | bool | |
| is_system | bool | for "Other" and "Adjustment", which can't be deleted |

### 4.3 `transactions`
| col | type | notes |
|---|---|---|
| type | text | `expense`, `income`, `transfer` |
| amount | int > 0 | in the **source account currency** |
| account_id | text → accounts | source account |
| to_account_id | text? → accounts | required if `transfer`; must differ from account_id |
| to_amount | int? | required if transfer between different currencies |
| category_id | text? → categories | required for expense/income; null for transfer |
| date | int | local day (see Art. 3.5) |
| time_of_day_minutes | int? | |
| payee | text? (≤ 60) | |
| note | text? (≤ 500) | |
| recurring_rule_id | text? → recurring_rules | |
| debt_id | text? → debts | |
| goal_id | text? → goals | if this transaction is a goal contribution |
| is_pending | bool | for recurring items awaiting confirmation; **excluded from all totals** |
| exclude_from_reports | bool | e.g. reimbursements |

Indexes: `(date)`, `(account_id, date)`, `(category_id, date)`, `(type, date)`.
Plus an **FTS5** virtual table `transactions_fts(payee, note)` kept in sync by triggers, for search.

### 4.4 `tags` and `transaction_tags`
`tags(name unique, color)`. `transaction_tags(transaction_id, tag_id)` has a composite PK and cascades on delete.

### 4.5 `attachments`
`(transaction_id → transactions cascade, file_name, mime, size_bytes, sha256)`. The files live in `<appDocs>/attachments/<id>.jpg`, are compressed to max 1600 px at JPEG 80, and are deleted when the row is deleted.

### 4.6 `budgets`
| col | type | notes |
|---|---|---|
| name | text | default = category name or "Overall" |
| category_id | text? | **null = overall budget** (all expenses) |
| include_subcategories | bool | default true |
| amount | int > 0 | in the base currency |
| period | text | `weekly`, `monthly`, `yearly`, `custom` |
| custom_start / custom_end | int? | for `custom` |
| rollover | bool | unused or overspent amount carries into the next period |
| alert_thresholds | text | JSON list of %, default `[80,100]` |
| archived | bool | |

Constraint: only one active budget per (category_id, period).

### 4.7 `budget_alert_log`
`(budget_id, period_start, threshold)` is unique, so each alert fires **once per period per threshold**.

### 4.8 `goals`
| col | type | notes |
|---|---|---|
| name | text | |
| target_amount | int > 0 | base currency |
| start_date | int | default today |
| deadline | int? | |
| linked_account_id | text? | optional savings account |
| icon, color | text | |
| priority | int | for sorting |
| status | text | `active`, `completed`, `archived` |
| completed_at | int? | |

### 4.9 `goal_contributions`
`(goal_id, amount int ≠ 0 (negative = withdrawal), date, note, transaction_id?)`.

### 4.10 `recurring_rules`
| col | type | notes |
|---|---|---|
| template_* | | type, amount, account_id, to_account_id, category_id, payee, note, tag ids JSON |
| frequency | text | `daily`, `weekly`, `monthly`, `yearly` |
| interval | int ≥ 1 | every N units |
| by_weekday | int? | for weekly |
| by_month_day | int? | 1–31; **clamped to the last day of short months** |
| start_date, end_date? , max_occurrences? | | |
| next_due_date | int | |
| mode | text | `auto` (create posted) or `confirm` (create pending) |
| remind_days_before | int? | bill reminder (0–7) |
| remind_time_minutes | int | default 9:00 |
| active | bool | |

### 4.11 `debts`
`(direction 'i_owe'|'owed_to_me', person_name, original_amount, currency_code, start_date, due_date?, note, status 'open'|'settled')`. Payments are transactions linked by `debt_id`. Remaining = original − Σ payments.

### 4.12 `exchange_rates`
`(from_code, to_code, rate_e6 int, date)`. The rate is stored ×1,000,000 as an int. Rates are **entered manually**. Use the latest rate on or before the transaction date; if none exists, ask the user when they create the transaction.

### 4.13 `settings` (key-value, typed in the repository)
`base_currency`, `locale`, `theme_mode`, `month_start_day (1–28)`, `week_start_day (1|6|7)`, `lock_enabled`, `lock_biometrics`, `lock_timeout_seconds (0, 30, 60, 300)`, `auto_backup_frequency (off|daily|weekly|monthly)`, `auto_backup_keep (1–20)`, `last_backup_at`, `last_recurring_run_at`, `onboarding_done`, `hide_amounts` (privacy blur), `first_day_seen`.

### 4.14 Seed data (first run, localized)
**Expense categories:** Food & Groceries, Restaurants & Cafes, Transport, Fuel, Rent / Housing, Bills & Utilities, Phone & Internet, Health, Education, Shopping, Clothing & Shoes, Entertainment, Subscriptions, Travel, Gifts & Donations, Family & Kids, Personal Care, Sport, Taxes & Fees, Other (system).
**Income categories:** Salary, Freelance, Business, Gifts, Refunds, Investments, Other income (system).
**System:** "Balance adjustment" (used by the reconcile feature, hidden from pickers).
Each category gets a fitting Phosphor icon and a CategoryColor from `design.md`.

## 5. Core business rules (pure Dart services, all unit-tested)

### 5.1 Money (`core/money`)
- `Money(int minor, Currency c)` supports `+ − ×(ratio, banker's rounding)`, comparisons, and `isZero`. Adding two different currencies throws.
- `Currency` holds the code, symbol, minor-unit digits (from a bundled table: 0, 2 or 3 digits), and symbol position.
- The formatter uses the locale and outputs: grouping, the real minus sign `−` (U+2212), and an optional `+` for income. It also has a `split()` method for the 50%-opacity decimals display.
- The input parser accepts `1234.5`, `1 234,50`, `1,234.50` and Arabic-Indic digits `١٢٣`, and rejects more decimals than the currency allows.

### 5.2 Periods (`core/time`)
- `monthPeriodFor(date, startDay)`: if `date.day >= startDay`, the period runs from `(y, m, startDay)` to `(y, m+1, startDay) − 1 day`; otherwise it starts in the previous month. `startDay` is clamped to 1–28.
- Week periods respect `week_start_day`. Yearly periods start on Jan 1.
- `previous()`, `next()`, `contains(date)`, `daysLeft(today)`, `daysTotal`.
- All "this month" UI uses the custom month period, never the calendar month.

### 5.3 Balances (`balance_service`)
`balance(account, asOf) = initial + Σ income − Σ expense − Σ transfer_out(amount) + Σ transfer_in(to_amount ?? amount)`, excluding pending items.
- Net worth = Σ balances of accounts with `include_in_total`, converted to the base currency.
- **Reconcile**: the user enters the real balance, and the app creates a "Balance adjustment" income or expense for the difference.
- A running balance after each transaction (per account) is shown in the transaction list.

### 5.4 Income and expense totals
- Transfers are **never** counted as income or expense.
- Pending and `exclude_from_reports` transactions are excluded.
- Multi-currency amounts are converted to the base currency with the rate for that date.

### 5.5 Budgets (`budget_service`)
For each budget and period:
- `spent` = Σ expenses in the category (plus subcategories if enabled), or all expenses for an overall budget.
- `available` = `amount + rolloverFromPrevious` (rollover = previous `available − spent`, can be negative; it is calculated recursively from the budget's creation, and capped at 12 periods back).
- `progress = spent / available`. Status: `<0.70 ok (green)`, `0.70–1.00 warning (orange)`, `>1.00 over (red)`.
- `remainingPerDay = max(0, available − spent) / daysLeft` (including today).
- Projection: `spent / daysElapsed × daysTotal`. If it is > available, show a "Projected to exceed by X" line.
- **Alerts**: after any transaction is saved, re-check the affected budgets. For each threshold crossed that has no row yet in `budget_alert_log`, insert a row and show a local notification right away.

### 5.6 Goals (`goal_service`)
- `saved` = Σ contributions (if `linked_account_id` is set, then saved = that account's balance plus manual contributions; let the user choose one mode per goal: **manual** or **linked**).
- `progress = saved / target` (clamped to 0–1 for the bar; show the real % in text).
- `remaining = max(0, target − saved)`.
- If there's a deadline: `expectedNow = target × elapsedDays / totalDays`.
  - `saved ≥ target` → **completed** (set `completed_at`, show a confetti animation once, and send a notification).
  - `saved ≥ expectedNow × 0.9` → **on track**.
  - otherwise → **behind**, with `behindPct = 1 − saved/expectedNow`.
  - `neededPerMonth = remaining / monthsLeft` (rounded up; months left = at least 1).
- With no deadline: show "No deadline", with the average monthly contribution and an estimated completion date.
- A contribution can optionally also create a **transfer** from account X to the linked savings account.

### 5.7 Recurring engine (`recurring_engine`)
- Runs on **every app start/resume** and from the home widget refresh: for each active rule, generate every occurrence with `next_due_date ≤ today` (catch-up), create transactions (posted or pending according to `mode`), then advance `next_due_date`.
- **Idempotent**: never create duplicates (guard with a unique key `(recurring_rule_id, date)`).
- Respects `end_date` / `max_occurrences`, and deactivates the rule after the last occurrence.
- Month-day clamping: the 31st falls on Feb 28/29.
- Pending items show in a "Needs confirmation" card on Home: **Confirm** (optionally editing the amount), **Skip**, or **Edit rule**.
- Reminders: schedule a notification at `next_due_date − remind_days_before` at `remind_time`. Re-schedule all reminders after any rule change and on app start (cap of 64 pending on iOS: keep the nearest ones).

### 5.8 Debts (`debt_service`)
Remaining, % paid, overdue flag (`due_date < today && remaining > 0`), and auto-settle when remaining reaches 0. A payment creates a linked transaction (for `i_owe`: an expense of category "Other" or a user-chosen one; for `owed_to_me`: income). The user can also choose "don't affect balances" (record only).

### 5.9 Insights (`insight_engine`)
These are deterministic rules, computed locally, ranked by priority. Show the top one in Home's `InsightPill`; the full list lives in Report → Insights.
1. Budget over 100% (critical) → "You've exceeded your Food budget by 120 MAD."
2. Budget ≥ 80% → "Food is at 86% of its limit, 14/day left."
3. Goal behind → "House by the Sea needs 210/month to stay on track."
4. Upcoming bill within 3 days → "Internet bill (299) due in 2 days."
5. Category ≥ +20% vs the same point of the previous period (compare day N to day N) → "Cafes is up 34% vs last month."
6. Unusual transaction: amount > 3× the category's median of the last 90 days.
7. Savings rate this period (if income > 0) → "You've saved 22% of your income so far 👏"
8. No transactions in 3+ days → "Don't forget to log your expenses."
Each insight has a tap action (opens the related screen) and can be dismissed for the current period.

### 5.10 Reports (`report_service`)
- Totals by category (with roll-up to the parent category), by account, by tag, and by payee.
- Time series: daily (within a period), monthly (the last 12 months), and yearly.
- Comparison vs the previous period (same length, aligned day-to-day).
- Savings rate, average daily spend, biggest expense, and the most frequent category.
- Cash flow: income vs expense per month, plus the net line.

---

## 6. Screens and flows (UI per `design.md`)

### 6.0 App start sequence
Splash (logo on `primary`) → open the encrypted DB → run migrations → run the recurring engine → re-schedule notifications → if `!onboarding_done` show Onboarding → if `lock_enabled` show Lock → Home.

### 6.1 Onboarding (4 steps, skippable after step 2)
1. Welcome: illustration, "Your money, private and offline", and a language picker (EN/FR/AR).
2. Currency: a searchable list of ISO currencies (common ones pinned on top: MAD, EUR, USD, GBP, SAR, AED, CAD, CHF) and the month start day (1–28, default 1, with an explanation: "e.g. pick 25 if you're paid on the 25th").
3. First account: name (default "Cash"), type, and opening balance.
4. Security (optional): set a PIN, and enable biometrics if the device supports them.
Finish → seed categories in the chosen language → Home, with a coach-mark on the FAB.

### 6.2 Lock screen
A 4–6 digit PIN pad (the PIN is stored as a salted SHA-256 hash in secure storage) plus a biometrics button. After 5 wrong attempts, apply an increasing delay of 30 s × attempts. The app re-locks after `lock_timeout_seconds` in the background. The app switcher shows a blurred preview of the app (Android `FLAG_SECURE` is optional via a setting).
"Forgot PIN" → explains that the data is local, and offers biometric reset if biometrics are enabled. Otherwise the only option is to reset the app (wipe the data, with a double confirmation).

### 6.3 Home tab (`design.md` §4.1, plus:)
- Header: avatar (initials, editable name in Settings), period picker (custom month), notifications bell → **Notification center** (a local list of past alerts/reminders).
- Current balance = net worth. Delta vs the same day of the previous period.
- An **eye icon** toggles `hide_amounts` (all amounts become `•••••` app-wide).
- "Your Money": an Income card and an Expenses card for the current period. "Details" → Accounts.
- **Needs confirmation** card (if any pending recurring items).
- **InsightPill** (top insight).
- **Budgets snapshot**: a horizontal list of up to 5 rings (the most-used budgets).
- **Transactions**: grouped by day for the selected period, with "Pinned" (the pin toggle shows starred transactions first) and history (recently edited). "For the Period" chip → the period filter sheet.
- Pull-to-refresh re-runs the recurring engine and the insights.

### 6.4 Transaction form (bottom sheet, `design.md` §4.4)
- Tabs: Expense / Income / Transfer. It remembers the last tab and the last account used.
- **Amount**: large display with a custom in-app keypad that supports `+ − × ÷`, so it works as a calculator (e.g. `45+12.5`), plus a backspace key. Evaluate on save.
- Category picker: a grid of the most used categories (top 8) + "All categories" → a searchable sheet with subcategories. Long-press to create one inline.
- Account picker (and the "to" account for transfers; if the currencies differ, a "to amount" field and an auto-suggested rate).
- Date (today, yesterday, calendar) and an optional time.
- Payee with autocomplete from history. Choosing a known payee **auto-suggests its last category**.
- Note, tags (chips, create inline), and attachments (camera or gallery, multiple, with thumbnails and full-screen preview).
- "Repeat" → opens the recurring rule editor inline.
- "Link to debt" / "Contribute to goal" (advanced section, collapsed by default).
- Validation: amount > 0, category is required (expense/income), and a transfer's accounts must differ. Errors appear inline in red, not in dialogs.
- Save → haptic + SnackBar "Saved · Undo". The "Save & add another" button keeps the sheet open with the same date and account.
- Edit mode: same sheet, pre-filled, with Delete (Undo) and **Duplicate** buttons.
- If the transaction belongs to a recurring rule and the user edits it, ask: "Only this one" or "This and future ones".

### 6.5 All transactions screen
- Search bar (FTS on payee and note, plus amount match `=45` / `>100`).
- Filter sheet: date range (presets: this period, last period, last 3 months, this year, custom), types, accounts, categories (multi), tags, amount min/max, "has attachment", pending only.
- Active filters show as removable chips. Totals for the filtered set appear in a sticky footer: In · Out · Net.
- Infinite scroll (pages of 50), grouped by day.
- Multi-select (long-press): bulk delete, change category, change account, add tag, export the selection to CSV.

### 6.6 Accounts
- List of accounts with icon, name, type, balance (in the account's currency, plus its base-currency equivalent if different) and a total at the top. Drag to reorder. Archived accounts are in a collapsible section.
- Account detail: balance, a 6-month balance line chart, and transactions for this account; actions: Edit, Reconcile, Transfer, Archive, Delete.
- **Delete rules**: if the account has transactions, the user must either move them to another account or delete them all (with confirmation and typing the account name). Otherwise suggest **Archive**.

### 6.7 Categories
- Tabs: Expense / Income. A tree with parents and children; drag to reorder; edit name, icon (a picker grid of ~120 Phosphor icons) and color (the CategoryColor swatches).
- Delete: if it's used, the user must pick a replacement category (re-assign) or choose Archive. System categories can't be deleted.
- Merge categories: pick a source and a target, then re-assign everything.

### 6.8 Report tab (`design.md` §4.2, plus:)
- Period picker (week / month / year / custom) with ‹ › arrows.
- Expenses | Income toggle. Donut ↔ bar toggle.
- Tapping a donut segment highlights it and scrolls the list to it. Tapping a list item opens **Category detail**: total, trend vs previous, a 12-month bar chart, subcategory breakdown, and its transactions.
- Extra sections below the category list:
  - **Cash flow**: 12-month bars for income vs expense, plus a net line.
  - **Stats**: savings rate, average/day, biggest expense, number of transactions, top payee.
  - **By tag** and **By account** tables.
  - **Insights**: the full list.
- Export button (top right): export this report as CSV, or **PDF** (a simple, well-formatted summary built with the `pdf` + `printing` packages, then shared).

### 6.9 Plan tab (`design.md` §4.3, plus:)
- The "+" button opens a choice: New goal, New budget, New recurring, or New debt.
- **Goals**: a featured card carousel, then "View All" → a list with filters Active / Completed / Archived.
  - Goal detail: big progress, status banner, needed-per-month, a contributions history chart (cumulative line + target line), and a contributions list; actions: Add contribution, Withdraw, Edit, Mark complete, Archive, Delete.
  - Goal form: name, icon, color, target, start date, deadline (optional), tracking mode (manual/linked + account), priority.
- **Budgets**: a list with rings (`design.md` §4.3, reworked).
  - Budget detail: available / spent / remaining, remaining per day, projection, a daily cumulative spending line vs an "ideal pace" line, history of the last 6 periods (bars with the limit line), and the transactions in the period.
  - Budget form: overall or category (with the subcategories toggle), amount, period, rollover, alert thresholds (chips 50/80/100/custom).
- **Recurring & Bills**: a list sorted by next due date (the next 30 days in a section "Upcoming"), each with amount, frequency text ("Every month on the 5th"), next date and mode; actions: Pause/Resume, Edit, Delete (options: keep or delete past generated items), Skip next.
- **Debts & Loans**: two tabs, "I owe" and "Owed to me", with the total at the top. Each card shows the person, remaining amount, progress, and due date (red if overdue); detail screen with payments, Add payment, Settle, Edit, Delete.

### 6.10 Settings tab (`design.md` §4.5, full)
- **Profile**: display name (for the avatar initials).
- **General**: language, base currency (changing it warns that budgets and goals keep their amounts as-is), month start day, week start day, theme (System/Light/Dark), hide amounts by default.
- **Accounts · Categories · Tags · Exchange rates** (manage screens; the rates screen lists pairs with history and an add-rate form).
- **Notifications**: master toggle, budget alerts, bill reminders, goal milestones (25/50/75/100%), daily log reminder (time picker, off by default), and a "Test notification" button. Handle permission requests and the denied state (with an "Open settings" link).
- **Security**: app lock, change PIN, biometrics, lock timeout, hide app content in the switcher.
- **Backup & Data**: Backup now · Auto backup (frequency, keep N) · Restore · Export CSV · Import CSV · Export PDF report · Delete all data.
- **About**: version, licenses (`showLicensePage`), privacy statement ("Your data never leaves your device").

### 6.11 Notification center
A local `notifications_log` table holding past alerts (budget, goal, reminder, backup), with read/unread state and a tap → the related screen. The bell shows a dot if there are unread items.

### 6.12 Home screen widget (Android + iOS)
- Small: "Spent this month" + a quick "+" that deep-links to the transaction form.
- Medium: spent / income / balance, and the top budget ring as text.
- Refresh after every DB write (through `home_widget`), and respect `hide_amounts`.

---

## 7. Backup, restore, CSV

### 7.1 Backup file `floos_backup_YYYYMMDD_HHmm.floos` (a zip)
```
manifest.json   { app: "floos", app_version, schema_version, created_at, device_locale,
                  base_currency, counts: {transactions, accounts, ...}, sha256: {db, attachments...},
                  encrypted: bool, kdf: {algo:"argon2id"|"pbkdf2", salt, iterations} }
data.db         # a consistent copy made with VACUUM INTO (decrypted copy, then encrypted with the password if one is set)
attachments/    # receipt images
```
- **Backup now** → optional password (AES-GCM, with the key derived via PBKDF2-HMAC-SHA256 at 310k iterations) → save to app storage, then the share sheet (Drive, email, files…).
- **Auto backup**: runs on app start if it's due. Saves to `<appDocs>/backups/`, rotates to keep the last N, and shows the "Last backup" date in Settings. Show a warning insight if there has been no backup for 30 days.
- **Restore**: pick a file → validate the manifest and checksums → ask for the password if it's encrypted → show a preview (date, counts) → confirm → **safety backup** → swap the DB atomically, then run migrations if the schema is older; refuse if the schema is newer than the app → restart the app state.

### 7.2 CSV export
UTF-8 with a BOM (opens correctly in Excel), with a choice of comma or semicolon separator. Columns: `date, time, type, amount, currency, account, to_account, to_amount, category, parent_category, payee, note, tags(|-separated), id`. Amounts use a decimal point and no grouping.

### 7.3 CSV import (wizard)
1. Pick a file → auto-detect the delimiter and encoding → preview the first 20 rows.
2. Column mapping UI (auto-matched by header name, in EN and FR), date format picker (with auto-detect), decimal separator, and a choice of "single signed amount column" or "separate type column".
3. Unknown categories or accounts → map them to existing ones or create new ones.
4. Duplicate detection (same date + amount + payee + account) → skip, or import anyway.
5. Dry-run summary → Import (in one transaction) → result report (imported / skipped / errors, with row numbers).

### 7.4 Delete all data
Type "DELETE" to confirm → safety backup → wipe the DB, attachments and secure keys → back to Onboarding.

---

## 8. Notifications (complete list)
| Type | Trigger | Content | Tap → |
|---|---|---|---|
| Budget threshold | crossed 80% / 100% / custom | "Food: 82% of 2,000 used" | Budget detail |
| Bill reminder | N days before the due date | "Internet 299 due Friday" | Recurring item |
| Pending recurring | the day it's created in confirm mode | "Rent is ready to confirm" | Home pending card |
| Goal milestone | 25/50/75/100% | "🎉 50% of House by the Sea" | Goal detail |
| Debt due | 1 day before + on the due date | "You owe Ahmed 500 tomorrow" | Debt detail |
| Daily reminder | user time | "Log today's expenses?" | Transaction form |
| Backup overdue | 30 days without a backup | "Back up your data" | Backup settings |
Use one Android channel per type (users can mute them individually). Notifications must show no amounts on the lock screen when `hide_amounts` is on.

## 9. Localization
- ARB files: `app_en.arb`, `app_fr.arb`, `app_ar.arb`. **Every** user-facing string is in them, with zero hard-coded strings. Use ICU plurals ("1 transaction / 3 transactions").
- Arabic: full RTL. Mirror the directional icons (back arrows, chevrons) but **not** the charts, numbers, or the progress direction meaning. Number formatting follows the locale; offer a "Use Western digits" toggle (default ON for Arabic).
- Dates use `intl` `DateFormat` per locale ("Lundi 12 janvier 2026", "الاثنين 12 يناير 2026").
- Seeded category names are localized when they're created (they're user data after that, so switching language doesn't rename them).

## 10. Accessibility
- Every interactive element has `Semantics` and a minimum target of 44×44.
- Charts expose a semantic summary plus a "View as table" toggle.
- Contrast passes AA in both themes. Never encode meaning in color alone (rings show %, amounts show signs).
- Support large text up to 1.3× (test it), screen readers (TalkBack/VoiceOver labels on amounts: "minus 354 dirhams 25"), and reduced motion.

## 11. Performance targets
- Cold start to Home in < 1.5 s on a mid-range device with 10,000 transactions.
- Every list uses `ListView.builder` / slivers with pagination. Aggregations are SQL queries (`SUM ... GROUP BY`), not Dart loops over everything.
- Reactive Drift `watch()` streams update the UI automatically; debounce search by 250 ms.
- Charts compute in a service, memoized per period.
- Provide a debug-only "Generate 10k demo transactions" action to test performance (excluded from release builds).

## 12. Error handling
- A `Result<T, AppFailure>` type in repositories. Failure types: `validation`, `notFound`, `conflict`, `storage`, `crypto`, `importFormat`, `permissionDenied`.
- UI shows a friendly localized message plus a retry action. Unexpected errors go to a local error log viewable in Settings → About → "Diagnostics" (with no personal data) and are exportable.
- Global `FlutterError.onError` and `PlatformDispatcher.instance.onError` handlers.

## 13. Edge cases you must handle (each one gets a test)
1. Month start day 31 is not allowed (max 28). A Feb rule on the 30th is clamped.
2. A transaction dated in the future: allowed, shown with a "Scheduled" badge, excluded from "spent so far" until its date arrives.
3. DST changes and time zone travel: grouping by local day stays correct.
4. Deleting a category used by budgets: the budget is archived with a notice.
5. Deleting an account linked to a goal: the goal switches to manual mode.
6. Editing an old transaction re-triggers budget checks for **that** period, without sending alerts for past periods.
7. Changing the base currency with no rate available: block the change until rates are entered for the used currencies.
8. Restoring a backup from an older schema → migrate; from a newer one → refuse with a message.
9. An amount entered with the calculator gives 0 or a negative → validation error.
10. A huge amount (≥ 10^13 minor units) → validation cap.
11. Empty DB: every screen shows its proper empty state; charts show a placeholder, not a crash.
12. Recurring catch-up after the app wasn't opened for 6 months → creates all occurrences, sends one summary notification (not 180).
13. Two transfers between accounts in different currencies with a missing rate → prompt for the rate inline.
14. Category with subcategories in the donut → roll up to the parent; the detail shows the split.
15. Notification permission denied → the in-app notification center still logs everything.

## 14. Security details
- The DB key is 32 random bytes, created on first run and stored in `flutter_secure_storage` (Keychain / Keystore).
- The PIN hash is salted SHA-256 × 100k iterations (or PBKDF2), stored in secure storage, never in the DB.
- `hide_amounts` and the app-switcher privacy screen are implemented.
- No `print` of personal data. Release builds are obfuscated (`--obfuscate --split-debug-info`).

## 15. Testing requirements
- **Unit (domain)**: Money (arithmetic, rounding, parsing, formatting in 3 locales), periods (all start days, leap years, week starts), balances (incl. transfers and multi-currency), budgets (rollover, thresholds, projections), goals (all statuses), recurring engine (all frequencies, clamping, catch-up, idempotency, end conditions), debts, insights (each rule), CSV round-trip (export → import = same data), backup round-trip (incl. password), migrations (v1 → latest).
- **DAO tests** with an in-memory Drift DB.
- **Widget tests**: transaction form (validation, calculator, save), Home with empty and populated data, budget ring colors, goal banner states, lock screen.
- **Golden tests**: the key components in light, dark and RTL.
- **Integration test**: onboarding → add expense → see it on Home → budget alert → backup → wipe → restore → data back.
- Domain-service coverage ≥ 90%.

## 16. Code quality rules
- Small widgets (≤ ~150 lines). Extract components. `const` everywhere possible.
- No business logic in widgets. Controllers expose immutable `freezed` state.
- Doc comments on all public services. Meaningful names. No magic numbers (use tokens and constants).
- Use git with conventional commits per phase (`feat(budgets): ...`).

## 17. Assets
- Bundle the Inter font (400/500/600/700).
- Simple flat **original** illustrations in the brand purple for: onboarding (3), empty states (transactions, budgets, goals, debts, recurring, search no-results), success (goal reached), and lock. They can be built as SVG with `flutter_svg`, or as `CustomPaint`.
- App icon: a purple gradient rounded square with a white wallet/coin glyph (`flutter_launcher_icons`). The splash screen uses `flutter_native_splash`.

## 18. Platform setup
- Android: minSdk 23 (or higher if required by packages), notification + exact-alarm permissions handled with fallbacks, `USE_BIOMETRIC`, `FileProvider` for sharing, home widget receiver, and the adaptive icon.
- iOS: Face ID usage description, photo/camera usage descriptions, a widget extension with an app group for `home_widget`, and file sharing via the share sheet.
- **No INTERNET permission** in the Android release manifest.

## 19. Build phases (do all of them, in order, without stopping)
1. **Foundation**: project setup, lints, packages, theme tokens (light/dark), l10n scaffolding (3 languages), router with the 4-tab shell + FAB, shared components from `design.md`.
2. **Data layer**: all Drift tables, DAOs, FTS, migrations framework, encryption, seed, repositories.
3. **Domain services**: Money, periods, balance, totals, budgets, goals, recurring, debts, FX, insights, reports, all with unit tests.
4. **Onboarding + lock + settings basics.**
5. **Transactions**: form (calculator, payees, tags, attachments), list, search, filters, bulk actions, undo.
6. **Accounts + categories + tags + exchange rates management.**
7. **Home tab** complete.
8. **Report tab** complete (donut, bars, cash flow, stats, category detail, PDF/CSV export).
9. **Plan tab**: goals, budgets, recurring & bills, debts, all with details and forms.
10. **Notifications** (all types) + notification center.
11. **Backup / restore / auto-backup / CSV import wizard / delete all.**
12. **Home screen widgets.**
13. **Polish**: animations from `design.md`, haptics, empty states, illustrations, dark mode QA, RTL QA, accessibility pass, performance pass with 10k rows.
14. **Testing completion**: widget, golden and integration tests, coverage check.
15. **Docs**: README, DECISIONS, PROGRESS (all ticked).

## 20. Definition of Done
- [ ] Every section of this file is implemented and ticked in `PROGRESS.md`.
- [ ] `flutter analyze` reports 0 issues, and `flutter test` plus the integration tests all pass.
- [ ] The app runs on Android and iOS in release mode with **no network access**.
- [ ] Light, dark, EN, FR and AR (RTL) all render with no overflow at text scale 1.0 and 1.3.
- [ ] 10k transactions: smooth scrolling and a cold start under 1.5 s.
- [ ] A backup made on one device restores perfectly on another (verified by the integration test).
- [ ] The UI matches `design.md` tokens and layouts exactly.
- [ ] No `TODO`, `FIXME`, placeholder text, or `UnimplementedError` remains (verify with a grep).
