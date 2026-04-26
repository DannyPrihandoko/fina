import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../models/transaction.dart';
import '../models/bill.dart';
import '../models/wallet.dart';
import '../models/budget.dart';
import '../models/financial_goal.dart';

import 'package:fina/providers/settings_provider.dart';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../services/local_ai_engine.dart';
import '../services/streak_service.dart';
import 'streak_provider.dart';

final databaseServiceProvider = Provider((ref) => DatabaseService.instance);

// BUDGETS PROVIDER
final budgetsProvider = StateNotifierProvider<BudgetsNotifier, List<Budget>>((ref) {
  return BudgetsNotifier(ref.watch(databaseServiceProvider));
});

class BudgetsNotifier extends StateNotifier<List<Budget>> {
  final DatabaseService _dbService;

  BudgetsNotifier(this._dbService) : super([]) {
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    state = await _dbService.getAllBudgets();
  }

  Future<void> setBudget(String category, double amount) async {
    final budget = Budget(category: category, limitAmount: amount);
    await _dbService.saveBudget(budget);
    await loadBudgets();
  }

  Future<void> removeBudget(int id) async {
    await _dbService.deleteBudget(id);
    await loadBudgets();
  }
}

// WALLETS PROVIDER
final walletsProvider = StateNotifierProvider<WalletsNotifier, List<Wallet>>((ref) {
  return WalletsNotifier(ref.watch(databaseServiceProvider), ref);
});

class WalletsNotifier extends StateNotifier<List<Wallet>> {
  final DatabaseService _dbService;
  final Ref _ref;

  WalletsNotifier(this._dbService, this._ref) : super([]) {
    loadWallets();
  }

  Future<void> loadWallets() async {
    state = await _dbService.getAllWallets();
  }

  Future<void> addWallet(Wallet wallet, double initialBalance) async {
    final id = await _dbService.createWallet(wallet);
    await loadWallets();

    if (initialBalance != 0) {
      final initialTx = Transaction(
        title: 'Saldo Awal: ${wallet.name}',
        amount: initialBalance.abs(),
        type: TransactionType.initial,
        category: 'Initial',
        date: DateTime.now(),
        walletId: id,
      );
      await _ref.read(transactionsProvider.notifier).addTransaction(initialTx);
    }
  }

  Future<void> removeWallet(int id) async {
    await _dbService.deleteWallet(id);
    await loadWallets();
  }

  Future<void> updateWallet(Wallet wallet) async {
    await _dbService.updateWallet(wallet);
    await loadWallets();
  }
}

// TRANSACTIONS PROVIDER
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
    final newStreak = await StreakService.recordActivity();
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
  }

  Future<void> removeTransaction(int id) async {
    await _dbService.deleteTransaction(id);
    await loadTransactions();
  }
}

// BILLS PROVIDER
final billsProvider = StateNotifierProvider<BillsNotifier, List<Bill>>((ref) {
  return BillsNotifier(ref.watch(databaseServiceProvider), ref);
});

class BillsNotifier extends StateNotifier<List<Bill>> {
  final DatabaseService _dbService;
  final Ref _ref;

  BillsNotifier(this._dbService, this._ref) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await loadBills();
    await syncReminders();
  }

  Future<void> loadBills() async {
    state = await _dbService.getAllBills();
  }

  Future<void> syncReminders() async {
    final settings = _ref.read(settingsProvider);
    if (!settings.isNotificationsEnabled) return;

    for (var bill in state) {
      if (!bill.isPaid && bill.reminderEnabled) {
        await NotificationService().scheduleBillReminders(bill);
      }
    }
  }

  Future<int> addBill(Bill bill) async {
    final id = await _dbService.createBill(bill);
    await loadBills();
    
    // Auto-schedule notification
    final settings = _ref.read(settingsProvider);
    if (settings.isNotificationsEnabled) {
      final updatedBill = bill.copyWith(id: id);
      await NotificationService().scheduleBillReminders(updatedBill);
    }
    
    return id;
  }

  Future<void> updateBill(Bill bill) async {
    await _dbService.updateBill(bill);
    await loadBills();

    // Reschedule notification
    final settings = _ref.read(settingsProvider);
    if (settings.isNotificationsEnabled) {
      await NotificationService().scheduleBillReminders(bill);
    }
  }

  Future<void> removeBill(int id) async {
    await _dbService.deleteBill(id);
    await NotificationService().cancelBillReminders(id);
    await loadBills();
  }

  Future<void> payBill(Bill bill, int walletId) async {
    final paidBill = bill.copyWith(isPaid: true);
    await _dbService.updateBill(paidBill);

    final transaction = Transaction(
      title: 'Bayar: ${bill.title}',
      amount: bill.amount,
      type: TransactionType.expense,
      category: bill.category,
      date: DateTime.now(),
      walletId: walletId,
    );

    await _ref.read(transactionsProvider.notifier).addTransaction(transaction);
    await loadBills();
  }
}

// CONVENIENCE PROVIDERS
final walletBalanceProvider = Provider.family<double, int>((ref, walletId) {
  final transactions = ref.watch(transactionsProvider);
  double balance = 0;

  for (var tx in transactions) {
    if (tx.walletId == walletId) {
      if (tx.type == TransactionType.income || tx.type == TransactionType.initial) {
        balance += tx.amount;
      } else if (tx.type == TransactionType.expense || tx.type == TransactionType.transfer) {
        balance -= tx.amount;
        balance -= tx.adminFee;
      }
    } else if (tx.toWalletId == walletId && tx.type == TransactionType.transfer) {
      balance += tx.amount;
    }
  }

  return balance;
});

final totalNetWorthProvider = Provider((ref) {
  final wallets = ref.watch(walletsProvider);
  double total = 0;
  for (var wallet in wallets) {
    total += ref.watch(walletBalanceProvider(wallet.id!));
  }
  return total;
});

// GOALS PROVIDER
final goalsProvider = StateNotifierProvider<GoalsNotifier, List<FinancialGoal>>((ref) {
  return GoalsNotifier(ref.watch(databaseServiceProvider));
});

class GoalsNotifier extends StateNotifier<List<FinancialGoal>> {
  final DatabaseService _dbService;

  GoalsNotifier(this._dbService) : super([]) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    state = await _dbService.getAllGoals();
  }

  Future<int> addGoal(FinancialGoal goal) async {
    final id = await _dbService.createGoal(goal);
    await loadGoals();
    return id;
  }

  Future<void> updateGoal(FinancialGoal goal) async {
    await _dbService.updateGoal(goal);
    await loadGoals();
  }

  Future<void> removeGoal(int id) async {
    await _dbService.deleteGoal(id);
    await loadGoals();
  }

  Future<void> addSavings(FinancialGoal goal, double amount) async {
    final updated = goal.copyWith(savedAmount: goal.savedAmount + amount);
    await _dbService.updateGoal(updated);
    await loadGoals();
  }
}
