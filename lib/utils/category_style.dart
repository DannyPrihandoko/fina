import 'package:flutter/material.dart';
import '../models/category.dart';
import '../theme/colors.dart';

/// Helper ikon & warna kategori terpusat — sebelumnya di-duplikasi terpisah di
/// dashboard_screen.dart, transactions_screen.dart, dan stats_screen.dart.
class CategoryStyle {
  CategoryStyle._();

  /// 'transfer'/'initial'/'pendapatan' adalah penanda tipe transaksi sistem,
  /// bukan kategori yang dikelola user lewat ManageCategoriesScreen — makanya
  /// dicek terpisah di sini, tidak ikut disimpan di tabel `categories`.
  static IconData icon(String category) {
    switch (category.toLowerCase()) {
      case 'transfer':
        return Icons.swap_horiz_rounded;
      case 'initial':
        return Icons.first_page_rounded;
      case 'pendapatan':
        return Icons.attach_money_rounded;
      case 'makanan':
        return Icons.restaurant_rounded;
      case 'belanja':
        return Icons.shopping_bag_outlined;
      case 'transportasi':
        return Icons.directions_bus_filled_outlined;
      case 'hiburan':
        return Icons.movie_filter_outlined;
      case 'kesehatan':
        return Icons.health_and_safety_outlined;
      case 'cicilan':
        return Icons.receipt_long_rounded;
      default:
        return Icons.category_outlined; // termasuk semua kategori custom user
    }
  }

  /// Warna diambil dari data dinamis `categoriesProvider` (termasuk kategori bawaan
  /// yang di-seed saat migrasi DB v6), bukan hardcoded switch lagi — supaya kategori
  /// custom yang user tambahkan otomatis dapat warna sesuai yang dipilih saat dibuat.
  static Color color(String category, List<Category> categories) {
    final match = categories.where((c) => c.name.toLowerCase() == category.toLowerCase());
    if (match.isNotEmpty) return Color(match.first.color);
    return AppColors.textDarkBlue;
  }
}
