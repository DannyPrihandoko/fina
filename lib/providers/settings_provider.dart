import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});

class SettingsState {
  final bool isNotificationsEnabled;
  final bool isSmartAlertsEnabled;
  final bool isInsightDismissed;
  final bool isDarkMode;
  final String languageCode;
  final String userName;
  final String? profilePhotoPath;
  final String? lastBackupStatus; // 'success' | 'failed' | null (belum pernah backup)
  final String? lastBackupAt; // ISO 8601 string

  SettingsState({
    required this.isNotificationsEnabled,
    required this.isSmartAlertsEnabled,
    required this.isInsightDismissed,
    required this.isDarkMode,
    required this.languageCode,
    required this.userName,
    this.profilePhotoPath,
    this.lastBackupStatus,
    this.lastBackupAt,
  });

  SettingsState copyWith({
    bool? isNotificationsEnabled,
    bool? isSmartAlertsEnabled,
    bool? isInsightDismissed,
    bool? isDarkMode,
    String? languageCode,
    String? userName,
    String? profilePhotoPath,
    String? lastBackupStatus,
    String? lastBackupAt,
  }) {
    return SettingsState(
      isNotificationsEnabled:
          isNotificationsEnabled ?? this.isNotificationsEnabled,
      isSmartAlertsEnabled: isSmartAlertsEnabled ?? this.isSmartAlertsEnabled,
      isInsightDismissed: isInsightDismissed ?? this.isInsightDismissed,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      languageCode: languageCode ?? this.languageCode,
      userName: userName ?? this.userName,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      lastBackupStatus: lastBackupStatus ?? this.lastBackupStatus,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences _prefs;

  static const _notificationsKey = 'notifications_enabled';
  static const _smartAlertsKey = 'smart_alerts_enabled';
  static const _insightKey = 'insight_dismissed';
  static const _darkModeKey = 'dark_mode';
  static const _languageKey = 'language_code';
  static const _userNameKey = 'user_name';
  static const _photoKey = 'profile_photo_path';
  static const _lastBackupStatusKey = 'last_backup_status';
  static const _lastBackupAtKey = 'last_backup_at';

  SettingsNotifier(this._prefs)
      : super(SettingsState(
          isNotificationsEnabled: _prefs.getBool(_notificationsKey) ?? false,
          isSmartAlertsEnabled: _prefs.getBool(_smartAlertsKey) ?? false,
          isInsightDismissed: _prefs.getBool(_insightKey) ?? false,
          isDarkMode: _prefs.getBool(_darkModeKey) ?? false,
          languageCode: _prefs.getString(_languageKey) ?? 'id',
          userName: _prefs.getString(_userNameKey) ?? 'User Fina',
          profilePhotoPath: _prefs.getString(_photoKey),
          lastBackupStatus: _prefs.getString(_lastBackupStatusKey),
          lastBackupAt: _prefs.getString(_lastBackupAtKey),
        ));

  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs.setBool(_notificationsKey, value);
    state = state.copyWith(isNotificationsEnabled: value);
  }

  Future<void> setSmartAlertsEnabled(bool value) async {
    await _prefs.setBool(_smartAlertsKey, value);
    state = state.copyWith(isSmartAlertsEnabled: value);
  }

  Future<void> setDarkMode(bool value) async {
    await _prefs.setBool(_darkModeKey, value);
    state = state.copyWith(isDarkMode: value);
  }

  Future<void> setLanguageCode(String value) async {
    await _prefs.setString(_languageKey, value);
    state = state.copyWith(languageCode: value);
  }

  Future<void> dismissInsight() async {
    await _prefs.setBool(_insightKey, true);
    state = state.copyWith(isInsightDismissed: true);
  }

  Future<void> revealInsight() async {
    await _prefs.setBool(_insightKey, false);
    state = state.copyWith(isInsightDismissed: false);
  }

  Future<void> setUserName(String name) async {
    await _prefs.setString(_userNameKey, name);
    state = state.copyWith(userName: name);
  }

  Future<void> setProfilePhoto(String? path) async {
    if (path == null) {
      await _prefs.remove(_photoKey);
    } else {
      await _prefs.setString(_photoKey, path);
    }
    state = state.copyWith(profilePhotoPath: path);
  }

  /// Dipanggil oleh [DatabaseBackupHelper] setiap kali backup otomatis ke cloud selesai,
  /// agar kegagalan backup tidak lagi sepenuhnya tersembunyi dari user (lihat Settings).
  Future<void> recordBackupResult(bool success) async {
    final status = success ? 'success' : 'failed';
    final timestamp = DateTime.now().toIso8601String();
    await _prefs.setString(_lastBackupStatusKey, status);
    await _prefs.setString(_lastBackupAtKey, timestamp);
    state = state.copyWith(lastBackupStatus: status, lastBackupAt: timestamp);
  }
}
