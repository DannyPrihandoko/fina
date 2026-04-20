import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});

class SettingsState {
  final bool isNotificationsEnabled;
  final bool isInsightDismissed;
  final bool isDarkMode;

  SettingsState({
    required this.isNotificationsEnabled,
    required this.isInsightDismissed,
    required this.isDarkMode,
  });

  SettingsState copyWith({
    bool? isNotificationsEnabled,
    bool? isInsightDismissed,
    bool? isDarkMode,
  }) {
    return SettingsState(
      isNotificationsEnabled: isNotificationsEnabled ?? this.isNotificationsEnabled,
      isInsightDismissed: isInsightDismissed ?? this.isInsightDismissed,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences _prefs;

  static const _notificationsKey = 'notifications_enabled';
  static const _insightKey = 'insight_dismissed';
  static const _darkModeKey = 'dark_mode';

  SettingsNotifier(this._prefs)
      : super(SettingsState(
          isNotificationsEnabled: _prefs.getBool(_notificationsKey) ?? false,
          isInsightDismissed: _prefs.getBool(_insightKey) ?? false,
          isDarkMode: _prefs.getBool(_darkModeKey) ?? false,
        ));

  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs.setBool(_notificationsKey, value);
    state = state.copyWith(isNotificationsEnabled: value);
  }

  Future<void> setDarkMode(bool value) async {
    await _prefs.setBool(_darkModeKey, value);
    state = state.copyWith(isDarkMode: value);
  }

  Future<void> dismissInsight() async {
    await _prefs.setBool(_insightKey, true);
    state = state.copyWith(isInsightDismissed: true);
  }

  Future<void> revealInsight() async {
    await _prefs.setBool(_insightKey, false);
    state = state.copyWith(isInsightDismissed: false);
  }
}
