import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/financial_goal.dart';
import '../services/database_service.dart';
import 'database_provider.dart';

final goalsProvider = StateNotifierProvider<GoalsNotifier, List<FinancialGoal>>((ref) {
  return GoalsNotifier(ref.watch(databaseServiceProvider), ref);
});

class GoalsNotifier extends StateNotifier<List<FinancialGoal>> {
  final DatabaseService _dbService;
  final Ref _ref;

  GoalsNotifier(this._dbService, this._ref) : super([]) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    state = await _dbService.getAllGoals();
  }

  Future<int> addGoal(FinancialGoal goal) async {
    final id = await _dbService.createGoal(goal);
    await loadGoals();
    DatabaseBackupHelper.triggerBackup(_ref);
    return id;
  }

  Future<void> updateGoal(FinancialGoal goal) async {
    await _dbService.updateGoal(goal);
    await loadGoals();
    DatabaseBackupHelper.triggerBackup(_ref);
  }

  Future<void> removeGoal(int id) async {
    await _dbService.deleteGoal(id);
    await loadGoals();
    DatabaseBackupHelper.triggerBackup(_ref);
  }

  Future<void> addSavings(FinancialGoal goal, double amount) async {
    final updated = goal.copyWith(savedAmount: goal.savedAmount + amount);
    await _dbService.updateGoal(updated);
    await loadGoals();
    DatabaseBackupHelper.triggerBackup(_ref);
  }
}
