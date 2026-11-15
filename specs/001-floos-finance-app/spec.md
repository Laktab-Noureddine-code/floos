# Feature Specification: Floos — Complete Offline Personal Finance Tracker

**Feature Branch**: `001-floos-finance-app`

**Created**: 2026-11-15

**Status**: Draft

**Input**: User description: "Build the full app described in APP_PROMPT.md (all of Part B: §1–§20), with the visual design of design.md and the reference image design.png. One complete product, not split into parts."

**Language decision (2026-11-15)**: the user chose **French only**. Every mention of English,
Arabic, RTL or a language picker in the annexes is out of scope; the UI, seeded categories,
notifications, PDF and CSV headers are in French.

**Normative annexes**: `APP_PROMPT.md` (behavior, every section §1–§20), `design.md` (visuals),
`design.png` (reference image: Home · Report · My Plan). Every numbered item in those files is in
scope. This spec restates them as user journeys and testable requirements; when a detail is
omitted here, the annex value applies.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - First run and quick-add an expense (Priority: P1)

A new user opens the app (in French), picks a base currency and the day their
"month" starts, creates a first account with an opening balance, optionally sets a PIN, and lands on
Home. They tap the central "+" button, type an amount on the already-open keypad, tap a category and
save — in under 5 seconds — and immediately see the expense on Home with the balance updated.

**Why this priority**: Recording money is the core value; everything else builds on it.

**Independent Test**: Fresh install → onboarding → add expense → Home shows the transaction grouped
under today, current balance = opening − expense, Expenses card updated.

**Acceptance Scenarios**:

1. **Given** a fresh install, **When** the user completes steps 1–2 of onboarding and skips the rest,
   **Then** a "Cash" account exists, seeded categories exist in the chosen language, and Home opens
   with a coach-mark on the "+" button.
2. **Given** Home, **When** the user taps "+", types `45+12.5`, picks "Food & Groceries" and Save,
   **Then** an expense of 57.50 is stored, a "Saved · Undo" message shows for 5 s with light haptic,
   and Home lists it under today's date header with a running balance.
3. **Given** the form, **When** the amount evaluates to 0, a negative number, or ≥ 10^13 minor
   units, **Then** Save shows an inline error and nothing is stored.
4. **Given** an Expense or Income, **When** no category is chosen, **Then** an inline error appears.
5. **Given** a Transfer, **When** source and destination accounts are the same, **Then** an inline
   error appears; **When** currencies differ, **Then** a "to amount" field and a suggested rate
   appear and, if no rate exists, the user is prompted to enter one inline.
6. **Given** a saved transaction, **When** the user taps Undo within 5 s, **Then** it is removed.
7. **Given** "Save & add another", **Then** the sheet stays open keeping date and account.

---

### User Story 2 - Manage and explore transactions (Priority: P1)

The user edits, duplicates and deletes transactions; adds payee, note, tags, date/time and receipt
photos; searches and filters the full history; and performs bulk actions.

**Why this priority**: Accurate history is required for every report, budget and goal.

**Independent Test**: Create 60+ transactions, search by payee, filter by category and amount,
bulk-change category, export selection to CSV; verify totals footer and paging.

**Acceptance Scenarios**:

1. **Given** a known payee, **When** the user picks it, **Then** its last category is suggested.
2. **Given** a transaction in edit mode, **When** Delete is tapped, **Then** it is removed with Undo;
   **When** Duplicate is tapped, **Then** a copy pre-filled with today's date opens.
3. **Given** a generated recurring transaction, **When** the user edits it, **Then** they are asked
   "Only this one" or "This and future ones" and the choice is applied.
4. **Given** the All transactions screen, **When** the user types `>100`, **Then** only amounts
   greater than 100 match; `=45` matches exactly 45; text matches payee and note.
5. **Given** active filters, **Then** they appear as removable chips and a sticky footer shows
   In · Out · Net of the filtered set; the list loads in pages of 50 grouped by day.
6. **Given** a long-press, **Then** multi-select allows bulk delete, change category, change account,
   add tag, and export selection to CSV.
7. **Given** a transaction dated in the future, **Then** it shows a "Scheduled" badge and is excluded
   from "spent so far" until its date.
