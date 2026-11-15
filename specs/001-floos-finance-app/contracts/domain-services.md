# Contract: Pure Dart domain services (no Flutter imports)

| Service | Key API |
|---|---|
| `Money` | `+`, `-`, `*ratio(num, den)` (half-even), `compareTo`, `isZero`, `isNegative`, `abs`, mixed currency → `CurrencyMismatchError` |
| `MoneyFormatter` | `format(Money, {locale, signed, showPlus, westernDigits})` (U+2212), `split()` → (integerPart, decimalPart), `mask` |
| `AmountInputParser` | `parse(String, Currency) → Result<int, AppFailure>` (handles `1 234,50`, `1,234.50`, Arabic-Indic) |
| `Calculator` | `evaluate(String expr, Currency) → Result<int, AppFailure>` |
| `PeriodCalculator` | `monthPeriodFor(date, startDay)`, `weekPeriodFor(date, weekStart)`, `yearPeriodFor`, `customPeriod`; `Period.previous/next/contains/daysLeft/daysTotal/daysElapsed` |
| `FxService` | `convert(Money, to, onDate, rates) → Result<Money, AppFailure>` |
| `BalanceService` | `balance(accountId, asOf)`, `netWorth(asOf, base)`, `runningBalances(accountId)`, `reconcile(account, realBalance) → TransactionDraft` |
| `TotalsService` | `incomeExpense(period, base) → (income, expense)` |
| `BudgetService` | `evaluate(budget, period, spentProvider) → BudgetStatus{available, spent, remaining, progress, level, remainingPerDay, projection, projectedOver}`; `thresholdsToAlert(...)` |
| `GoalService` | `evaluate(goal, contributions, linkedBalance, today) → GoalStatus{saved, progress, remaining, state(onTrack/behind/completed/noDeadline), behindPct, neededPerMonth, avgMonthly, estimatedDate}` |
| `RecurringEngine` | `occurrencesDue(rule, today) → List<LocalDay>`, `nextAfter(rule, day)`, `describe(rule)`; `run(today)` (repository-backed, idempotent) |
| `DebtService` | `evaluate(debt, payments, today) → DebtStatus{remaining, pctPaid, overdue, shouldSettle}` |
| `InsightEngine` | `compute(InsightInputs) → List<Insight>` ranked; `Insight{id, kind, priority, params, route}` |
| `ReportService` | totals by category (roll-up), account, tag, payee; daily/monthly/yearly series; comparison aligned day N; stats; cash flow |
| `CsvService` | `export(rows, separator) → bytes`, `detect(bytes)`, `parse(...)`, `plan(mapping) → ImportPlan` |
| `BackupService` | `create(password?)`, `inspect(file)`, `restore(file, password)`, `rotate(keep)` |
| `PinHasher` | `hash(pin, salt)`, `verify(pin, stored)`, lockout delay `delayFor(failedAttempts)` |
