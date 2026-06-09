import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget.dart';
import '../services/database_service.dart';
import 'database_provider.dart';

final budgetsProvider = StateNotifierProvider<BudgetsNotifier, List<Budget>>((ref) {
  return BudgetsNotifier(ref.watch(databaseServiceProvider), ref);
});

class BudgetsNotifier extends StateNotifier<List<Budget>> {
  final DatabaseService _dbService;
  final Ref _ref;

  BudgetsNotifier(this._dbService, this._ref) : super([]) {
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    state = await _dbService.getAllBudgets();
  }

  Future<void> setBudget(String category, double amount) async {
    final budget = Budget(category: category, limitAmount: amount);
    await _dbService.saveBudget(budget);
    await loadBudgets();
    DatabaseBackupHelper.triggerBackup(_ref);
  }

  Future<void> removeBudget(int id) async {
    await _dbService.deleteBudget(id);
    await loadBudgets();
    DatabaseBackupHelper.triggerBackup(_ref);
  }
}
