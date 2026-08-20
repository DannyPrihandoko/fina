class AppConstants {
  // Kategori transaksi sekarang dinamis (tabel `categories` di DB, dikelola via
  // categoriesProvider/ManageCategoriesScreen) — bukan daftar statis lagi.
  // 7 nama yang dulu ada di sini tetap jadi seed default di DatabaseService.
  static const String defaultCategory = 'Makanan';

  static const List<String> defaultBillCategories = [
    'Listrik',
    'Air',
    'Internet',
    'Sewa',
    'Asuransi',
    'Lainnya',
  ];

  static const String defaultBillCategory = 'Listrik';
}
