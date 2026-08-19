import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import 'settings_provider.dart';

// Export child providers so existing imports don't break
export 'budget_provider.dart';
export 'wallet_provider.dart';
export 'transaction_provider.dart';
export 'bill_provider.dart';
export 'goal_provider.dart';

final databaseServiceProvider = Provider((ref) => DatabaseService.instance);

class DatabaseBackupHelper {
  /// Triggers a background cloud backup if the user is signed in with Google.
  static void triggerBackup(Ref ref) {
    final user = AuthService().currentUser;
    if (user == null || user.isAnonymous) return;

    // Run async in background - don't block the UI
    Future.microtask(() async {
      try {
        final db = DatabaseService.instance;
        final settings = ref.read(settingsProvider);
        await CloudSyncService().backupAll(
          uid: user.uid,
          transactions: await db.getAllTransactions(),
          wallets: await db.getAllWallets(),
          bills: await db.getAllBills(),
          budgets: await db.getAllBudgets(),
          goals: await db.getAllGoals(),
          userName: settings.userName,
          photoUrl: user.photoURL,
        );
        await ref.read(settingsProvider.notifier).recordBackupResult(true);
      } catch (e) {
        debugPrint('BackupHelper: Backup failed: $e');
        await ref.read(settingsProvider.notifier).recordBackupResult(false);
      }
    });
  }
}
