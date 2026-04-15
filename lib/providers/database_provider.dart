import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../models/transaction.dart';
import '../models/bill.dart';

final databaseServiceProvider = Provider((ref) => DatabaseService.instance);

final transactionsProvider = StateNotifierProvider<TransactionsNotifier, List<Transaction>>((ref) {
  return TransactionsNotifier(ref.watch(databaseServiceProvider));
});

class TransactionsNotifier extends StateNotifier<List<Transaction>> {
  final DatabaseService _dbService;

  TransactionsNotifier(this._dbService) : super([]) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    state = await _dbService.getAllTransactions();
  }

  Future<void> addTransaction(Transaction tx) async {
    await _dbService.createTransaction(tx);
    await loadTransactions();
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

  Future<void> removeBill(int id) async {
    await _dbService.deleteBill(id);
    await loadBills();
  }
}
