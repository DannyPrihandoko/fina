import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fina/screens/splash_screen.dart';
import 'package:fina/theme/app_theme.dart';
import 'package:fina/services/notification_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:fina/providers/settings_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  try {
    await NotificationService().init();
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

class FinaApp extends StatelessWidget {
  const FinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fina',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
