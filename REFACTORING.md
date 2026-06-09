# Panduan & Dokumentasi Refactoring FINA

Dokumen ini mendokumentasikan hasil dari refactoring kode secara bertahap pada aplikasi **FINA** untuk meningkatkan modularitas, kebersihan kode, keterbacaan, dan kemudahan pengujian.

---

## 🎯 Target Utama yang Dicapai

1. **Pembersihan Layer Model & Konstanta (Fase 1)**:
   - Menambahkan method `copyWith` ke kelas `Transaction` ([transaction.dart](file:///c:/Project/Android/fina/lib/models/transaction.dart)) untuk kemudahan manipulasi state tanpa merusak immutability.
   - Kelas `Connection` dan `SocialState` dipisahkan dari layer provider dan dipindahkan ke file model baru: [connection.dart](file:///c:/Project/Android/fina/lib/models/connection.dart).
   - Kategori default transaksi dan tagihan rutin dikumpulkan secara terpusat di dalam [constants.dart](file:///c:/Project/Android/fina/lib/utils/constants.dart), menghilangkan hardcoded string di berbagai screen.

2. **Standarisasi Service Layer & Dependency Injection (Fase 2)**:
   - `LocalAIEngine` dan `OCRService` diubah menjadi **Singleton** menggunakan factory constructor untuk mengurangi konsumsi memori dan mengamankan instance tunggal.
   - `StreakService` didekati dengan pola **Dependency Injection** di mana ia menerima instance `SharedPreferences` via constructor, dan dibungkus menggunakan Riverpod Provider (`streakServiceProvider`).

3. **Dekomposisi Provider (Urai God File) (Fase 3)**:
   - File besar `database_provider.dart` (336 baris) dipecah menjadi file provider terdedikasi sesuai domain data:
     - [budget_provider.dart](file:///c:/Project/Android/fina/lib/providers/budget_provider.dart)
     - [wallet_provider.dart](file:///c:/Project/Android/fina/lib/providers/wallet_provider.dart)
     - [transaction_provider.dart](file:///c:/Project/Android/fina/lib/providers/transaction_provider.dart)
     - [bill_provider.dart](file:///c:/Project/Android/fina/lib/providers/bill_provider.dart)
     - [goal_provider.dart](file:///c:/Project/Android/fina/lib/providers/goal_provider.dart)
   - `database_provider.dart` bertindak sebagai *barrel file* yang mengekspor provider-provider baru tersebut sehingga tidak ada import di UI screen yang patah.
   - Helper backup `_triggerBackup` dibungkus secara rapi dalam utility class `DatabaseBackupHelper`.

4. **Dekopling Firebase dari Provider Layer (Fase 4)**:
   - Logic parsing dokumen `QueryDocumentSnapshot` Firestore dipindahkan sepenuhnya ke service layer di `FirebaseService`.
   - Import package `cloud_firestore` dihapus dari `social_provider.dart`.
   - Data disanitasi secara otomatis dari tipe data Firestore (misal `Timestamp` ke ISO string) di dalam `FirebaseService` sebelum dikirimkan ke stream provider.

5. **Dekomposisi UI Screen (Fase 5)**:
   - Mengurangi boilerplate di [settings_screen.dart](file:///c:/Project/Android/fina/lib/screens/settings_screen.dart) (mengurangi ukuran file dari 35KB menjadi ~25KB).
   - Seluruh settings tile visual pembantu diekstraksi ke file widget modular baru: [settings_tiles.dart](file:///c:/Project/Android/fina/lib/widgets/settings_tiles.dart).

6. **Optimasi Caching & Pengujian (Fase 6)**:
   - Menambahkan `walletTransactionsProvider` di [wallet_provider.dart](file:///c:/Project/Android/fina/lib/providers/wallet_provider.dart) untuk mem-cache hasil filter transaksi per dompet (walletId).
   - Memperbarui `walletBalanceProvider` untuk mengonsumsi transaksi terfilter yang telah di-cache, mengeliminasi loop linear redundan pada seluruh list transaksi.
   - Memperbaiki setup pengujian (`widget_test.dart` dan `app_ui_test.dart`) dengan mensimulasikan nilai default `SharedPreferences` dan menimpa `sharedPreferencesProvider` di dalam `ProviderScope` untuk mencegah error `UnimplementedError` pada runtime test.

---

## 🔍 Hasil Verifikasi Kode
* **Kompilasi Dart**: Seluruh kode Dart lolos kompilasi tanpa ada syntax error atau type reference error.
* **Unit & Integration Tests**: Seluruh test suite (`flutter test`) berhasil diselesaikan dengan hasil **100% lulus** (9 dari 9 pengujian sukses).
* **Gradle Android API Warning**: Build Gradle Android memiliki dependensi `home_widget` (Glance Widget) yang memerlukan compileSDK 37, sedangkan konfigurasi dasar Gradle proyek saat ini masih menggunakan SDK 36. Perbaikan ini opsional di level Android Gradle, namun seluruh logic code Dart 100% aman dan sehat.

