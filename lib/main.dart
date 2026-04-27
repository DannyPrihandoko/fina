import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fina/screens/splash_screen.dart';
import 'package:fina/theme/app_theme.dart';
import 'package:fina/services/notification_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:fina/providers/settings_provider.dart';
import 'package:fina/providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:fina/services/streak_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (!kIsWeb) {
      await StreakService.init();
    }
  } catch (e) {
    debugPrint('StreakService initialization failed: $e');
  }
  
  try {
    // Di Web, Firebase butuh konfigurasi khusus. Jika belum ada, kita skip dulu agar tidak crash.
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  
  try {
    if (!kIsWeb) {
      await NotificationService().init();
    }
  } catch (e) {
    debugPrint('Notification initialization failed: $e');
  }

  final sharedPrefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const FinaApp(),
    ),
  );
}

class FinaApp extends ConsumerWidget {
  const FinaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    
    return MaterialApp(
      title: 'fina',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
