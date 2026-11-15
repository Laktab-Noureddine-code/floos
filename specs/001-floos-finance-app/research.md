# Research: Floos (Phase 0)

All Technical Context unknowns resolved. Each entry: Decision · Rationale · Alternatives.

## R1 — Package versions
- **Decision**: Use latest versions resolvable by `flutter pub add` on Flutter 3.47.9 stable;
  lock in `pubspec.lock`. Any package that fails to resolve or build is replaced by the closest
  offline equivalent and logged in `DECISIONS.md`.
- **Rationale**: Constitution "latest stable"; reproducible via lockfile.
- **Alternatives**: Hand-pinned older versions — rejected (stale, harder upgrades).

## R2 — Encrypted database
- **Decision**: Drift with `NativeDatabase.createInBackground` over `sqlcipher_flutter_libs`;
  on open run `PRAGMA key = "x'<hex>'"`, verify `PRAGMA cipher_version`, then
  `PRAGMA foreign_keys = ON`. Key: 32 random bytes (`Random.secure`) hex-encoded in
  `flutter_secure_storage` under `db_key_v1`. Tests use plain `NativeDatabase.memory()`.
- **Rationale**: Constitution II/X; drift background isolate keeps UI smooth.
- **Alternatives**: `sqlite3_flutter_libs` unencrypted (rejected: privacy), app-level field
  encryption (rejected: breaks SQL aggregation and FTS).

## R3 — Full-text search
- **Decision**: FTS5 external-content table `transactions_fts(payee, note, content='transactions',
  content_rowid='rowid')` with AFTER INSERT/UPDATE/DELETE triggers created in migration v1.
  Queries: prefix tokens (`foo*`), combined with amount operators parsed client-side
  (`=45`, `>100`, `<20`, `>=`, `<=`).
- **Rationale**: Fast search over 10k+ rows; SQLCipher ships FTS5.
- **Alternatives**: `LIKE '%x%'` (rejected: full scans).

## R4 — Money & rounding
- **Decision**: `Money(int minor, Currency)`; ratio multiplication via `BigInt` rational
  `(minor × num) / den` with round-half-even; FX uses `rate_e6` → `(minor × rate_e6 × 10^(dTo)) /
  (10^6 × 10^(dFrom))` half-even. Currency table bundled as Dart const (ISO 4217 code, symbol,
  minor digits 0/2/3, symbol position).
- **Rationale**: Exactness; constitution III.
- **Alternatives**: `decimal` package — unnecessary dependency.

## R5 — Calculator keypad
- **Decision**: Own tokenizer + shunting-yard over rational integers (minor units scaled), supporting
  `+ − × ÷`, precedence, locale decimal separator; division results rounded half-even to the
  currency minor unit at the end.
- **Rationale**: No double; deterministic tests.

## R6 — Dates and periods
- **Decision**: Store `date` = UTC ms of local midnight (`DateTime(y,m,d).millisecondsSinceEpoch`).
  Read back via `DateTime.fromMillisecondsSinceEpoch(ms)` → local `(y,m,d)`; grouping keys use
  `LocalDay(y,m,d)` value type, never `Duration(days:1)` arithmetic (DST safe). Period math uses
  calendar fields. `Clock` injectable for tests. Time-zone travel: day re-derived from stored
  local-midnight in current zone; DECISIONS documents that a day may shift if user crosses zones
  (acceptable per APP_PROMPT 3.5) — mitigated by rounding to nearest local midnight within ±14 h.
- **Alternatives**: Store `yyyymmdd` int — rejected (APP_PROMPT mandates UTC ms).

## R7 — State management
- **Decision**: Riverpod 3 with code generation (`@riverpod`); controllers are `Notifier`/
  `AsyncNotifier`; state classes with `freezed`. Streams from Drift `watch()` exposed via
  `StreamProvider`s.
- **Alternatives**: Bloc — rejected (constitution mandates Riverpod).