8. **Given** attachments, **Then** the user can add several from camera or gallery, see thumbnails
   and a full-screen preview, and they are deleted with the transaction.

---

### User Story 3 - Accounts, balances and reconciliation (Priority: P1)

The user keeps several accounts (cash, bank, card, savings, e-wallet, other) in possibly different
currencies, sees each balance and the total net worth in the base currency, reorders/archives them,
reconciles a balance, and transfers money between them.

**Why this priority**: Correct balances are the headline number of the app.

**Independent Test**: Two accounts in MAD and EUR with an entered rate; transfer between them;
reconcile one; verify per-account balances, base-currency equivalent and net worth.

**Acceptance Scenarios**:

1. **Given** accounts with `include_in_total`, **Then** Home's Current Balance = Σ their balances
   converted to base currency, with a delta vs the same day of the previous period.
2. **Given** Reconcile with a real balance that differs, **Then** a "Balance adjustment" income or
   expense for the difference is created and the balance matches.
3. **Given** an account with transactions, **When** Delete is chosen, **Then** the user must move the
   transactions to another account or delete them all after typing the account name; otherwise
   Archive is suggested. **Given** a goal linked to it, **Then** the goal switches to manual mode.
4. **Given** account detail, **Then** a 6-month balance line chart and its transactions are shown,
   with actions Edit, Reconcile, Transfer, Archive, Delete.

---

### User Story 4 - Home dashboard (Priority: P1)

Home shows (per design.md §4.1 / design.png left screen): purple gradient header with avatar
initials, custom-month picker and notifications bell; Current Balance with 50%-opacity decimals and
delta pill; eye icon toggling hidden amounts; "Your Money" Income/Expenses cards; "Needs
confirmation" card for pending recurring items; insight pill; budgets snapshot rings; transactions
of the selected period grouped by day with pinned and history toggles and "For the Period" chip;
pull-to-refresh.

**Why this priority**: The daily entry point.

**Independent Test**: Empty DB shows the empty-wallet state with "Add your first expense"; populated
DB shows all sections with correct numbers for the chosen period.

**Acceptance Scenarios**:

1. **Given** month start day 25 and today the 3rd, **Then** "this month" spans 25th of the previous
   month to the 24th of this month everywhere.
2. **Given** hide amounts ON, **Then** every amount in the app shows `•••••`.
3. **Given** pending recurring items, **Then** the user can Confirm (optionally editing amount),
   Skip, or Edit rule from the card.
4. **Given** the Income card is tapped, **Then** Report opens pre-filtered to Income.
5. **Given** the user pulls to refresh, **Then** recurring generation and insights re-run.

---

### User Story 5 - Reports and insights (Priority: P2)

Report tab (design.md §4.2 / design.png middle screen): period picker (week/month/year/custom) with
‹ ›; Expenses | Income toggle; donut ↔ bar toggle; donut with total in the center, tap a segment to
raise it with a % tooltip and scroll to its row; category list with share %, trend chip vs previous
period and progress bar; category detail; cash flow (12 months), stats, by-tag and by-account tables,
the full insight list; export as CSV or PDF.

**Why this priority**: Understanding spending is the second core value.

**Independent Test**: Seeded data across 3 months; verify totals by category roll up to parents,
trend %, cash-flow bars, stats and that PDF/CSV export produce shareable files.

**Acceptance Scenarios**:

1. **Given** a parent with subcategories, **Then** the donut shows the rolled-up parent and the
   detail shows the split.
2. **Given** spending up vs the previous period at the same day, **Then** the trend chip is red for
   expenses (green for income increases).
3. **Given** an empty period, **Then** a chart placeholder and empty state show, never a crash.
4. **Given** "View as table", **Then** chart data is shown as an accessible table.
5. **Given** insights, **Then** they follow the 8 ranked rules of APP_PROMPT §5.9, each with a tap
   action and dismissible for the current period; the top one appears in Home's pill.

---

### User Story 6 - Budgets (spending limits) (Priority: P2)

The user creates overall or per-category budgets (weekly/monthly/yearly/custom, with optional
subcategories, rollover and alert thresholds), sees rings coloured green <70%, orange 70–100%, red
>100% with the % label, remaining per day, projection, and receives one alert per threshold per
period.

