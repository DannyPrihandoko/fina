import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../models/transaction.dart';
import '../models/bill.dart';

import 'package:fina/providers/settings_provider.dart';

final databaseServiceProvider = Provider((ref) => DatabaseService.instance);

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
    await _dbService.createTransaction(tx);
    await loadTransactions();
    await _ref.read(settingsProvider.notifier).revealInsight();
  }

  Future<void> removeTransaction(int id) async {
    await _dbService.deleteTransaction(id);
    await loadTransactions();
  }
}

final billsProvider = StateNotifierProvider<BillsNotifier, List<Bill>>((ref) {
  return BillsNotifier(ref.watch(databaseServiceProvider));
});

class BillsNotifier extends StateNotifier<List<Bill>> {
  final DatabaseService _dbService;

  BillsNotifier(this._dbService) : super([]) {
    loadBills();
  }

  Future<void> loadBills() async {
    state = await _dbService.getAllBills();
  }

  Future<void> addBill(Bill bill) async {
    await _dbService.createBill(bill);
    await loadBills();
  }

  Future<void> updateBill(Bill bill) async {
    await _dbService.updateBill(bill);
    await loadBills();
  }

  Future<void> removeBill(int id) async {
    await _dbService.deleteBill(id);
    await loadBills();
  }
}
