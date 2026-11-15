# Contract: Routes & Screens (UI contract)

Shell (`StatefulShellRoute`, bottom nav per design.md §2, FAB opens transaction sheet):

| Path | Screen | Notes |
|---|---|---|
| `/home` | Home (design.md §4.1) | tab 0 |
| `/report?type=expense|income` | Report (§4.2) | tab 1 |
| `/plan` | My Plan (§4.3) | tab 2 |
| `/settings` | Settings (§4.5) | tab 3 |

Full-screen routes (above shell):

| Path | Screen |
|---|---|
| `/onboarding` | 4-step onboarding |
| `/lock` | Lock screen |
| `/transactions?filter=…` | All transactions (search, filters, bulk) |
| `/accounts`, `/accounts/:id`, `/accounts/new`, `/accounts/:id/edit` | Accounts list/detail/form |
| `/categories`, `/categories/:id/edit`, `/categories/new?kind=`, `/categories/merge` | Categories |
| `/tags` | Tags management |
| `/rates` | Exchange rates |
| `/report/category/:id?period=` | Category detail |
| `/goals`, `/goals/:id`, `/goals/new`, `/goals/:id/edit` | Goals |
| `/budgets`, `/budgets/:id`, `/budgets/new`, `/budgets/:id/edit` | Budgets |
| `/recurring`, `/recurring/:id/edit`, `/recurring/new` | Recurring & bills |
| `/debts`, `/debts/:id`, `/debts/new`, `/debts/:id/edit` | Debts & loans |
| `/notifications` | Notification center |
| `/settings/general`, `/settings/notifications`, `/settings/security`, `/settings/backup`, `/settings/about`, `/settings/diagnostics`, `/settings/currency` | Settings sub-screens |
| `/backup/restore`, `/backup/import-csv` | Restore flow, CSV import wizard |
| `/add?type=` | Opens Home + transaction sheet (deep link `floos://add`) |

Bottom sheets: transaction form, period picker, filter sheet, category picker, account picker,
icon picker, color picker, plan "+" chooser, confirm-pending editor, contribution form, debt payment.

Redirect order: `!onboarding_done → /onboarding`; `lock_enabled && locked → /lock`; else target.