## R8 — Navigation
- **Decision**: go_router `StatefulShellRoute.indexedStack` with 4 branches; custom bottom nav +
  centered `GradientFab` in a `Stack`; full-screen routes above the shell for details/forms;
  transaction form as modal bottom sheet via helper. Deep links `floos://add` (home widget) and
  notification payload routes go through the router.

## R9 — Notifications
- **Decision**: flutter_local_notifications with one Android channel per type (7); `zonedSchedule`
  with `timezone` and `flutter_timezone`; exact alarms if permitted else inexact fallback; iOS cap
  64 → schedule nearest. All alerts first appended to `notifications_log`, then shown only if
  permission granted and toggle on. With hide amounts on, notification bodies omit amounts.

## R10 — Backup format & crypto
- **Decision**: Zip (`archive`) containing `manifest.json`, `data.db` (`VACUUM INTO` a temp
  plaintext file via `ATTACH ... KEY ''` export / `sqlcipher_export`), `attachments/*`. SHA-256 per
  file in manifest. Password: PBKDF2-HMAC-SHA256 310k iterations, 16-byte salt, AES-256-GCM, 12-byte
  nonce per file; manifest unencrypted except counts are fine to show in preview. Restore: verify →
  safety backup → close DB → write new DB encrypted with the device key (`sqlcipher_export`) to
  temp → atomic rename → reopen → migrate → invalidate providers.
- **Alternatives**: argon2id — `cryptography` supports it in pure Dart but slow on low-end phones;
  manifest `kdf.algo` field keeps it future-compatible.

## R11 — CSV
- **Decision**: `csv` package; export UTF-8 with BOM, `,` or `;`; import wizard detects delimiter by
  counting candidates in the first 5 lines, encoding UTF-8 (BOM-aware) with Latin-1 fallback; date
  formats auto-detected among `yyyy-MM-dd`, `dd/MM/yyyy`, `MM/dd/yyyy`, `dd.MM.yyyy`, `dd-MM-yyyy`.
  Header synonyms EN/FR (`date/Date`, `montant/amount`, `catégorie/category`, `compte/account`,
  `bénéficiaire/payee`, `note/remarque`, `type`, …).

## R12 — PDF report
- **Decision**: `pdf` package with bundled Inter TTF (and Noto Naskh Arabic for AR) to render summary
  tables; shared via `share_plus` (file) — `printing` used for preview/share where supported.

## R13 — Home widgets
- **Decision**: `home_widget` to save `spent`, `income`, `balance`, `topBudget`, `hidden` keys after
  each write (debounced 1 s); Android `AppWidgetProvider`s (small + medium) with RemoteViews XML;
  iOS WidgetKit extension source provided under `ios/FloosWidget/` with app group
  `group.com.floos.app` (requires Xcode to add the target — documented in README).
  "+" deep-links `floos://add`.

## R14 — Fonts & icons
- **Decision**: Inter 400/500/600/700 TTF bundled under `assets/fonts/` and declared in pubspec;
  `google_fonts` configured with `allowRuntimeFetching = false` and resolved from assets. Phosphor
  icons via `phosphor_flutter`; icon keys stored as strings mapped through a const registry
  (~120 entries).

## R15 — Testing on host
- **Decision**: Unit/DAO/widget/golden tests run with `flutter test` on Linux using system
  `libsqlite3` (FTS5 enabled). Golden tests load Inter from assets to avoid Ahem boxes.
  Integration test runs on Linux desktop (`flutter test integration_test -d linux`) with fakes for
  secure storage, notifications, local_auth and file pickers injected via provider overrides.

## R16 — Lint
- **Decision**: `very_good_analysis` with `public_member_api_docs` relaxed for widgets only
  (doc comments still required on services), generated files excluded.

## R17 — Settings storage
- **Decision**: Settings table (key-value) for data-relevant settings (included in backups);
  shared_preferences only for UI-only state (last tab, last account, coach-mark seen).
