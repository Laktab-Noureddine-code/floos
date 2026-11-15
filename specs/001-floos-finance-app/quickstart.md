# Quickstart & Validation: Floos

## Prerequisites
Flutter stable (3.47+), Android SDK 36, JDK 21; Xcode 16+ on macOS for iOS. Linux host needs
`libsqlite3-dev` (FTS5) and `libsecret`/GTK for the desktop test runner.

## Setup
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

## Validate
```bash
flutter analyze                      # expect: No issues found!
flutter test                         # unit + DAO + migration + widget + golden
flutter test --coverage && lcov --summary coverage/lcov.info   # domain ≥ 90%
flutter test integration_test -d linux     # full flow (or -d <android-device>)
grep -rnE "TODO|FIXME|UnimplementedError|coming soon" lib/ ; echo "expect no output"
flutter build apk --release --obfuscate --split-debug-info=build/symbols
aapt dump permissions build/app/outputs/flutter-apk/app-release.apk | grep -c INTERNET   # expect 0
```

## Manual scenarios (map to spec user stories)
1. US1: fresh install → onboarding (FR, MAD, start day 25) → "+" → `45+12.5` → Food → Save → Home shows −57,50 MAD under today.
2. US3: add EUR account, rate 1 EUR = 10.8 MAD, transfer 100 EUR → balances and net worth correct.
3. US6: budget Food 2,000 → expenses to 1,640 → orange ring 82% + notification (once).
4. US7: goal 1,750 deadline +12 months → status banner states.
5. US8: monthly rule on 31st from Jan; set clock +6 months → 6 items, 1 summary notification.
6. US11: backup with password → Delete all → restore → identical data.
7. Debug menu → "Generate 10k demo transactions" → restart → Home < 1.5 s, smooth scrolling.
8. Switch AR + dark + text scale 1.3 → no overflow anywhere.
