import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fina/screens/splash_screen.dart';
import 'package:fina/theme/app_theme.dart';
import 'package:fina/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(
    const ProviderScope(
      child: FinaApp(),
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
