import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/streak_service.dart';
import 'settings_provider.dart';

final streakServiceProvider = Provider((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StreakService(prefs);
});

final streakProvider = StateProvider<int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getInt('streak_count') ?? 0;
});
