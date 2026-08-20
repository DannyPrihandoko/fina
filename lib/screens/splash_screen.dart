import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_screen.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/database_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Request notification permissions early
    _requestNotificationPermissions();

    _controller = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  Future<void> _requestNotificationPermissions() async {
    try {
      await NotificationService().requestPermissions();
    } catch (e) {
      debugPrint('SplashScreen: Notification permission request failed: $e');
    }
    
    try {
      await _checkAndAutoSync();
    } catch (e) {
      debugPrint('SplashScreen: Auto-sync failed: $e');
    }

    _navigateToHome();
  }

  Future<void> _checkAndAutoSync() async {
    try {
      final user = AuthService().currentUser;
      if (user == null || user.isAnonymous) return;

      final db = DatabaseService.instance;
      final localTx = await db.getAllTransactions();

      // If local DB is empty but user is signed in, auto-restore from cloud
      if (localTx.isEmpty) {
        final hasCloud = await CloudSyncService().isCloudDataAvailable(user.uid);
        if (!hasCloud) return;

        final result = await CloudSyncService().restoreAll(user.uid);
        if (result == null) return;

        final database = await db.database;
        await database.delete('transactions');
        await database.delete('wallets');
        await database.delete('bills');
        await database.delete('budgets');
        await database.delete('financial_goals');

        for (final w in result.wallets) { await db.createWallet(w); }
        for (final t in result.transactions) { await db.createTransaction(t); }
        for (final b in result.bills) { await db.createBill(b); }
        for (final bg in result.budgets) { await db.saveBudget(bg); }
        for (final g in result.goals) { await db.createGoal(g); }
        // Backup lama tidak punya dokumen 'categories' — jangan wipe kategori lokal
        // kalau cloud tidak punya apa-apa (lihat catatan sama di settings_screen.dart).
        if (result.categories.isNotEmpty) {
          await database.delete('categories');
          for (final c in result.categories) { await db.createCategory(c); }
        }

        debugPrint('SplashScreen: Auto-restore completed from cloud.');
      }
    } catch (e) {
      debugPrint('SplashScreen: Auto-sync error: $e');
    }
  }

  void _navigateToHome() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (_, __, ___) => const MainScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? Theme.of(context).scaffoldBackgroundColor 
          : Theme.of(context).colorScheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.05 : 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/icon/logo_apps.png',
                    fit: BoxFit.contain,
                    color: Colors.white, // Keep logo white on primary/dark background
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'FINA',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'PERSONAL CASH FLOW',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
