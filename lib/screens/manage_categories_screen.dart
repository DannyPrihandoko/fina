import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../models/category.dart';
import '../theme/colors.dart';
import '../utils/category_style.dart';

class ManageCategoriesScreen extends ConsumerStatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  ConsumerState<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends ConsumerState<ManageCategoriesScreen> {
  static const List<Map<String, dynamic>> _colorOptions = [
    {'label': 'Hijau', 'value': 0xFF4CAF50},
    {'label': 'Biru', 'value': 0xFF2196F3},
    {'label': 'Ungu', 'value': 0xFF7C4DFF},
    {'label': 'Oranye', 'value': 0xFFFF9800},
    {'label': 'Merah', 'value': 0xFFE53935},
    {'label': 'Pink', 'value': 0xFFE91E63},
    {'label': 'Teal', 'value': 0xFF009688},
    {'label': 'Amber', 'value': 0xFFFFC107},
    {'label': 'Coklat', 'value': 0xFF795548},
    {'label': 'Abu', 'value': 0xFF607D8B},
  ];

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final transactions = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Kelola Kategori', style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final usageCount = transactions.where((tx) => tx.category == category.name).length;
                return _buildCategoryTile(context, category, usageCount);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('KATEGORI BARU', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5, fontSize: 12)),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, Category category, int usageCount) {
    final color = Color(category.color);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(CategoryStyle.icon(category.name), color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(
                  category.isDefault ? 'Kategori bawaan' : '$usageCount transaksi memakai kategori ini',
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                ),
              ],
            ),
          ),
          if (!category.isDefault)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
              tooltip: 'Hapus kategori',
              onPressed: () => _confirmDeleteCategory(context, category, usageCount),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteCategory(BuildContext context, Category category, int usageCount) async {
    if (usageCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak bisa hapus "${category.name}" — masih dipakai $usageCount transaksi.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Kategori?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Kategori "${category.name}" akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('BATAL')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('HAPUS', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(categoriesProvider.notifier).removeCategory(category.id!);
    }
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final controller = TextEditingController();
    int selectedColor = _colorOptions.first['value'] as int;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kategori Baru', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nama Kategori',
                    hintText: 'Contoh: Pendidikan, Zakat, Investasi',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Warna', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _colorOptions.map((option) {
                    final value = option['value'] as int;
                    final isSelected = selectedColor == value;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedColor = value),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(value),
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3) : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = controller.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nama kategori wajib diisi')),
                        );
                        return;
                      }
                      final success = await ref.read(categoriesProvider.notifier).addCategory(name, selectedColor);
                      if (context.mounted) {
                        if (success) {
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Kategori "$name" sudah ada')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('SIMPAN', style: TextStyle(fontWeight: FontWeight.w900)),
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
