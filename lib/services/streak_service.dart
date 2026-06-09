import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  final SharedPreferences _prefs;
  
  static const String _streakKey = 'streak_count';
  static const String _lastLoggedDateKey = 'last_logged_date';
  static const String _androidWidgetName = 'FinaWidgetProvider';

  StreakService(this._prefs);

  static Future<void> init() async {
    await HomeWidget.setAppGroupId('group.com.example.fina');
  }

  Future<int> recordActivity() async {
    int currentStreak = _prefs.getInt(_streakKey) ?? 0;
    int lastLoggedEpoch = _prefs.getInt(_lastLoggedDateKey) ?? 0;
    
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime? lastLogged;
    
    if (lastLoggedEpoch != 0) {
      lastLogged = DateTime.fromMillisecondsSinceEpoch(lastLoggedEpoch);
      lastLogged = DateTime(lastLogged.year, lastLogged.month, lastLogged.day);
    }
    
    if (lastLogged == null) {
      // First time logging
      currentStreak = 1;
    } else {
      final difference = today.difference(lastLogged).inDays;
      if (difference == 1) {
        // Logged consecutive day
        currentStreak++;
      } else if (difference > 1) {
        // Missed a day
        currentStreak = 1;
      } else if (difference == 0) {
        // Already logged today, streak remains same
        currentStreak = currentStreak == 0 ? 1 : currentStreak;
      }
    }
    
    await _prefs.setInt(_streakKey, currentStreak);
    await _prefs.setInt(_lastLoggedDateKey, now.millisecondsSinceEpoch);
    
    // Send to HomeWidget
    await HomeWidget.saveWidgetData<int>('streak_count', currentStreak);
    await HomeWidget.saveWidgetData<int>('last_logged_date', now.millisecondsSinceEpoch);
    await HomeWidget.updateWidget(
      name: _androidWidgetName,
      iOSName: _androidWidgetName, // Not used but good to have
    );
    
    return currentStreak;
  }
}