**Why this priority**: Spending control is a key reason to use the app.

**Independent Test**: Budget 2,000 on Food; add expenses to 1,640 → warning ring 82% + one
notification; add more → 112% red + one notification; editing an old transaction from a past period
re-evaluates without alerting.

**Acceptance Scenarios**:

1. **Given** rollover ON, **Then** available = amount + previous period's (available − spent),
   possibly negative, computed recursively up to 12 periods back.
2. **Given** projection > available, **Then** "Projected to exceed by X" shows.
3. **Given** a budget's category is deleted, **Then** the budget is archived with a notice.
4. **Given** a budget detail, **Then** it shows available/spent/remaining, remaining per day,
   cumulative daily line vs ideal pace, last 6 periods bars with limit line, and transactions.
5. Only one active budget per (category, period) is allowed.

---

### User Story 7 - Goals (savings objectives) (Priority: P2)

The user creates goals (target, start date, optional deadline, manual or linked-account tracking,
icon, colour, priority), adds contributions or withdrawals (optionally also creating a transfer to
the linked savings account), and sees saved / target, hatched progress bar, left amount, and a status
banner: behind (with %), on track (needed/month), or reached (confetti once + notification).

**Why this priority**: Saving toward objectives is the third core value.

**Independent Test**: Goal 1,750 with deadline in 12 months, 2 months elapsed, saved 100 → "behind"
banner with correct %; contribute to 1,750 → completed, confetti once, notification.

**Acceptance Scenarios**:

