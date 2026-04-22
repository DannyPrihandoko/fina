# FINA - Aplikasi Manajemen Arus Kas Pribadi

**FINA** adalah aplikasi manajemen keuangan pribadi yang modern dan cerdas, dirancang untuk membantu Anda mengelola arus kas, melacak pengeluaran, mencapai target finansial, dan berbagi ringkasan keuangan dengan keluarga atau mitra secara aman.

![Logo](assets/icon/logo_apps.png)

## 🚀 Fitur Utama

### 1. Manajemen Arus Kas (Transaksi)
*   **Pemasukan & Pengeluaran**: Catat setiap transaksi harian Anda dengan kategori yang dapat disesuaikan.
*   **Transfer Antar Dompet**: Kelola mutasi saldo antar dompet atau bank Anda dengan mudah.
*   **Swipe to Delete**: Hapus transaksi yang salah input dengan menggeser item transaksi, dilengkapi dengan konfirmasi untuk keamanan data.

### 2. Multi-Wallet (Dompet Digital)
*   Kelola berbagai dompet sekaligus (Tunai, Bank, E-Wallet, dll).
*   Visualisasi saldo total (Net Worth) secara *real-time*.

### 3. Target Finansial (Goals)
*   **Tabungan Terencana**: Tetapkan target untuk impian Anda (misal: Beli Mobil, Dana Darurat, Liburan).
*   **Progress Tracking**: Pantau seberapa dekat Anda dengan target melalui indikator persentase yang visual.

### 4. Manajemen Tagihan (Bills)
*   **Pengingat Otomatis**: Catat tagihan rutin (Listrik, Kost, Langganan Streaming) dan dapatkan notifikasi sebelum jatuh tempo.
*   **Bayar Satu Klik**: Tandai tagihan sebagai terbayar dan aplikasi akan otomatis mencatatnya sebagai pengeluaran di dompet pilihan Anda.

### 5. AI Insights & OCR
*   **Smart Scan (OCR)**: Scan struk belanja Anda menggunakan kamera, dan biarkan AI mendeteksi jumlah serta judul transaksi secara otomatis.
*   **AI Financial Analysis**: Dapatkan saran dan wawasan keuangan berdasarkan pola pengeluaran Anda.

### 6. Hubungan Keuangan (Social Sharing)
*   **Berbagi Rekap**: Publikasikan ringkasan keuangan Anda ke *cloud* secara anonim.
*   **Scan QR**: Hubungkan perangkat Anda dengan anggota keluarga (misal: Istri/Suami) untuk saling memantau total saldo dan pengeluaran secara transparan tanpa berbagi data privat secara detail.

### 7. Statistik & Rekapitulasi
*   Grafik tren arus kas mingguan dan bulanan.
*   Analisis pengeluaran per kategori untuk membantu Anda melakukan penghematan.

---

## 🛠️ Teknologi yang Digunakan

*   **Framework**: Flutter (Dart)
*   **State Management**: Flutter Riverpod
*   **Database Lokal**: SQLite (Sqflite)
*   **Backend & Sync**: Firebase (Firestore & Anonymous Auth)
*   **AI/ML**: Google ML Kit (Text Recognition)
*   **Charts**: FL Chart

---

## 📸 Panduan Penggunaan

### Menambah Transaksi
1.  Klik ikon **"+"** di Dashboard.
2.  Pilih jenis transaksi (Masuk/Keluar/Transfer).
3.  Opsi: Gunakan ikon kamera untuk scan struk belanja secara otomatis.
4.  Masukkan nominal dan simpan.

### Menggunakan Fitur Hubungan (Keluarga)
1.  **Pengirim**: Buka Menu Hubungan -> Tab ID SAYA -> Klik **Publikasikan Data** -> Tunjukkan QR Code.
2.  **Penerima**: Buka Menu Hubungan -> Klik tombol **BAGI DATA** -> Scan QR Code perangkat pengirim.
3.  Sekarang Anda dapat memantau rekap saldo perangkat tersebut di daftar Hubungan Anda.

### Menghapus Data
Geser (swipe) item transaksi ke arah kiri pada halaman Riwayat atau Dashboard, lalu konfirmasi penghapusan pada *pop-up* yang muncul.

---

## 🛠️ Instalasi untuk Developer

1.  Pastikan Anda telah menginstal [Flutter SDK](https://docs.flutter.dev/get-started/install).
2.  Clone repository ini.
3.  Jalankan `flutter pub get` untuk mengunduh semua dependency.
4.  Konfigurasikan proyek Firebase Anda dan tambahkan file `google-services.json` ke direktori `android/app`.
5.  Jalankan aplikasi dengan `flutter run`.

---

## 📧 Kontak & Dukungan
Jika Anda memiliki pertanyaan atau masukan untuk pengembangan FINA, jangan ragu untuk menghubungi tim pengembang.

**Dibuat dengan ❤️ untuk Masa Depan Finansial yang Lebih Baik.**
