import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';

final streakProvider = StateProvider<int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getInt('streak_count') ?? 0;
});
