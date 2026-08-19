import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bill.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'database_provider.dart';
import 'settings_provider.dart';
import 'transaction_provider.dart';

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
    DatabaseBackupHelper.triggerBackup(_ref);
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
    DatabaseBackupHelper.triggerBackup(_ref);
  }

  Future<void> removeBill(int id) async {
    await _dbService.deleteBill(id);
    await NotificationService().cancelBillReminders(id);
    await loadBills();
    DatabaseBackupHelper.triggerBackup(_ref);
  }

  Future<void> payBill(Bill bill, int walletId) async {
    final paidBill = bill.copyWith(isPaid: true);
    await _dbService.updateBill(paidBill);
    // Tagihan yang sudah lunas tidak boleh lagi mengirim reminder jatuh tempo.
    await NotificationService().cancelBillReminders(bill.id!);

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
    DatabaseBackupHelper.triggerBackup(_ref);
  }
}
