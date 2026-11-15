# Data Model: Floos (Phase 1)

Encrypted SQLite (Drift). Schema version **1**. `PRAGMA foreign_keys = ON`.
Every table: `id TEXT PK (uuid v4)`, `created_at INT (UTC ms)`, `updated_at INT (UTC ms)`.
Money = `INT` minor units. Dates = `INT` UTC ms of **local midnight** (Art. 3.5).

## accounts
| col | type | rules |
|---|---|---|
| name | TEXT | 1–40 chars, trimmed; unique (case-insensitive) among `archived = 0` (repo check) |
| type | TEXT | `cash`/`bank`/`card`/`savings`/`ewallet`/`other` |
| currency_code | TEXT(3) | ISO 4217 in bundled table |
| initial_balance | INT | any sign, |v| < 10^13 |
| color | TEXT | `CategoryColor` name |
| icon | TEXT | icon registry key |
| include_in_total | BOOL | default 1 |
| sort_order | INT | |
| archived | BOOL | default 0 |

## categories
| col | type | rules |
|---|---|---|
| name | TEXT | 1–30 |
| kind | TEXT | `expense`/`income` |
| parent_id | TEXT? → categories ON DELETE RESTRICT | parent must have `parent_id IS NULL` and same kind (max 1 level) |
| icon, color | TEXT | |
| sort_order | INT | |
| archived | BOOL | |
| is_system | BOOL | `Other`, `Other income`, `Balance adjustment` |
| system_key | TEXT? UNIQUE | `other_expense`, `other_income`, `adjustment` (stable lookup; not localized) |

## transactions
| col | type | rules |
|---|---|---|
| type | TEXT | `expense`/`income`/`transfer` |
| amount | INT | > 0 and < 10^13, source currency |
| account_id | TEXT → accounts RESTRICT | |
| to_account_id | TEXT? → accounts RESTRICT | required iff transfer; ≠ account_id |
| to_amount | INT? | required iff transfer and currencies differ; > 0 |
| category_id | TEXT? → categories RESTRICT | required iff expense/income; kind must match type |
| date | INT | local midnight UTC ms |
| time_of_day_minutes | INT? | 0–1439 |
| payee | TEXT? | ≤ 60 |
| note | TEXT? | ≤ 500 |
| recurring_rule_id | TEXT? → recurring_rules SET NULL | |
| debt_id | TEXT? → debts SET NULL | |
| goal_id | TEXT? → goals SET NULL | |
| is_pending | BOOL | excluded from all totals |
| exclude_from_reports | BOOL | excluded from reports/budgets, still affects balance |
| pinned | BOOL | Home "Pinned" toggle |

Indexes: `(date)`, `(account_id, date)`, `(category_id, date)`, `(type, date)`,
`(to_account_id, date)`, UNIQUE `(recurring_rule_id, date)` WHERE `recurring_rule_id IS NOT NULL`
(idempotency guard). `updated_at` drives "history" ordering.

FTS: `transactions_fts USING fts5(payee, note, content='transactions', content_rowid='rowid')` +
triggers `transactions_ai`, `transactions_ad`, `transactions_au`.

## tags / transaction_tags
`tags(name TEXT UNIQUE COLLATE NOCASE 1–30, color TEXT)`.
`transaction_tags(transaction_id → transactions CASCADE, tag_id → tags CASCADE, PK(both))`.

## attachments
`(transaction_id → transactions CASCADE, file_name, mime, size_bytes INT, sha256 TEXT)`.
File at `<appDocs>/attachments/<id>.jpg`; repository deletes file when row deleted (and on
transaction delete via pre-delete lookup).

## budgets
| col | type | rules |
|---|---|---|
| name | TEXT | default category name or localized "Overall" |
| category_id | TEXT? → categories SET NULL | null = overall (expense only) |
| include_subcategories | BOOL | default 1 |
| amount | INT | > 0, base currency |
| period | TEXT | `weekly`/`monthly`/`yearly`/`custom` |
| custom_start/custom_end | INT? | required iff custom; end ≥ start |
| rollover | BOOL | |
| alert_thresholds | TEXT | JSON int list, 1–200, default `[80,100]` |
| archived | BOOL | |
UNIQUE partial index `(coalesce(category_id,'__overall__'), period) WHERE archived = 0`.

## budget_alert_log
`(budget_id → budgets CASCADE, period_start INT, threshold INT)` UNIQUE(budget_id, period_start, threshold).

