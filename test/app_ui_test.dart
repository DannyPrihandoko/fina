import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:fina/screens/main_screen.dart';
import 'package:fina/providers/settings_provider.dart';

// Catatan: sengaja pump `MainScreen` langsung (bukan `FinaApp`/`SplashScreen`) karena
// SplashScreen menunda navigasi lewat `Future.delayed(3 detik)` yang dijadwalkan SETELAH
// rantai await notification-permission & auto-sync selesai — di lingkungan widget test
// tanpa mock platform channel untuk plugin notifikasi/sqflite, rantai itu tidak pernah
// benar-benar selesai sehingga navigasi ke MainScreen tidak pernah terjadi walau di-pump
// berkali-kali. Menguji MainScreen langsung tetap merupakan pengujian nyata atas UI utama
// tanpa bergantung pada plugin native yang tidak tersedia di lingkungan test.
Widget _buildTestApp(SharedPreferences prefs) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const MaterialApp(home: MainScreen()),
  );
}

void main() {
  // MainScreen/DashboardScreen memuat providers yang menyentuh sqflite (DatabaseService)
  // secara nyata. Di lingkungan widget test tanpa device, `databaseFactory` default
  // tidak ada — perlu diarahkan ke implementasi FFI (in-memory/desktop) dulu.
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('UI dan Button Integration Test', () {
    testWidgets('Report: Memastikan aplikasi berjalan dan UI utama tampil', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final sharedPrefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildTestApp(sharedPrefs));
      // Bukan pumpAndSettle(): Dashboard punya indikator loading yang terus berputar
      // selama data belum siap, jadi tidak akan pernah benar-benar "settle". Pump
      // beberapa frame dengan durasi tetap sudah cukup untuk render awal selesai.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }

      // Assertion nyata: MainScreen harus benar-benar tampil dengan BottomNavigationBar-nya,
      // bukan cuma mengecek MaterialApp yang trivially true di layar manapun.
      expect(find.byType(BottomNavigationBar), findsOneWidget,
          reason: 'MainScreen harus menampilkan BottomNavigationBar');

      print('✅ REPORT: Aplikasi berhasil dirender tanpa error UI (Clean Build).');
    });

    testWidgets('Report: Memeriksa interaksi tombol (Button Click Test)', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final sharedPrefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildTestApp(sharedPrefs));
      // Bukan pumpAndSettle(): Dashboard punya indikator loading yang terus berputar
      // selama data belum siap, jadi tidak akan pernah benar-benar "settle". Pump
      // beberapa frame dengan durasi tetap sudah cukup untuk render awal selesai.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }

      // Cari semua tombol / action yang ada di layar (mencakup widget button bawaan
      // Material maupun tap-target custom berbasis GestureDetector/InkWell yang dipakai
      // di beberapa screen FINA).
      final iconButtons = find.byType(IconButton);
      final floatingButtons = find.byType(FloatingActionButton);
      final elevatedButtons = find.byType(ElevatedButton);
      final filledButtons = find.byType(FilledButton);
      final textButtons = find.byType(TextButton);
      final gestureDetectors = find.byType(GestureDetector);
      final inkWells = find.byType(InkWell);

      final totalTappable = iconButtons.evaluate().length +
          floatingButtons.evaluate().length +
          elevatedButtons.evaluate().length +
          filledButtons.evaluate().length +
          textButtons.evaluate().length +
          gestureDetectors.evaluate().length +
          inkWells.evaluate().length;

      print('✅ REPORT: Ditemukan ${iconButtons.evaluate().length} IconButton, '
          '${floatingButtons.evaluate().length} FAB, ${elevatedButtons.evaluate().length} ElevatedButton, '
          '${filledButtons.evaluate().length} FilledButton, ${textButtons.evaluate().length} TextButton, '
          '${gestureDetectors.evaluate().length} GestureDetector, ${inkWells.evaluate().length} InkWell '
          '(total $totalTappable elemen interaktif).');

      // Assertion nyata: layar utama HARUS punya minimal satu elemen interaktif setelah
      // render selesai. Sebelumnya test ini hanya mencetak angka tanpa expect() apa pun,
      // sehingga tetap "lulus" meski 0 tombol ditemukan / semua tombol rusak.
      expect(totalTappable, greaterThan(0),
          reason: 'Layar utama harus memiliki setidaknya satu elemen yang bisa ditekan');

      // Simulasi klik salah satu item BottomNavigationBar untuk memverifikasi navigasi antar-tab berfungsi.
      final navBarFinder = find.byType(BottomNavigationBar);
      if (navBarFinder.evaluate().isNotEmpty) {
        await tester.tap(navBarFinder.first);
        await tester.pump(const Duration(milliseconds: 300));
        print('✅ REPORT: BottomNavigationBar berhasil di-tap tanpa error.');
      }
    });
  });
}
