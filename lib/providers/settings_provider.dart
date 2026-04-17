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

  SettingsState({
    required this.isNotificationsEnabled,
    required this.isInsightDismissed,
  });

  SettingsState copyWith({
    bool? isNotificationsEnabled,
    bool? isInsightDismissed,
  }) {
    return SettingsState(
      isNotificationsEnabled: isNotificationsEnabled ?? this.isNotificationsEnabled,
      isInsightDismissed: isInsightDismissed ?? this.isInsightDismissed,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences _prefs;

  static const _notificationsKey = 'notifications_enabled';
  static const _insightKey = 'insight_dismissed';

  SettingsNotifier(this._prefs)
      : super(SettingsState(
          isNotificationsEnabled: _prefs.getBool(_notificationsKey) ?? false,
          isInsightDismissed: _prefs.getBool(_insightKey) ?? false,
        ));

  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs.setBool(_notificationsKey, value);
    state = state.copyWith(isNotificationsEnabled: value);
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
