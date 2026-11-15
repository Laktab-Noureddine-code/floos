import 'dart:convert';

import 'package:floos/core/time/clock.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:meta/meta.dart';

/// Setting keys (APP_PROMPT §4.13 + app extras).
abstract final class SettingKeys {
  static const baseCurrency = 'base_currency';
  static const locale = 'locale';
  static const themeMode = 'theme_mode';
  static const monthStartDay = 'month_start_day';
  static const weekStartDay = 'week_start_day';
  static const lockEnabled = 'lock_enabled';
  static const lockBiometrics = 'lock_biometrics';
  static const lockTimeoutSeconds = 'lock_timeout_seconds';
  static const secureFlag = 'secure_flag';
  static const autoBackupFrequency = 'auto_backup_frequency';
  static const autoBackupKeep = 'auto_backup_keep';
  static const lastBackupAt = 'last_backup_at';
  static const lastRecurringRunAt = 'last_recurring_run_at';
  static const onboardingDone = 'onboarding_done';
  static const hideAmounts = 'hide_amounts';
  static const hideAmountsDefault = 'hide_amounts_default';
  static const firstDaySeen = 'first_day_seen';
  static const displayName = 'display_name';
  static const westernDigits = 'western_digits';
  static const notifMaster = 'notif_master';
  static const notifBudget = 'notif_budget';
  static const notifBills = 'notif_bills';
  static const notifGoals = 'notif_goals';
  static const notifDebts = 'notif_debts';
  static const notifDaily = 'notif_daily';
  static const notifDailyTime = 'notif_daily_time';
  static const notifBackup = 'notif_backup';
  static const dismissedInsights = 'dismissed_insights';
  static const coachMarkSeen = 'coach_mark_seen';
}

/// Typed, immutable view of all settings with defaults.
@immutable
class AppPrefs {
  const AppPrefs(this.raw);

  static const AppPrefs defaults = AppPrefs({});

  final Map<String, String> raw;

  String _s(String k, String d) => raw[k] ?? d;
  int _i(String k, int d) => int.tryParse(raw[k] ?? '') ?? d;
  bool _b(String k, {required bool d}) => raw[k] == null ? d : raw[k] == '1';

  String get baseCurrency => _s(SettingKeys.baseCurrency, 'MAD');
  String? get locale => raw[SettingKeys.locale];

  /// `system` | `light` | `dark`.
  String get themeMode => _s(SettingKeys.themeMode, 'system');
  int get monthStartDay => _i(SettingKeys.monthStartDay, 1).clamp(1, 28);
  int get weekStartDay {
    final v = _i(SettingKeys.weekStartDay, 1);
    return const [1, 6, 7].contains(v) ? v : 1;
  }

  bool get lockEnabled => _b(SettingKeys.lockEnabled, d: false);
  bool get lockBiometrics => _b(SettingKeys.lockBiometrics, d: false);
  int get lockTimeoutSeconds {
    final v = _i(SettingKeys.lockTimeoutSeconds, 0);
    return const [0, 30, 60, 300].contains(v) ? v : 0;
  }

  bool get secureFlag => _b(SettingKeys.secureFlag, d: false);

  /// `off` | `daily` | `weekly` | `monthly`.
  String get autoBackupFrequency => _s(SettingKeys.autoBackupFrequency, 'off');
  int get autoBackupKeep => _i(SettingKeys.autoBackupKeep, 5).clamp(1, 20);
  DateTime? get lastBackupAt {
    final v = int.tryParse(raw[SettingKeys.lastBackupAt] ?? '');
    return v == null ? null : DateTime.fromMillisecondsSinceEpoch(v);
  }

  bool get onboardingDone => _b(SettingKeys.onboardingDone, d: false);
  bool get hideAmounts => _b(SettingKeys.hideAmounts, d: false);
  bool get hideAmountsDefault => _b(SettingKeys.hideAmountsDefault, d: false);
  String get displayName => _s(SettingKeys.displayName, '');

  /// Western digits (default ON, APP_PROMPT §9).
  bool get westernDigits => _b(SettingKeys.westernDigits, d: true);
  bool get notifMaster => _b(SettingKeys.notifMaster, d: true);
  bool get notifBudget => _b(SettingKeys.notifBudget, d: true);
  bool get notifBills => _b(SettingKeys.notifBills, d: true);
  bool get notifGoals => _b(SettingKeys.notifGoals, d: true);
  bool get notifDebts => _b(SettingKeys.notifDebts, d: true);
  bool get notifDaily => _b(SettingKeys.notifDaily, d: false);
  int get notifDailyTime => _i(SettingKeys.notifDailyTime, 20 * 60);
  bool get notifBackup => _b(SettingKeys.notifBackup, d: true);
  bool get coachMarkSeen => _b(SettingKeys.coachMarkSeen, d: false);

  /// Insight ids dismissed per period key.
  Map<String, List<String>> get dismissedInsights {
    try {
      final m = jsonDecode(raw[SettingKeys.dismissedInsights] ?? '{}') as Map<String, dynamic>;
      return m.map((k, v) => MapEntry(k, (v as List).cast<String>()));
    } on Object {
      return const {};
    }
  }

  @override
  bool operator ==(Object other) => other is AppPrefs && _mapEq(other.raw, raw);

  @override
  int get hashCode => Object.hashAllUnordered(raw.entries.map((e) => Object.hash(e.key, e.value)));

  static bool _mapEq(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}

/// Typed key-value settings stored in the (backed-up) database.
class SettingsRepository {
  SettingsRepository(this._db, {this._clock = const Clock()});

  final AppDatabase _db;
  final Clock _clock;

  Stream<AppPrefs> watch() => _db.settingsDao.watchAll().map(AppPrefs.new);

  Future<AppPrefs> load() async => AppPrefs(await _db.settingsDao.getAll());

  Future<void> set(String key, Object value) {
    final v = switch (value) {
      final bool b => b ? '1' : '0',
      final DateTime d => '${d.millisecondsSinceEpoch}',
      _ => '$value',
    };
    return _db.settingsDao.put(key, v, _clock.now().millisecondsSinceEpoch);
  }

  Future<void> setAll(Map<String, Object> values) => _db.transaction(() async {
    for (final e in values.entries) {
      await set(e.key, e.value);
    }
  });

  Future<void> remove(String key) => _db.settingsDao.remove(key);

  Future<void> dismissInsight(String periodKey, String insightId) async {
    final prefs = await load();
    final map = {
      // Keep only the current period to avoid unbounded growth.
      periodKey: [...?prefs.dismissedInsights[periodKey], insightId],
    };
    await set(SettingKeys.dismissedInsights, jsonEncode(map));
  }
}