## goals
`name 1–40, target_amount INT > 0, start_date INT, deadline INT?, tracking_mode TEXT
('manual'|'linked'), linked_account_id TEXT? → accounts SET NULL, icon, color, priority INT,
status TEXT ('active'|'completed'|'archived'), completed_at INT?, celebrated BOOL,
milestones_notified TEXT (JSON list of 25/50/75/100)`.

State transitions: `active → completed` (saved ≥ target or manual "Mark complete"; sets
`completed_at`), `active|completed → archived`, `archived → active` (unarchive),
`completed → active` (if saved drops below target via withdrawal and not manually completed).
Linked account deleted → `tracking_mode = manual`, `linked_account_id = NULL`.

## goal_contributions
`(goal_id → goals CASCADE, amount INT ≠ 0 (negative = withdrawal), date INT, note TEXT?,
transaction_id TEXT? → transactions SET NULL)`.

## recurring_rules
| col | type | rules |
|---|---|---|
| name | TEXT? | display; defaults to payee/category |
| template_type, template_amount, template_account_id, template_to_account_id, template_to_amount, template_category_id, template_payee, template_note, template_tag_ids (JSON) | | same validation as transactions |
| frequency | TEXT | `daily`/`weekly`/`monthly`/`yearly` |
| interval | INT | ≥ 1 |
| by_weekday | INT? | 1–7 (Mon=1) for weekly |
| by_month_day | INT? | 1–31, clamped to month length |
| start_date | INT | |
| end_date | INT? | |
| max_occurrences | INT? | ≥ 1 |
| occurrences_count | INT | generated so far |
| next_due_date | INT | |
| mode | TEXT | `auto`/`confirm` |
| remind_days_before | INT? | 0–7 |
| remind_time_minutes | INT | default 540 |
| active | BOOL | |

Transitions: active → inactive (pause or end reached); inactive → active (resume; next due
re-computed ≥ today). Skip next: advance `next_due_date` one occurrence.

## debts
`direction ('i_owe'|'owed_to_me'), person_name 1–40, original_amount INT > 0, currency_code,
start_date, due_date?, note?, status ('open'|'settled'), settled_at?`.
Remaining = original − Σ(payments: linked transactions' amounts (converted to debt currency if
needed) + record-only `debt_payments.amount`). Remaining ≤ 0 → status `settled`.

## debt_payments (record-only)
`(debt_id → debts CASCADE, amount INT > 0, date, note?)`.

## exchange_rates
`(from_code, to_code, rate_e6 INT > 0, date INT)` UNIQUE(from_code,to_code,date).
Lookup: latest `date ≤ txDate` for (from,to); else inverse pair with `10^12 / rate_e6` half-even.

## settings
`(key TEXT PK, value TEXT, updated_at)`. Typed in `SettingsRepository`:
`base_currency`, `locale`, `theme_mode`, `month_start_day` (1–28), `week_start_day` (1|6|7),
`lock_enabled`, `lock_biometrics`, `lock_timeout_seconds` (0|30|60|300), `secure_flag`,
`auto_backup_frequency`, `auto_backup_keep` (1–20), `last_backup_at`, `last_recurring_run_at`,
`onboarding_done`, `hide_amounts`, `hide_amounts_default`, `first_day_seen`, `display_name`,
`western_digits`, `notif_master`, `notif_budget`, `notif_bills`, `notif_goals`, `notif_debts`,
`notif_daily` + `notif_daily_time`, `notif_backup`, `dismissed_insights` (JSON {periodKey:[ids]}).

## notifications_log
`(type TEXT, title TEXT, body TEXT, route TEXT, created_at, read BOOL)`; type ∈
`budget|bill|pending|goal|debt|daily|backup|summary`.

## error_log
`(created_at, kind TEXT, message TEXT, stack TEXT)` — sanitized, no personal data; capped at 500 rows.

## Derived values (never stored)
- Account balance, net worth, period totals, budget spent/available, goal saved/progress,
  debt remaining — computed by services from SQL aggregates.

## Migrations
`MigrationStrategy(onCreate: createAll + FTS + triggers + indexes, onUpgrade: stepwise
from→to, beforeOpen: foreign_keys ON)`. Schema dumps exported with `drift_dev schema dump`
into `drift_schemas/` and verified with `drift_dev` generated test helpers (v1 baseline; framework
ready for v2+).
