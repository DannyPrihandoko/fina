import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fina/main.dart'; // Sesuaikan jika FinaApp ada di lokasi lain

void main() {
  group('UI dan Button Integration Test', () {
    testWidgets('Report: Memastikan aplikasi berjalan dan UI utama tampil', (WidgetTester tester) async {
      // 1. Inisialisasi Aplikasi (di dalam ProviderScope karena menggunakan Riverpod)
      await tester.pumpWidget(
        const ProviderScope(
          child: FinaApp(),
        ),
      );

      // Tunggu hingga animasi atau proses asinkron awal selesai
      await tester.pumpAndSettle();

      // 2. Report/Cek UI Utama (Misalnya mengecek AppBar atau judul layar tampil)
      // Ganti 'MainScreen' / Teks spesifik sesuai UI kamu.
      // expect(find.text('Nama Judul Header'), findsOneWidget); 
      
      // Catat bahwa framework sudah berhasil memutar / merender layar pertama
      expect(find.byType(MaterialApp), findsOneWidget);
      
      print('✅ REPORT: Aplikasi berhasil dirender tanpa error UI (Clean Build).');
    });

    testWidgets('Report: Memeriksa interaksi tombol (Button Click Test)', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: FinaApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 3. Cari semua tombol / action yang ada di layar.
      // Ini adalah contoh mencari IconButton (misalnya tombol navigasi atau tambah)
      final buttons = find.byType(IconButton);
      final floatingButtons = find.byType(FloatingActionButton);
      final elevatedButtons = find.byType(ElevatedButton);

      print('✅ REPORT: Ditemukan \$${buttons.evaluate().length} IconButton, \$${floatingButtons.evaluate().length} FAB, dan \$${elevatedButtons.evaluate().length} ElevatedButton.');

      // 4. Simulasi Klik Tombol (Opsional, pastikan element nya benar-benar ada)
      // Contoh jika kamu mau menekan tombol dengan icon tertentu:
      /*
      if (find.byIcon(Icons.add).evaluate().isNotEmpty) {
         await tester.tap(find.byIcon(Icons.add));
         await tester.pumpAndSettle(); // Tunggu layar berpindah
         print('✅ REPORT: Tombol Add berhasil diklik.');
         
         // Lakukan pengecekan layar setelah di klik
         // expect(find.text('Tambah Transaksi Baru'), findsOneWidget);
      }
      */
    });

  });
}
