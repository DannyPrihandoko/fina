import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/streak_service.dart';
import 'settings_provider.dart';

final streakServiceProvider = Provider((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StreakService(prefs);
});

final streakProvider = StateProvider<int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final storedStreak = prefs.getInt('streak_count') ?? 0;
  final lastLoggedEpoch = prefs.getInt('last_logged_date');
  if (storedStreak == 0 || lastLoggedEpoch == null) return storedStreak;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final lastLoggedRaw = DateTime.fromMillisecondsSinceEpoch(lastLoggedEpoch);
  final lastLogged = DateTime(lastLoggedRaw.year, lastLoggedRaw.month, lastLoggedRaw.day);
  final diffDays = today.difference(lastLogged).inDays;

  // Cocok dengan logika live di FinaWidgetProvider.kt: streak dianggap putus begitu
  // lebih dari 1 hari berlalu sejak aktivitas terakhir. Tanpa ini, StreakBadge di
  // dashboard tetap menampilkan angka lama sampai user mencatat transaksi baru,
  // padahal widget Android sudah benar menampilkan 0.
  return diffDays > 1 ? 0 : storedStreak;
});