1. **Given** the goal card, **Then** it reads `saved of target` with progress saved/target and left
   = target − saved (data consistent; design.md §0 issue #1 fixed).
2. **Given** no deadline, **Then** "No deadline" with average monthly contribution and estimated date.
3. **Given** milestones 25/50/75/100%, **Then** a notification fires once each.
4. Goal detail shows the cumulative contributions line with a target line and actions Add
   contribution, Withdraw, Edit, Mark complete, Archive, Delete; list filters Active/Completed/Archived.

---

### User Story 8 - Recurring items and bill reminders (Priority: P2)

The user defines recurring rules (daily/weekly/monthly/yearly every N, weekday, month-day clamped to
short months, end date or max occurrences, auto or confirm mode, reminder N days before at a time).
The app generates due items on every start/resume/refresh, idempotently, with catch-up.

**Why this priority**: Automation keeps the data complete with minimal effort.

**Independent Test**: Monthly rule on the 31st started in January; app unopened for 6 months →
exactly one transaction per month (Feb 28/29 clamped), one summary notification, no duplicates on
re-run.

**Acceptance Scenarios**:

1. **Given** confirm mode, **Then** generated items are pending, excluded from all totals, shown in
   "Needs confirmation", and a "ready to confirm" notification fires.
2. **Given** end date or max occurrences reached, **Then** the rule is deactivated.
3. **Given** the recurring list, **Then** it is sorted by next due date with an "Upcoming" (30 days)
   section, frequency text ("Every month on the 5th"), and actions Pause/Resume, Edit, Delete (keep or
   delete past items), Skip next.
4. Reminders are re-scheduled after any rule change and on start (nearest 64 on iOS).

---

### User Story 9 - Debts and loans (Priority: P3)

The user tracks "I owe" and "Owed to me" debts per person, records payments (as linked expense/income
or record-only), sees remaining, % paid, overdue flag, auto-settle at zero, and due reminders.

**Independent Test**: Debt 500 I owe Ahmed due tomorrow → reminder; pay 200 then 300 → settled.

**Acceptance Scenarios**:

1. **Given** due date passed and remaining > 0, **Then** the card shows the due date in red.
2. **Given** "don't affect balances", **Then** the payment is recorded without a transaction.
3. Two tabs with totals at the top; detail with payments, Add payment, Settle, Edit, Delete.

---

### User Story 10 - Security: app lock and privacy (Priority: P2)

The user protects the app with a 4–6 digit PIN and optional biometrics; the app re-locks after the
chosen timeout; the app switcher shows a blurred preview; "Forgot PIN" offers biometric reset or full
reset with double confirmation.

**Independent Test**: Enable PIN, background past timeout, resume → lock; 5 wrong PINs → 30 s delay,
growing with attempts.

**Acceptance Scenarios**:

1. **Given** 5+ wrong attempts, **Then** input is blocked for 30 s × attempts beyond 4.
2. **Given** biometrics enabled and supported, **Then** a biometrics button unlocks.
3. **Given** "Forgot PIN" without biometrics, **Then** the only option is reset app (wipe) after two
   confirmations.

---

### User Story 11 - Backup, restore, CSV import/export, delete all (Priority: P2)

The user backs up to a `.floos` archive (optionally password-protected), shares it, restores it on
another device, schedules automatic local backups with rotation, exports CSV (comma/semicolon, BOM),
imports CSV through a mapping wizard with duplicate detection, and deletes all data.

**Independent Test**: Backup with password → wipe → restore with password → identical data and
attachments. CSV export → import into empty DB → identical transactions.

**Acceptance Scenarios**:

1. **Given** restore/import/delete-all, **Then** a safety backup is made first.
2. **Given** a corrupted file or wrong checksum, **Then** restore is refused with a message and data
   is unchanged; any failure mid-way rolls back completely.
3. **Given** a backup from a newer schema, **Then** it is refused; from an older one, it is migrated.
4. **Given** the CSV wizard, **Then** delimiter/encoding are detected, the first 20 rows previewed,
   columns auto-mapped by EN/FR header names, date format detected, unknown categories/accounts
   mapped or created, duplicates (date+amount+payee+account) skipped or imported, dry-run summary,
   one-transaction import, and a report with row numbers for errors.
5. **Given** "Delete all data", **When** the user types DELETE, **Then** a safety backup is made,
   DB/attachments/keys are wiped, and onboarding restarts.
6. **Given** no backup for 30 days, **Then** an insight warning and a notification appear.

---

### User Story 12 - Categories, tags, exchange rates and settings (Priority: P2)

The user manages categories (expense/income tabs, one nesting level, reorder, icon picker of ~120
icons, colour swatches, delete with re-assign or archive, merge), tags, exchange rates (pairs with
history, add rate), and all settings: profile name, base currency (blocked until rates
exist for used currencies), month start day 1–28, week start day, theme, hide amounts default,
notifications, security, backup & data, about (version, licenses, privacy
statement, diagnostics log export).

**Independent Test**: Merge two categories → all transactions re-assigned; change base currency
without rates → blocked with a message; add rates → allowed.

**Acceptance Scenarios**:

1. System categories ("Other", "Other income", "Balance adjustment") cannot be deleted; "Balance
   adjustment" is hidden from pickers.
2. Seeded category names are localized at creation and never renamed by later language changes.
3. Changing the base currency warns that budgets and goals keep their amounts as-is.

---

### User Story 13 - Notifications and notification center (Priority: P3)

All alert types (budget threshold, bill reminder, pending recurring, goal milestone, debt due, daily
log reminder, backup overdue) are delivered as local notifications on separate channels and logged in
an in-app notification center with read/unread state; the bell shows a dot for unread; tapping opens
the related screen. If permission is denied, the center still logs everything and settings show an
"Open settings" link. Lock-screen notifications show no amounts when hide amounts is on.

**Independent Test**: Deny permission, cross a budget threshold → entry appears in the center, bell
dot shows, tapping opens budget detail.

---

### User Story 14 - Home screen widgets (Priority: P3)

Small widget: "Spent this month" + "+" deep-linking to the transaction form. Medium widget: spent /
income / balance + top budget as text. Refreshed after every data change; respects hide amounts.

**Independent Test**: Add an expense → widget value updates; enable hide amounts → widget masks.

---

### Edge Cases

All APP_PROMPT §13 cases are mandatory and each has a test:

1. Month start day > 28 not allowed; a Feb rule on the 30th clamps to Feb 28/29.
2. Future-dated transactions: allowed, "Scheduled" badge, excluded from spent-so-far until due.
3. DST change and time-zone travel keep grouping by local day correct.
4. Deleting a category used by a budget archives the budget with a notice.
5. Deleting an account linked to a goal switches the goal to manual.
6. Editing an old transaction re-checks that period's budgets without sending past-period alerts.
7. Base currency change with missing rates is blocked until rates are entered.
8. Restore older schema → migrate; newer → refuse with message.
9. Calculator result 0 or negative → validation error.
10. Amount ≥ 10^13 minor units → validation cap.
11. Empty DB: every screen shows its empty state; charts show placeholders.
12. 6-month recurring catch-up creates all occurrences and sends one summary notification.
13. Cross-currency transfer with missing rate → inline rate prompt.
14. Category with subcategories rolls up in the donut; detail shows the split.
15. Notification permission denied → in-app center still logs everything.

Additional: text scale 1.3× with no overflow on every screen; wrong backup password → crypto error with retry; storage full during backup → storage error;
import with malformed rows → per-row errors, valid rows imported atomically or none per user choice
of dry-run outcome.

## Requirements *(mandatory)*

### Functional Requirements

**Onboarding, lock, start sequence**

- **FR-001**: On start the app MUST: show splash, open the encrypted store, run migrations, run
  recurring generation, re-schedule notifications, run due auto-backup, then route to onboarding (if
  not done) → lock (if enabled) → Home.
- **FR-002**: Onboarding MUST have 4 steps (welcome; currency with pinned MAD, EUR, USD,
  GBP, SAR, AED, CAD, CHF and searchable ISO list + month start day 1–28 with explanation; first
  account name/type/opening balance; optional PIN + biometrics), skippable after step 2, then seed
  localized categories and show a coach-mark on "+".
- **FR-003**: Lock MUST accept a 4–6 digit PIN (salted, iterated hash outside the main store),
  biometrics when enabled, apply 30 s × attempts delay after 5 failures, re-lock after the configured
  timeout (0/30/60/300 s), show a privacy blur in the app switcher (optional secure-flag setting), and
  offer "Forgot PIN" (biometric reset or double-confirmed wipe).

**Transactions**

- **FR-010**: Users MUST be able to create expense, income and transfer transactions with amount,
  account, category (not for transfers), local date, optional time, payee (≤60), note (≤500), tags,
  attachments, recurring rule, debt link, goal contribution, exclude-from-reports flag.
- **FR-011**: The amount keypad MUST support digits, decimal separator, `+ − × ÷`, backspace,
  evaluate on save, reject results ≤ 0 or ≥ 10^13 minor units, and reject more decimals than the
  currency allows; input parsing accepts `1234.5`, `1 234,50`, `1,234.50` and Arabic-Indic digits.
- **FR-012**: The form MUST remember the last tab and last account, show top-8 most-used categories
  plus "All categories" searchable sheet with subcategories, allow inline category creation by
  long-press, inline tag creation, payee autocomplete with last-category suggestion, Today/Yesterday/
  calendar date, "Repeat" inline rule editor, collapsed advanced section (debt/goal), Save,
  Save & add another, and in edit mode Delete (Undo) and Duplicate.
- **FR-013**: Transfers MUST require different accounts; cross-currency transfers MUST capture
  `to amount` with a suggested rate (latest on or before the date) and prompt for a rate if none.
- **FR-014**: Attachments MUST be compressed to max 1600 px JPEG 80, stored in app storage with
  checksum, previewable full-screen, and deleted with their transaction.
- **FR-015**: All-transactions screen MUST provide FTS search on payee/note, amount operators
  (`=`, `>`, `<`), 250 ms debounce, filter sheet (date presets + custom, types, accounts, categories,
  tags, amount min/max, has attachment, pending only), removable filter chips, sticky In·Out·Net
  footer, pages of 50 grouped by day with day totals, multi-select bulk delete / change category /
  change account / add tag / export CSV.
- **FR-016**: Each list row MUST show the per-account running balance after the transaction; rows
  support swipe-left Delete and Edit; tap opens edit.

**Accounts, categories, tags, rates**

- **FR-020**: Accounts: create/edit (name 1–40 unique among non-archived, type, currency, initial
  balance can be negative, colour, icon, include in total), drag reorder, archive section, detail with
  6-month balance chart, reconcile, delete rules (move or delete-all with name confirmation, else
  suggest archive).
- **FR-021**: Balances MUST be derived: initial + income − expense − transfers out + transfers in
  (to amount if set), excluding pending; net worth over included accounts converted to base currency.
- **FR-022**: Categories: expense/income tabs, max one nesting level, reorder, rename, icon grid
  (~120), colour swatches, delete with re-assign or archive, merge, system categories undeletable.
- **FR-023**: Tags: create (unique name), colour, rename, delete (removes associations).
- **FR-024**: Exchange rates: manual entry per pair/date stored with 6-decimal precision; conversion
  uses latest rate on or before the transaction date, with banker's rounding.

**Home** — **FR-030**: Home MUST render every element of User Story 4 and design.md §4.1, using the
custom month period, with empty state "No transactions yet" + "Add your first expense", last ~10
items + "See all", period filter sheet, pinned (starred) first toggle, history (recently edited)
toggle, notification center entry, pull-to-refresh, and FAB-safe bottom padding.

**Report** — **FR-040**: Report MUST render every element of User Story 5 and design.md §4.2,
including donut (220 diameter, 44 stroke, 4° gaps, rounded segments, largest first, "Other" last
hatched and labelled), 6-month bar variant, category detail (total, trend, 12-month bars, subcategory
breakdown, transactions), cash flow with net line, stats (savings rate, average/day, biggest expense,
transaction count, top payee, most frequent category), by-tag and by-account tables, insights list,
and CSV/PDF export shared via the system share sheet.

**Plan** — **FR-050**: Plan MUST provide the "+" chooser (goal/budget/recurring/debt), goal carousel
+ View All, budgets list, recurring & bills list, debts & loans tabs, each with detail and form
screens per User Stories 6–9 and design.md §4.3.

- **FR-051**: Budget math: spent (category + optional subcategories, or all expenses), available =
  amount + rollover, progress, status thresholds 0.70 / 1.00, remaining/day including today,
  projection = spent / daysElapsed × daysTotal.
- **FR-052**: After any transaction save/edit/delete, affected budgets of the affected period MUST be
  re-checked; each crossed threshold without a log row inserts one and notifies — only if the period
  is the current one.
- **FR-053**: Goal math per APP_PROMPT §5.6 (manual or linked mode; on track ≥ 0.9 × expected;
  neededPerMonth rounded up with ≥1 month).
- **FR-054**: Recurring engine per APP_PROMPT §5.7: catch-up, idempotent per (rule, date),
  month-day clamping, end conditions, auto/confirm modes, single summary notification on large
  catch-up, reminders re-scheduled on change and start.
- **FR-055**: Debts per APP_PROMPT §5.8.

**Insights & reports engine** — **FR-060**: The 8 insight rules of APP_PROMPT §5.9 (plus the
"no backup in 30 days" warning) MUST be deterministic, ranked, tappable and dismissible per period.
**FR-061**: Reports per APP_PROMPT §5.10, computed by aggregate queries and memoized per period.

**Settings** — **FR-070**: Settings MUST include every group of APP_PROMPT §6.10 (Profile, General,
Accounts/Categories/Tags/Exchange rates, Notifications incl. test button and denied state, Security,
Backup & Data, About incl. licenses, privacy statement and Diagnostics log viewer/export) styled as
grouped cards per design.md §4.5.

**Notifications** — **FR-080**: The 7 notification types of APP_PROMPT §8 on separate channels,
logged in a notification center (read/unread, tap-through, bell dot), no amounts on lock screen when
hide amounts is on, goal milestones 25/50/75/100, daily reminder off by default.

**Backup/CSV** — **FR-090**: Backup archive format, password encryption, share, auto-backup with
rotation (keep 1–20; off/daily/weekly/monthly), restore validation/preview/safety-backup/atomic swap/
schema checks, CSV export (BOM, `,`/`;`, columns per APP_PROMPT §7.2, decimal point, no grouping),
CSV import wizard (5 steps per §7.3), delete all (type DELETE).

**Home widgets** — **FR-100**: Small and medium widgets per User Story 14 on Android and iOS.

**Cross-cutting**

- **FR-110**: All amounts formatted per locale with real minus sign (U+2212), optional `+` for
  income, account currency symbol, decimals at 50% opacity in hero amounts; hide-amounts masks as
  `•••••` everywhere.
- **FR-111**: French UI with all strings in the French ARB file, ICU plurals and French date/number
  formats (no language picker, no RTL).
- **FR-112**: Light and dark themes per design.md §1 and §5; motion per design.md §1.7 disabled under
  reduced motion; haptics on save/delete/toggle.
- **FR-113**: Accessibility: semantics labels on all interactive elements and amounts, ≥44×44
  targets, chart semantic summaries + "View as table", AA contrast, no overflow at 1.3× text.
- **FR-114**: Every list has an empty state (illustration, sentence, primary action); every error
  shows a friendly localized message with a recovery action; unexpected errors go to a local,
  personal-data-free diagnostics log.
- **FR-115**: Debug-only action generates 10,000 demo transactions; it does not exist in release.
- **FR-116**: Tablet layout: same layout centered with max width 600; portrait only.

### Key Entities *(include if feature involves data)*

- **Account**: named money container with type, currency, initial balance, colour, icon,
  include-in-total, order, archived. Balance is derived.
- **Category**: expense or income, optional parent (one level), icon, colour, order, archived,
  system flag.
- **Transaction**: expense/income/transfer with positive amount in source currency, accounts,
  optional to-amount, category, local date + optional time, payee, note, links to recurring rule /
  debt / goal, pending and exclude-from-reports flags; has tags and attachments.
- **Tag**, **Attachment** (receipt image metadata + checksum).
- **Budget**: overall or category limit with period, rollover, thresholds, archived;
  **Budget alert log**: one row per budget × period start × threshold.
- **Goal** (target, dates, tracking mode, linked account, priority, status) and
  **Goal contribution** (signed amount, date, note, optional transaction).
- **Recurring rule**: transaction template + schedule + mode + reminder + active.
- **Debt**: direction, person, original amount, currency, dates, note, status; payments are
  transactions or record-only payment entries.
- **Exchange rate**: from/to currency, rate ×10^6, date.
- **Setting**: typed key-value preferences (APP_PROMPT §4.13 list plus display name, Western digits,
  secure flag, notification toggles, insight dismissals).
- **Notification log entry**: type, title, body, target route, created, read.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can record an expense from Home in ≤ 5 seconds and ≤ 4 taps after typing the
  amount.
- **SC-002**: With 10,000 transactions, the app reaches Home in < 1.5 s on a mid-range device and
  lists scroll without visible jank.
- **SC-003**: 100% of balance, budget, goal, recurring, debt, insight and report rules produce exact
  results (to the minor unit) on the documented test scenarios; domain test coverage ≥ 90%.
- **SC-004**: A backup created on one device restores on another with 100% of records and
  attachments identical; CSV export → import round-trip yields identical transactions.
- **SC-005**: The app performs every function with networking fully disabled; the release build
  requests no network permission.
- **SC-006**: Every screen renders without overflow in light and dark (French) at text scale 1.0
  and 1.3.
- **SC-007**: Zero placeholder/"coming soon"/TODO occurrences in shipped code; every screen has an
  empty state and every error has a recovery action.
- **SC-008**: Static analysis reports zero issues and all unit, widget, golden and integration tests
  pass.
- **SC-009**: Budget threshold alerts fire exactly once per threshold per period; recurring catch-up
  of 6 months produces exactly one item per occurrence and one summary notification.
- **SC-010**: Visual review against design.md tokens and design.png layouts finds no deviation other
  than the intentional fixes listed in design.md §0.

## Assumptions

- "Floos" is the app name used throughout; package id `com.floos.app` (recorded in DECISIONS.md).
- Single local user per device; no sync, no accounts.
- Debt payments that "don't affect balances" are stored as record-only payment entries linked to
  the debt (documented in DECISIONS.md); payments that affect balances are transactions with
  `debt_id`.
- Pinned transactions use a `pinned` flag; "history" shows most recently edited first.
- Insight dismissals and display name are stored in settings.
- When a mandated package does not support the current toolchain, an equivalent offline package is
  used and recorded in DECISIONS.md (constitution Technology constraints).
- Device-only verifications (cold-start timing on a physical mid-range phone, release builds on real
  iOS hardware, home-widget rendering) are prepared and documented; automated checks run on the
  development host (unit/widget/golden tests, analyze, Android debug/release build where the SDK is
  available).
