import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/local_ai_engine.dart';
import '../services/notification_service.dart';
import 'database_provider.dart';
import 'settings_provider.dart';
import 'streak_provider.dart';

final transactionsProvider = StateNotifierProvider<TransactionsNotifier, List<Transaction>>((ref) {
  return TransactionsNotifier(ref.watch(databaseServiceProvider), ref);
});

class TransactionsNotifier extends StateNotifier<List<Transaction>> {
  final DatabaseService _dbService;
  final Ref _ref;

  TransactionsNotifier(this._dbService, this._ref) : super([]) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    state = await _dbService.getAllTransactions();
  }

  Future<void> addTransaction(Transaction tx) async {
    final id = await _dbService.createTransaction(tx);
    await loadTransactions();
    await _ref.read(settingsProvider.notifier).revealInsight();
    
    // Update streak
    final newStreak = await _ref.read(streakServiceProvider).recordActivity();
    _ref.read(streakProvider.notifier).state = newStreak;

    // Smart Alerts Logic
    final settings = _ref.read(settingsProvider);
    if (settings.isSmartAlertsEnabled && tx.type == TransactionType.expense) {
      final transactions = state;
      final alerts = LocalAIEngine().detectUnusualSpending(
        transactions: transactions.where((t) => t.id != id).toList(),
        newTransaction: tx,
      );

      for (var alert in alerts) {
        await NotificationService().showSmartAlert(
          title: 'fina: Alert Pengeluaran',
          body: alert,
        );
      }
    }
    DatabaseBackupHelper.triggerBackup(_ref);
  }

  Future<void> removeTransaction(int id) async {
    await _dbService.deleteTransaction(id);
    await loadTransactions();
    DatabaseBackupHelper.triggerBackup(_ref);
  }
}
