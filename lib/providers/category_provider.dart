import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import 'database_provider.dart';

final categoriesProvider = StateNotifierProvider<CategoriesNotifier, List<Category>>((ref) {
  return CategoriesNotifier(ref.watch(databaseServiceProvider), ref);
});

class CategoriesNotifier extends StateNotifier<List<Category>> {
  final DatabaseService _dbService;
  final Ref _ref;

  CategoriesNotifier(this._dbService, this._ref) : super([]) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    state = await _dbService.getAllCategories();
  }

  /// Menambah kategori custom baru. Return `false` kalau nama sudah dipakai
  /// (constraint UNIQUE di DB) supaya UI bisa kasih feedback yang jelas.
  Future<bool> addCategory(String name, int color) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    if (state.any((c) => c.name.toLowerCase() == trimmed.toLowerCase())) return false;

    try {
      await _dbService.createCategory(Category(name: trimmed, color: color, isDefault: false));
      await loadCategories();
      DatabaseBackupHelper.triggerBackup(_ref);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> removeCategory(int id) async {
    await _dbService.deleteCategory(id);
    await loadCategories();
    DatabaseBackupHelper.triggerBackup(_ref);
  }
}
