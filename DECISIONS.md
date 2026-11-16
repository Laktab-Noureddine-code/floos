# Floos — Technical decisions

- **French only** (decision 2026-11-15): one ARB (`lib/core/l10n/app_fr.arb`), no EN/AR/RTL. Seed names for other locales stay in `seed.dart` but only `fr` is used.
- **Encrypted DB**: `sqlcipher_flutter_libs` is EOL, so `sqlite3` 3.x is built from the `sqlite3mc` source (`hooks.user_defines`) and opened with `PRAGMA cipher='sqlcipher'`; the key lives in secure storage.
- **Fonts bundled** through `pubspec.yaml` instead of `google_fonts`: fully offline and deterministic tests.
- **State**: Riverpod with hand-written providers (no `riverpod_generator`) and hand-written immutable state (no `freezed`) to keep codegen time down. Only Drift uses `build_runner`.
- **Icons**: `phosphor_flutter` 2.1.0 no longer compiles with current Flutter (`IconData` is a `final class`). A local patched copy lives in `packages/phosphor_flutter` (Regular, Bold, Fill only) and is referenced by path.
- **Backups**: `data.db` is produced with `ATTACH (KEY '')` + table copy rather than `VACUUM INTO`; restore is a column-matched copy inside one transaction (older schemas migrate, newer ones are refused). A safety backup is always taken before a restore.
- **Reconcile** creates an adjustment transaction flagged `exclude_from_reports`.
- **Debts**: payments without an account are stored in `debt_payments` (record-only) and never touch balances.
- **Future-dated transactions** are excluded from totals until due (`capAt` = today).
- **Goals**: completion is sticky until the user reactivates; contributing from an account to a linked goal creates a transfer (saved = linked balance + manual contributions).
- **Ordering ties**: transactions on the same day/time are ordered by `created_at` then `rowid` so running balances are deterministic.
- **Lock**: PIN hashed with PBKDF2 (100k rounds) off the UI isolate; lockout is 30 s × failed attempts after 5; the privacy cover hides the UI when the app is inactive; `FLAG_SECURE` is toggled through the `com.floos.app/secure` method channel.
- **Android widgets**: Kotlin providers extend `HomeWidgetProvider`; data is pushed by `PlatformHomeWidgetSync`; tapping opens `floos://add`. The iOS WidgetKit source is in `ios/FloosWidget/` and needs an Xcode extension target + App Group to ship.
- **Permissions**: release builds have no `INTERNET` (only the debug manifest declares it).
