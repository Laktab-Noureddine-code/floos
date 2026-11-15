# Contract: Notifications & Home widget

| Type | Channel id | Trigger | Body (hide_amounts ON → amounts omitted) | Payload route |
|---|---|---|---|---|
| Budget threshold | `budget_alerts` | threshold crossed in current period | "Food: 82% of 2,000 used" | `/budgets/:id` |
| Bill reminder | `bill_reminders` | next_due − N days at remind_time | "Internet 299 due Friday" | `/recurring/:id/edit` |
| Pending recurring | `pending_recurring` | item created in confirm mode | "Rent is ready to confirm" | `/home` |
| Goal milestone | `goal_milestones` | 25/50/75/100% first reached | "🎉 50% of House by the Sea" | `/goals/:id` |
| Debt due | `debt_due` | due − 1 day and due day, 09:00 | "You owe Ahmed 500 tomorrow" | `/debts/:id` |
| Daily reminder | `daily_reminder` | daily at user time (off by default) | "Log today's expenses?" | `/add` |
| Backup overdue | `backup` | 30 days since last backup (checked at start) | "Back up your data" | `/settings/backup` |
| Catch-up summary | `pending_recurring` | catch-up created > 3 items | "12 recurring items were added" | `/transactions` |

Every event is appended to `notifications_log` first (even if permission denied or toggle off for
display is the only thing skipped). IDs: deterministic ints from hash(type+entity+date) to allow
cancel/reschedule. iOS: at most 64 pending; schedule nearest first.

Home widget keys (`home_widget`): `spent_month`, `income_month`, `balance`, `top_budget`,
`hidden` (bool), `currency`; updated (debounced 1 s) after any write and on start. Small widget
"+" → `floos://add`.
