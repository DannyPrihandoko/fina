# 🏗️ FINA — Engineering Documentation

> **Versi**: 1.1.0 · **Terakhir diperbarui**: 19 Agustus 2026  
> **Penulis**: Auto-generated dari analisis codebase  
> **Tech Stack**: Flutter (Dart) · Riverpod · SQLite · Firebase · ML Kit

---

## Daftar Isi

1. [Arsitektur Aplikasi](#1-arsitektur-aplikasi)
2. [Struktur Folder](#2-struktur-folder)
3. [Data Models](#3-data-models)
4. [Database Schema (SQLite)](#4-database-schema-sqlite)
5. [Service Layer](#5-service-layer)
6. [State Management (Riverpod)](#6-state-management-riverpod)
7. [Screens & Navigation](#7-screens--navigation)
8. [Widgets (Reusable Components)](#8-widgets-reusable-components)
9. [Design System & Theming](#9-design-system--theming)
10. [Workflow & Data Flow](#10-workflow--data-flow)
11. [Business Logic Functions](#11-business-logic-functions)
12. [Firebase & Cloud Architecture](#12-firebase--cloud-architecture)
13. [AI Engine & OCR Pipeline](#13-ai-engine--ocr-pipeline)
14. [Notification System](#14-notification-system)
15. [Dependency Map](#15-dependency-map)
16. [Konvensi & Panduan Pengembangan](#16-konvensi--panduan-pengembangan)
17. [Platform Integrations](#17-platform-integrations)
18. [Known Issues & Bug Backlog](#18-known-issues--bug-backlog)

---

## 1. Arsitektur Aplikasi

FINA menggunakan arsitektur **Clean Layered Architecture** berbasis Flutter dengan pemisahan concern yang jelas:

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────┐ │
│  │ Screens  │  │ Widgets  │  │  Theme   │  │     Utils        │ │
│  │ (16 files)│  │ (2 files)│  │ (2 files)│  │   (1 file)       │ │
│  └────┬─────┘  └──────────┘  └──────────┘  └──────────────────┘ │
│       │                                                         │
│       ▼                                                         │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    STATE MANAGEMENT                         │ │
│  │  Riverpod Providers (6 files)                               │ │
│  │  StateNotifierProvider + StateProvider + StreamProvider      │ │
│  └────┬────────────────────────────────────────────────────────┘ │
│       │                                                         │
│       ▼                                                         │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                     SERVICE LAYER                           │ │
│  │  DatabaseService · AuthService · FirebaseService            │ │
│  │  CloudSyncService · NotificationService · OCRService        │ │
│  │  LocalAIEngine · StreakService                              │ │
│  └────┬────────────────────────────────────────────────────────┘ │
│       │                                                         │
│       ▼                                                         │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                      DATA LAYER                             │ │
│  │  Models (5 files) · SQLite DB · Firebase Firestore          │ │
│  │  SharedPreferences                                          │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Prinsip Arsitektur

| Prinsip | Implementasi |
|---------|-------------|
| **Unidirectional Data Flow** | Screen → Provider → Service → DB → Provider → Screen |
| **Singleton Services** | Semua service menggunakan pattern `factory` singleton |
| **Immutable Models** | Semua model menggunakan `final` fields + `copyWith()` |
| **Reactive UI** | Riverpod `ref.watch()` untuk auto-rebuild widget |
| **Separation of Concerns** | UI, logic bisnis, dan data access terpisah jelas |

---

## 2. Struktur Folder

```
lib/
├── main.dart                       # Entry point, Firebase init, Riverpod scope
├── models/                         # Data classes (immutable)
│   ├── bill.dart                   # Model Tagihan
│   ├── budget.dart                 # Model Anggaran per Kategori
│   ├── financial_goal.dart         # Model Target Finansial
│   ├── transaction.dart            # Model Transaksi (income/expense/transfer)
│   └── wallet.dart                 # Model Dompet (cash/bank/ewallet)
├── providers/                      # Riverpod state management
│   ├── auth_provider.dart          # Auth state (Firebase user stream)
│   ├── database_provider.dart      # Barrel file untuk export provider data
│   ├── budget_provider.dart        # Budget StateNotifier
│   ├── wallet_provider.dart        # Wallet StateNotifier & balance calculation
│   ├── transaction_provider.dart   # Transaction StateNotifier
│   ├── bill_provider.dart          # Bill StateNotifier
│   ├── goal_provider.dart          # Financial Goal StateNotifier
│   ├── navigation_provider.dart    # Bottom nav index
│   ├── settings_provider.dart      # App settings (dark mode, notif, language)
│   ├── social_provider.dart        # Koneksi keluarga (Firestore + local)
│   └── streak_provider.dart        # Streak counter
├── screens/                        # Full-page UI screens
│   ├── add_bill_screen.dart        # Form tambah tagihan
│   ├── add_goal_screen.dart        # Form tambah target
│   ├── add_transaction_screen.dart # Form tambah transaksi (+OCR)
│   ├── ai_screen.dart              # Chat interface AI assistant
│   ├── bills_screen.dart           # List & manage tagihan
│   ├── connections_screen.dart     # Hubungan keluarga
│   ├── dashboard_screen.dart       # Dashboard utama (net worth, chart, etc)
│   ├── goals_screen.dart           # List & manage target finansial
│   ├── main_screen.dart            # Shell + BottomNavigationBar
│   ├── settings_screen.dart        # Pengaturan aplikasi
│   ├── share_data_screen.dart      # Publikasi data ke cloud + QR
│   ├── shared_detail_screen.dart   # Detail data koneksi
│   ├── splash_screen.dart          # Splash + auto-restore dari cloud
│   ├── stats_screen.dart           # Statistik & grafik
│   ├── transactions_screen.dart    # Riwayat transaksi
│   └── wallets_screen.dart         # Manage multi-wallet
├── services/                       # Business logic & external integrations
│   ├── auth_service.dart           # Google Sign-In + Firebase Auth
│   ├── cloud_sync_service.dart     # Backup/Restore ke Firestore
│   ├── database_service.dart       # SQLite CRUD operations
│   ├── firebase_service.dart       # Firestore: profiles, snapshots, relationships
│   ├── local_ai_engine.dart        # AI chatbot + OCR parsing + smart alerts
│   ├── notification_service.dart   # Local notifications (bill reminders, alerts)
│   ├── ocr_service.dart            # Camera capture + ML Kit text recognition
│   └── streak_service.dart         # Activity streak + Home Widget
├── theme/                          # Design system
│   ├── app_theme.dart              # Light + Dark ThemeData
│   └── colors.dart                 # AppColors constants
├── utils/                          # Utility helpers
│   ├── constants.dart              # Global constants (categories, config)
│   └── currency_formatter.dart     # ThousandSeparatorFormatter + CurrencyUtils
└── widgets/                        # Reusable UI components
    ├── settings_tiles.dart         # Modular widget untuk pengaturan
    ├── streak_badge.dart           # Streak fire badge
    └── success_modal.dart          # Animated success dialog
```

---

## 3. Data Models

### 3.1 Transaction

```dart
// File: lib/models/transaction.dart
enum TransactionType { income, expense, transfer, initial }

class Transaction {
  final int? id;
  final String title;          // Nama transaksi
  final double amount;          // Nominal
  final TransactionType type;   // Jenis
  final String category;        // Kategori (Makanan, Transportasi, dll)
  final DateTime date;          // Tanggal
  final String? note;           // Catatan opsional
  final int walletId;           // FK ke wallet asal
  final int? toWalletId;        // FK ke wallet tujuan (khusus transfer)
  final double adminFee;        // Biaya admin transfer
}
```

**Catatan penting:**
- `TransactionType.initial` digunakan untuk "Saldo Awal" saat membuat wallet baru
- `toWalletId` hanya terisi saat `type == transfer`
- `adminFee` dipotong dari wallet asal saat transfer

### 3.2 Wallet

```dart
// File: lib/models/wallet.dart
enum WalletType { cash, bank, ewallet }

class Wallet {
  final int? id;
  final String name;       // "Dompet Utama", "BCA", "GoPay"
  final WalletType type;   // Jenis dompet
  final Color color;       // Warna identitas
}
```

**Catatan:** Saldo wallet **tidak disimpan langsung**, melainkan dihitung dari akumulasi transaksi via `walletBalanceProvider`.

### 3.3 Bill

```dart
// File: lib/models/bill.dart
class Bill {
  final int? id;
  final String title;           // "Listrik", "Kost", "Netflix"
  final double amount;           // Nominal tagihan
  final DateTime dueDate;        // Jatuh tempo
  final String category;         // Kategori
  final bool isRecurring;        // Tagihan berulang?
  final bool reminderEnabled;    // Notifikasi aktif?
  final bool isPaid;             // Sudah dibayar?
}
```

### 3.4 Budget

```dart
// File: lib/models/budget.dart
class Budget {
  final int? id;
  final String category;      // Kategori (unik per budget)
  final double limitAmount;    // Batas anggaran bulanan
}
```

### 3.5 FinancialGoal

```dart
// File: lib/models/financial_goal.dart
class FinancialGoal {
  final int? id;
  final String title;          // "Beli Mobil", "Dana Darurat"
  final double targetAmount;    // Target nominal
  final double savedAmount;     // Nominal terkumpul
  final DateTime deadline;      // Batas waktu
  final String icon;            // Emoji icon (default: '🎯')
  final String color;           // Hex color string

  // Computed Properties:
  double get progress;          // savedAmount / targetAmount (0.0 - 1.0)
  double get remainingAmount;   // targetAmount - savedAmount
  bool get isCompleted;         // savedAmount >= targetAmount
  int get daysRemaining;        // deadline.difference(now).inDays
}
```

### 3.6 Connection

```dart
// File: lib/models/connection.dart
class Connection {
  final String uid;             // User ID koneksi
  final String name;            // Nama pengguna
  final DateTime connectedAt;   // Tanggal terhubung
}
```

### Diagram Relasi Model

```
┌──────────────┐       ┌──────────────┐
│   Wallet     │◄──────│ Transaction  │
│              │  FK   │              │
│  id (PK)     │   ┌───│ walletId     │
│  name        │   │   │ toWalletId   │──────► Wallet (tujuan transfer)
│  type        │   │   │ type         │
│  color       │   │   │ category ────│──┐
└──────────────┘   │   │ amount       │  │
                   │   │ adminFee     │  │   ┌──────────────┐
                   │   └──────────────┘  │   │   Budget     │
                   │                     └──►│  category    │
                   │                         │  limitAmount │
                   │                         └──────────────┘
                   │
                   │   ┌──────────────┐     ┌──────────────┐
                   │   │    Bill      │     │ FinancialGoal│
                   │   │  id (PK)    │     │  id (PK)     │
                   │   │  title      │     │  title       │
                   │   │  amount     │     │  targetAmount│
                   │   │  dueDate    │     │  savedAmount │
                   │   │  isPaid     │     │  deadline    │
                   │   └──────────────┘     └──────────────┘
```

---

## 4. Database Schema (SQLite)

**File:** `lib/services/database_service.dart`  
**Database Name:** `fina.db`  
**Current Version:** `5`

### Tabel

```sql
-- Wallet: Dompet pengguna
CREATE TABLE wallets (
  id    INTEGER PRIMARY KEY AUTOINCREMENT,
  name  TEXT NOT NULL,
  type  TEXT NOT NULL,       -- 'cash' | 'bank' | 'ewallet'
  color INTEGER NOT NULL     -- Color.value (int ARGB)
);
-- Default: INSERT {id:1, name:'Dompet Utama', type:'bank', color:0xFF42A5F5}

-- Transaction: Semua mutasi keuangan
CREATE TABLE transactions (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  title      TEXT NOT NULL,
  amount     REAL NOT NULL,
  type       TEXT NOT NULL,       -- 'income' | 'expense' | 'transfer' | 'initial'
  category   TEXT NOT NULL,
  date       TEXT NOT NULL,       -- ISO 8601 string
  note       TEXT,
  walletId   INTEGER NOT NULL,    -- FK → wallets.id
  toWalletId INTEGER,             -- FK → wallets.id (nullable, hanya transfer)
  adminFee   REAL NOT NULL DEFAULT 0,
  FOREIGN KEY (walletId)   REFERENCES wallets (id),
  FOREIGN KEY (toWalletId) REFERENCES wallets (id)
);

-- Bill: Tagihan
CREATE TABLE bills (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  title           TEXT NOT NULL,
  amount          REAL NOT NULL,
  dueDate         TEXT NOT NULL,       -- ISO 8601
  category        TEXT NOT NULL,
  isRecurring     INTEGER NOT NULL,    -- 0/1
  reminderEnabled INTEGER NOT NULL,    -- 0/1
  isPaid          INTEGER NOT NULL DEFAULT 0
);

-- Budget: Anggaran per kategori
CREATE TABLE budgets (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  category    TEXT NOT NULL UNIQUE,
  limitAmount REAL NOT NULL
);

-- Financial Goals: Target tabungan
CREATE TABLE financial_goals (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  title        TEXT NOT NULL,
  targetAmount REAL NOT NULL,
  savedAmount  REAL NOT NULL DEFAULT 0,
  deadline     TEXT NOT NULL,       -- ISO 8601
  icon         TEXT NOT NULL DEFAULT '🎯',
  color        TEXT NOT NULL DEFAULT '0xFF4CAF50'
);
```

### Migration History

| Version | Perubahan |
|---------|-----------|
| 1 → 2 | Tambah tabel `wallets`, kolom `walletId`, `toWalletId`, `adminFee` di transactions |
| 2 → 3 | Tambah tabel `budgets` |
| 3 → 4 | Tambah kolom `isPaid` di bills |
| 4 → 5 | Tambah tabel `financial_goals` |

### CRUD Operations

`DatabaseService` adalah **Singleton** (`DatabaseService.instance`) yang menyediakan:

| Entity | Create | Read | Update | Delete |
|--------|--------|------|--------|--------|
| Wallet | `createWallet()` | `getAllWallets()` | `updateWallet()` | `deleteWallet()` |
| Transaction | `createTransaction()` | `getAllTransactions()` | ❌ | `deleteTransaction()` |
| Bill | `createBill()` | `getAllBills()` | `updateBill()` | `deleteBill()` |
| Budget | `saveBudget()` | `getAllBudgets()` | `saveBudget()` (REPLACE) | `deleteBudget()` |
| FinancialGoal | `createGoal()` | `getAllGoals()` | `updateGoal()` | `deleteGoal()` |

> ⚠️ **Transaction tidak memiliki update** — hanya delete dan create ulang.

---

## 5. Service Layer

Semua service menggunakan **Singleton pattern** via `factory` constructor.

### 5.1 DatabaseService

```
Lokasi:  lib/services/database_service.dart
Pattern: Singleton (DatabaseService.instance)
Deps:    sqflite, path, models/*
```

- Mengelola lifecycle SQLite database
- CRUD untuk semua 5 entity
- Menangani database migration (version 1→5)

### 5.2 AuthService

```
Lokasi:  lib/services/auth_service.dart
Pattern: Singleton (factory AuthService())
Deps:    firebase_auth, google_sign_in
```

| Method | Fungsi |
|--------|--------|
| `signInWithGoogle()` | Login Google → link anonymous account → atau sign in |
| `signOut()` | Logout Google + Firebase |
| `currentUser` | Getter Firebase `User?` |
| `isSignedIn` | `true` jika non-anonymous user |
| `authStateChanges` | Stream `User?` untuk reactive auth |

**Flow Login:**
1. `GoogleSignIn.signIn()` → Get Google account
2. Get `GoogleSignInAuthentication` → `OAuthCredential`
3. Jika user anonymous → `linkWithCredential()` (merge data)
4. Jika link gagal (credential-already-in-use) → `signInWithCredential()`
5. Return `User`

**Error Handling:**
- `FirebaseAuthException` → Pesan error Indonesia yang user-friendly
- `PlatformException` → Deteksi SHA-1 misconfiguration
- Catch-all → Generic error message

### 5.3 FirebaseService

```
Lokasi:  lib/services/firebase_service.dart
Pattern: Singleton
Deps:    cloud_firestore, firebase_auth
```

**Firestore Collections:**

| Collection | Dokumen ID | Fungsi |
|------------|-----------|--------|
| `profiles` | `{uid}` | Profil user (name, updatedAt) |
| `snapshots` | `{uid}` | Ringkasan keuangan untuk sharing |
| `relationships` | `{uid1}_{uid2}` | Koneksi antar user (sorted uid) |

| Method | Fungsi |
|--------|--------|
| `ensureLoggedIn()` | Auto anonymous login jika belum |
| `publishSnapshot(data)` | Upload ringkasan keuangan ke Firestore |
| `fetchSnapshot(uid)` | Ambil ringkasan orang lain |
| `fetchProfile(uid)` | Ambil profil user |
| `requestRelationship()` | Kirim request koneksi |
| `updateRelationshipStatus()` | Accept/reject koneksi |
| `streamRelationships()` | Real-time stream koneksi user |

**Penanganan Data (Sanitization):**
- `_sanitizeData()`: Digunakan untuk memparsing data dari Firestore, dengan pengetikan eksplisit `<String, dynamic>` pada `.map()` agar konversi dari JSON aman di Dart strict mode (menghindari `CastError` Map<dynamic, dynamic>).

### 5.4 CloudSyncService

```
Lokasi:  lib/services/cloud_sync_service.dart
Pattern: Singleton
Deps:    cloud_firestore, models/*
```

**Firestore Structure (Backup):**

```
users/{uid}/
  ├── userName, photoUrl, lastSyncAt
  └── backup/
      ├── transactions  → { data: [...], updatedAt }
      ├── wallets       → { data: [...], updatedAt }
      ├── bills         → { data: [...], updatedAt }
      ├── budgets       → { data: [...], updatedAt }
      └── goals         → { data: [...], updatedAt }
```

| Method | Fungsi |
|--------|--------|
| `backupAll(...)` | Batch write semua data ke Firestore |
| `isCloudDataAvailable(uid)` | Cek apakah backup ada |
| `restoreAll(uid)` | Download & parse semua data dari cloud |
| `getLastSyncTime(uid)` | Ambil timestamp sync terakhir |

### 5.5 NotificationService

```
Lokasi:  lib/services/notification_service.dart
Pattern: Singleton
Deps:    flutter_local_notifications, timezone
```

**Notification Channels (Android):**

| Channel ID | Nama | Fungsi |
|-----------|------|--------|
| `bill_channel` | Tagihan | Reminder jatuh tempo |
| `test_channel_v2` | Tes Notifikasi | Verifikasi fitur |
| `smart_alerts_channel` | Alert Pintar | Anomali pengeluaran |

**Scheduling Logic (Bill Reminders):**
- **H-Day** (Hari-H): Notifikasi jam 09:00 → `bill.id * 2`
- **H-1** (Sehari sebelum): Notifikasi jam 09:00 → `bill.id * 2 + 1`
- Menggunakan `zonedSchedule` dengan timezone-aware scheduling

### 5.6 OCRService

```
Lokasi:  lib/services/ocr_service.dart
Pattern: Instance (non-singleton)
Deps:    image_picker, google_mlkit_text_recognition, LocalAIEngine
```

**Pipeline:**
```
Camera/Gallery → ImagePicker → ML Kit TextRecognizer → LocalAIEngine.extractReceiptData() → {amount, category, title}
```

### 5.7 LocalAIEngine

```
Lokasi:  lib/services/local_ai_engine.dart
Pattern: Instance
Deps:    intl, models/*
```

Engine AI lokal (tanpa API call) dengan 3 fungsi utama:

1. **processQuery()** — Chatbot keuangan
2. **extractReceiptData()** — Parsing struk OCR
3. **detectUnusualSpending()** — Smart alert anomali

*(Detail lengkap di [Bagian 13](#13-ai-engine--ocr-pipeline))*

### 5.8 StreakService

```
Lokasi:  lib/services/streak_service.dart
Pattern: Static methods
Deps:    home_widget, shared_preferences
```

| Method | Fungsi |
|--------|--------|
| `init()` | Set app group ID untuk HomeWidget |
| `recordActivity()` | Catat aktivitas hari ini, hitung streak |

**Logika Streak:**
- `difference == 0` → Sudah login hari ini, streak tetap
- `difference == 1` → Konsekutif, `streak++`
- `difference > 1` → Reset ke `1`
- Data juga dikirim ke Android Home Widget via `HomeWidget.saveWidgetData()`

---

## 6. State Management (Riverpod)

### 6.1 Provider Map

```dart
// ─── SIMPLE PROVIDERS ─────────────────────────────────────
navigationProvider        : StateProvider<int>              // Index bottom nav
streakProvider            : StateProvider<int>              // Streak count
sharedPreferencesProvider : Provider<SharedPreferences>     // Injected at startup

// ─── AUTH PROVIDERS ───────────────────────────────────────
authServiceProvider       : Provider<AuthService>           // Singleton instance
authStateProvider         : StreamProvider<User?>            // Firebase auth stream
isSignedInProvider        : Provider<bool>                  // Computed: non-anonymous?

// ─── DATA PROVIDERS (StateNotifier) ───────────────────────
settingsProvider          : StateNotifierProvider<SettingsNotifier, SettingsState>
walletsProvider           : StateNotifierProvider<WalletsNotifier, List<Wallet>>
transactionsProvider      : StateNotifierProvider<TransactionsNotifier, List<Transaction>>
billsProvider             : StateNotifierProvider<BillsNotifier, List<Bill>>
budgetsProvider           : StateNotifierProvider<BudgetsNotifier, List<Budget>>
goalsProvider             : StateNotifierProvider<GoalsNotifier, List<FinancialGoal>>
socialProvider            : StateNotifierProvider<SocialNotifier, SocialState>

// ─── COMPUTED PROVIDERS & CACHING ─────────────────────────
walletTransactionsProvider: Provider.family<List<Transaction>, int> // Cache tx per wallet
walletBalanceProvider     : Provider.family<double, int>    // Saldo per wallet dari cached tx
totalNetWorthProvider     : Provider<double>                // Total semua wallet
```

### 6.2 SettingsState

Semua settings persisted via `SharedPreferences`:

| Field | Key | Default | Tipe |
|-------|-----|---------|------|
| `isNotificationsEnabled` | `notifications_enabled` | `false` | `bool` |
| `isSmartAlertsEnabled` | `smart_alerts_enabled` | `false` | `bool` |
| `isInsightDismissed` | `insight_dismissed` | `false` | `bool` |
| `isDarkMode` | `dark_mode` | `false` | `bool` |
| `languageCode` | `language_code` | `'id'` | `String` |
| `userName` | `user_name` | `'User Fina'` | `String` |
| `profilePhotoPath` | `profile_photo_path` | `null` | `String?` |

### 6.3 Pola Provider — CRUD + Side Effects

Setiap `StateNotifier` mengikuti pola konsisten:

```dart
class XxxNotifier extends StateNotifier<List<Xxx>> {
  final DatabaseService _dbService;
  final Ref _ref;

  XxxNotifier(this._dbService, this._ref) : super([]) {
    loadXxx();  // Auto-load saat init
  }

  Future<void> loadXxx() async {
    state = await _dbService.getAllXxx();
  }

  Future<void> addXxx(Xxx item) async {
    await _dbService.createXxx(item);
    await loadXxx();        // Refresh state
    _triggerBackup(_ref);   // Auto-backup ke cloud
  }

  // ... removeXxx, updateXxx follow same pattern
}
```

**Side effects setelah setiap mutasi:**
1. `loadXxx()` — Refresh state dari DB
2. `_triggerBackup(ref)` — Background cloud backup (jika user signed in)

> ⚠️ **Koreksi:** Implementasi nyata bukan method privat `_triggerBackup()` di tiap notifier, melainkan `DatabaseBackupHelper.triggerBackup(ref)` — class statis yang didefinisikan langsung di `lib/providers/database_provider.dart` (bukan file terpisah `utils/database_backup_helper.dart` seperti disebut di beberapa versi dokumen sebelumnya). Semua provider CRUD memanggil `DatabaseBackupHelper.triggerBackup(ref)` dari situ.

### 6.4 Wallet Balance Calculation

```dart
// Saldo dihitung real-time menggunakan cache dari walletTransactionsProvider
walletTransactionsProvider = Provider.family<List<Transaction>, int>((ref, walletId) {
  final allTransactions = ref.watch(transactionsProvider);
  return allTransactions.where((tx) => tx.walletId == walletId || tx.toWalletId == walletId).toList();
});

walletBalanceProvider = Provider.family<double, int>((ref, walletId) {
  final transactions = ref.watch(walletTransactionsProvider(walletId));
  double balance = 0;

  for (var tx in transactions) {
    if (tx.walletId == walletId) {
      if (tx.type == income || tx.type == initial) {
        balance += tx.amount;
      } else if (tx.type == expense || tx.type == transfer) {
        balance -= tx.amount;
        balance -= tx.adminFee;  // Admin fee juga dipotong
      }
    } else if (tx.toWalletId == walletId && tx.type == transfer) {
      balance += tx.amount;  // Terima transfer (tanpa admin fee)
    }
  }
  return balance;
});
```

**Formula:**
```
Saldo Wallet = Σ(income + initial) - Σ(expense + transfer + adminFee) + Σ(incoming transfers)
```

---

## 7. Screens & Navigation

### 7.1 Navigation Structure

```
SplashScreen (entry point)
    │
    ▼ (setelah 3 detik + auto-sync)
MainScreen (shell)
    │
    ├─ [0] DashboardScreen      ← DASHBOARD
    ├─ [1] StatsScreen           ← LAPORAN
    ├─ [2] BillsScreen           ← TAGIHAN
    ├─ [3] GoalsScreen           ← TARGET
    ├─ [4] ConnectionsScreen     ← HUBUNGAN
    └─ [5] AIScreen              ← AI

Sub-screens (via Navigator.push):
    ├─ AddTransactionScreen
    ├─ AddBillScreen
    ├─ AddGoalScreen
    ├─ TransactionsScreen       (riwayat lengkap)
    ├─ WalletsScreen            (manage dompet)
    ├─ SettingsScreen
    ├─ ShareDataScreen          (publikasi + QR)
    └─ SharedDetailScreen       (detail data koneksi)
```

### 7.2 Screen Responsibilities

| Screen | Ukuran (bytes) | Fungsi Utama |
|--------|-------------|-------------|
| `dashboard_screen` | 32KB | Net worth, recent tx, chart, AI insight card, streak badge |
| `settings_screen` | 25KB | Dark mode, notif, profile, backup/restore, language |
| `bills_screen` | 25KB | List tagihan, swipe-to-pay, overdue indicator |
| `stats_screen` | 29KB | Rekapitulasi, time-range filter (7D/30D), cash flow trend, detail pemasukan & pengeluaran |
| `wallets_screen` | 21KB | Multi-wallet CRUD, balance per wallet |
| `transactions_screen` | 20KB | Full transaction history, filter, swipe-to-delete |
| `goals_screen` | 19KB | Goal cards, progress bar, add savings |
| `add_bill_screen` | 16KB | Form tagihan (kategori, nominal, tanggal) |
| `add_transaction_screen` | 13KB | Form transaksi + OCR scan button |
| `add_goal_screen` | 13KB | Form target (emoji picker, color picker) |
| `ai_screen` | 9KB | Chat UI, query processing |
| `share_data_screen` | 9KB | Publish snapshot, show QR code |
| `connections_screen` | 8KB | List koneksi, scan QR, accept/reject |
| `shared_detail_screen` | 7KB | Read-only view data koneksi |
| `splash_screen` | 5KB | Logo animation, auto-restore |
| `main_screen` | 2KB | BottomNavBar shell + IndexedStack |

### 7.3 Navigation Pattern

- **Main tabs**: `IndexedStack` + `BottomNavigationBar` (6 tabs)
- **Sub-screens**: `Navigator.push()` dengan `MaterialPageRoute`
- **Splash → Main**: `Navigator.pushReplacement()` dengan `FadeTransition`
- **State via Riverpod**: `navigationProvider` (StateProvider<int>) untuk tab index

---

## 8. Widgets (Reusable Components)

### 8.1 StreakBadge

```dart
// File: lib/widgets/streak_badge.dart
StreakBadge(
  streakCount: 7,     // Jumlah hari berturut-turut
  top: 0,             // Posisi dalam Stack
  right: 0,
)
```

- Menampilkan 🔥 icon + counter
- Menggunakan local `Theme()` override untuk isolasi styling
- Pattern: `Theme → Stack → Positioned → Container`

### 8.2 SuccessModal

```dart
// File: lib/widgets/success_modal.dart
SuccessModal.show(
  context: context,
  title: 'Berhasil!',
  subtitle: 'Transaksi telah dicatat',
  buttonText: 'OK',
  onConfirm: () => Navigator.pop(context),
);
```

- Dialog dengan animasi `ScaleTransition` + `FadeTransition`
- Ikon ✅ dengan `TweenAnimationBuilder` (elastic bounce effect)
- `showGeneralDialog()` untuk full control transisi

---

## 9. Design System & Theming

### 9.1 Color Palette

**Light Mode:**

| Token | Hex | Penggunaan |
|-------|-----|-----------|
| `background` | `#FDFDFD` | Scaffold background |
| `cardPaleBlue` | `#F1F5FB` | Card surface |
| `ctaAqua` | `#00BFA5` | CTA buttons, accents |
| `textDarkBlue` | `#0D1B2A` | Primary text |
| `textMuted` | `#62727B` | Secondary text |
| `borderColor` | `#E0E6ED` | Card borders |
| `error` | `#D32F2F` | Error states |

**Dark Mode:**

| Token | Hex | Penggunaan |
|-------|-----|-----------|
| `darkBackground` | `#0A0E12` | Deep obsidian scaffold |
| `darkCard` | `#151D26` | Dark navy cards |
| `darkBorder` | `#242F3D` | Subtle borders |
| `darkTextPrimary` | `#FDFDFD` | Primary text |
| `darkTextMuted` | `#8B9BA8` | Muted blue-grey text |

**Gradients:**
- `mainGradient`: `[#0D1B2A → #1B263B]` — Header/splash backgrounds
- `accentGradient`: `[#00E5FF → #00BFA5]` — Highlights, accents
- `glassGradient`: `[0x33FFFFFF → 0x0DFFFFFF]` — Glass-morphism effect

### 9.2 Typography

**Font Family:** `Plus Jakarta Sans` (via Google Fonts)

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| `displayLarge` | 56px | w800 | Hero numbers (net worth) |
| `headlineSmall` | 24px | w800 | Section titles |
| `titleMedium` | 16px | w700 | Card titles |
| `bodyLarge` | 14px | w500 | Body text |
| `bodySmall` | 12px | w600 | Labels, captions |

### 9.3 Component Styling

| Component | Border Radius | Elevation | Notes |
|-----------|--------------|-----------|-------|
| Cards | 24px | 0 | Border: 1px solid `borderColor` |
| Buttons (Elevated) | 16px | 0 | Aqua bg, padding 24×16 |
| Dialogs | 28px | 20 | Via `SuccessModal` |
| Bottom Nav | — | 0 | Top border only |

### 9.4 Page Transitions

```dart
PageTransitionsTheme(
  builders: {
    TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
  },
)
```

---

## 10. Workflow & Data Flow

### 10.1 App Startup Flow

```
main() ──┬── WidgetsFlutterBinding.ensureInitialized()
         ├── StreakService.init()                    [non-web only]
         ├── Firebase.initializeApp()                [try-catch]
         ├── NotificationService().init()            [non-web only]
         ├── SharedPreferences.getInstance()
         └── runApp(ProviderScope(
               overrides: [sharedPreferencesProvider],
               child: FinaApp() → SplashScreen
             ))

SplashScreen ──┬── requestNotificationPermissions()
               ├── checkAndAutoSync()
               │   ├── Cek user signed in (non-anonymous)?
               │   ├── Local DB kosong? → Restore dari cloud
               │   └── Insert all restored data ke SQLite
               └── navigateToHome() [delay 3 detik]
                   └── FadeTransition → MainScreen
```

### 10.2 Add Transaction Flow

```
User tap [+] di Dashboard
    │
    ▼
AddTransactionScreen
    ├── Input: title, amount, type, category, date, wallet, note
    ├── [Opsional] Tap 📷 → OCRService.scanReceipt()
    │   ├── ImagePicker → ambil foto struk
    │   ├── ML Kit → extract text
    │   └── LocalAIEngine.extractReceiptData() → auto-fill form
    │
    ▼ User tap SIMPAN
    │
transactionsProvider.notifier.addTransaction(tx)
    ├── 1. DatabaseService.createTransaction(tx)     → Insert ke SQLite
    ├── 2. loadTransactions()                         → Refresh state
    ├── 3. settingsProvider.revealInsight()            → Reset AI insight card
    ├── 4. StreakService.recordActivity()              → Update streak
    ├── 5. [Smart Alerts] Jika expense:
    │   ├── LocalAIEngine.detectUnusualSpending()
    │   └── NotificationService.showSmartAlert()      → Push notifikasi
    └── 6. _triggerBackup(ref)                        → Background cloud sync
```

### 10.3 Pay Bill Flow

```
BillsScreen → User swipe bill → Pilih wallet
    │
    ▼
billsProvider.notifier.payBill(bill, walletId)
    ├── 1. Update bill → isPaid = true
    ├── 2. Create Transaction(type: expense) dari bill
    │   └── → Trigger full addTransaction flow (streak, alerts, backup)
    ├── 3. loadBills()
    └── 4. _triggerBackup(ref)
```

### 10.4 Social Sharing Flow

```
Pengirim:
    ShareDataScreen → publishSnapshot()
    ├── FirebaseService.publishSnapshot(data)
    │   ├── profiles/{uid} → name, updatedAt
    │   └── snapshots/{uid} → netWorth, wallets, totalExpense...
    └── Tampilkan QR Code (berisi UID)

Penerima:
    ConnectionsScreen → Scan QR → socialProvider.addConnection(uid, name)
    ├── FirebaseService.requestRelationship()
    │   └── relationships/{docId} → fromUid, toUid, status:'pending'
    └── Firestore listener auto-update state
```

### 10.5 Cloud Backup & Restore Flow

```
┌─ BACKUP (Otomatis setelah setiap mutasi data) ─────────┐
│                                                          │
│  _triggerBackup(ref)                                     │
│  ├── Cek: user signed in (non-anonymous)?                │
│  ├── Future.microtask() → Background, non-blocking       │
│  └── CloudSyncService.backupAll(                         │
│        uid, transactions, wallets, bills, budgets, goals │
│      )                                                   │
│      └── Firestore batch write → users/{uid}/backup/*    │
└──────────────────────────────────────────────────────────┘

┌─ RESTORE (Manual dari Settings / Auto dari SplashScreen) ┐
│                                                           │
│  CloudSyncService.restoreAll(uid)                         │
│  ├── Fetch 5 documents dari users/{uid}/backup/           │
│  ├── Parse JSON → Model objects                           │
│  ├── Clear local SQLite                                   │
│  └── Insert semua data ke SQLite                          │
└───────────────────────────────────────────────────────────┘
```

---

## 11. Business Logic Functions

### 11.1 Kalkulasi Saldo Wallet

```
Input:  List<Transaction>, walletId
Output: double (saldo)

Logic:
  UNTUK SETIAP transaksi:
    JIKA tx.walletId == walletId:
      JIKA income/initial  → saldo += amount
      JIKA expense/transfer → saldo -= (amount + adminFee)
    JIKA tx.toWalletId == walletId DAN type == transfer:
      saldo += amount  (terima tanpa admin fee)
```

### 11.2 Net Worth

```
Input:  List<Wallet>
Output: double

Logic:
  netWorth = Σ walletBalance(wallet.id) untuk semua wallet
```

### 11.3 Health Score (Skor Kesehatan Keuangan)

```
Input:  income, expense, needs, wants, savings
Output: int (0-100)

Breakdown (100 poin total):
  ┌─ Savings Rate (40 poin) ────────────────────┐
  │  ≥ 20%  → +40 poin                          │
  │  ≥ 10%  → +20 poin                          │
  │  > 0%   → +5 poin                           │
  └──────────────────────────────────────────────┘
  ┌─ Budget Discipline (30 poin) ────────────────┐
  │  Needs ≤ 50% income → +30 poin              │
  │  Needs ≤ 60% income → +15 poin              │
  └──────────────────────────────────────────────┘
  ┌─ Wants Control (30 poin) ────────────────────┐
  │  Wants ≤ 30% income → +30 poin              │
  │  Wants ≤ 40% income → +10 poin              │
  └──────────────────────────────────────────────┘
```

**Klasifikasi Kategori:**
- **Needs**: makanan, transportasi, kesehatan, cicilan, tagihan, listrik, air
- **Wants**: hiburan, belanja, hobi, jajan, nonton

### 11.4 Smart Alert (Deteksi Anomali)

```
Input:  existing transactions, new transaction
Output: List<String> (alert messages)

Logic:
  1. Hitung total expense bulan lalu
  2. Hitung total expense bulan ini (sebelum + sesudah transaksi baru)
  3. Alert A: Jika total bulan ini BARU SAJA melebihi total bulan lalu
  4. Alert B: Jika total KATEGORI bulan ini BARU SAJA melebihi bulan lalu
```

### 11.5 Streak Logic

```
Input:  lastLoggedDate, today
Output: int (streak count)

Logic:
  difference = today - lastLoggedDate (in days)
  
  JIKA difference == 0 → streak tetap (sudah login hari ini)
  JIKA difference == 1 → streak++ (konsekutif)
  JIKA difference > 1  → streak = 1 (reset)
  JIKA pertama kali    → streak = 1
```

### 11.6 Budget Monitoring

```
Input:  List<Transaction>, List<Budget>
Output: Map<category, {spent, limit, percentage}>

Logic:
  UNTUK SETIAP budget:
    Filter transaksi bulan ini dengan kategori == budget.category
    spent = Σ amount dari filtered transactions
    percentage = (spent / budget.limitAmount) * 100
    JIKA spent > limitAmount → FLAG exceeded
```

---

## 12. Firebase & Cloud Architecture

### 12.1 Firebase Services Used

| Service | Fungsi |
|---------|--------|
| **Firebase Auth** | Anonymous Auth + Google Sign-In |
| **Cloud Firestore** | Social sharing, backup/restore |

### 12.2 Firestore Data Structure

```
firestore-root/
│
├── profiles/{uid}
│   ├── uid: string
│   ├── name: string
│   └── updatedAt: timestamp
│
├── snapshots/{uid}
│   ├── uid: string
│   ├── name: string
│   ├── updatedAt: timestamp
│   └── ... (financial summary data)
│
├── relationships/{docId}          # docId = sorted "{uid1}_{uid2}"
│   ├── id: string
│   ├── uids: [uid1, uid2]        # Array for query
│   ├── fromUid: string
│   ├── toUid: string
│   ├── fromName: string
│   ├── toName: string
│   ├── status: 'pending' | 'accepted'
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp
│
└── users/{uid}
    ├── uid: string
    ├── userName: string
    ├── photoUrl: string?
    ├── lastSyncAt: timestamp
    └── backup/                    # Subcollection
        ├── transactions → { data: [...], updatedAt }
        ├── wallets      → { data: [...], updatedAt }
        ├── bills        → { data: [...], updatedAt }
        ├── budgets      → { data: [...], updatedAt }
        └── goals        → { data: [...], updatedAt }
```

### 12.3 Security Considerations

- Relationship `docId` menggunakan **sorted UID** untuk prevent duplicate docs
- Anonymous auth digunakan sebagai fallback, Google Sign-In untuk backup
- Link anonymous → Google account saat pertama kali sign in
- Backup dilakukan via `Future.microtask()` → non-blocking UI

---

## 13. AI Engine & OCR Pipeline

### 13.1 AI Chatbot (processQuery)

**Intent Detection** menggunakan **keyword matching + fuzzy search (Levenshtein distance)**:

| Intent | Keywords | Response |
|--------|----------|----------|
| `greeting` | halo, hai, pagi, siang, malam | Sapaan + CTA |
| `status` | saldo, uang, balance, dompet | Ringkasan arus kas + skor |
| `analysis` | analisis, kesehatan, evaluasi, boros | Analisis 50/30/20 |
| `savings` | dana darurat, simpanan, hemat | Evaluasi dana darurat (3 bulan) |
| `bills` | tagihan, cicilan, hutang, bayar | Ringkasan tagihan + overdue |
| `budget` | anggaran, budget, limit, kuota | Monitoring budget per kategori |
| `comparison` | bandingkan, bulan lalu, vs | Perbandingan bulan ini vs lalu |
| `invest` | investasi, saham, reksadana, emas | Saran alokasi surplus |
| `rekap` | rekap, detail, kategori, rincian | Top 3 kategori terboros |
| `help` | bantuan, fitur, tolong, help | Daftar kemampuan AI |
| `inflation` | inflasi, uang aman, runway, pensiun, masa depan | Kalkulasi prediksi uang aman untuk X tahun dengan asumsi inflasi tahunan 5% |

**Fuzzy Matching:**
- Menggunakan **Levenshtein distance** untuk toleransi typo
- Threshold: ≤ 2 karakter perbedaan
- Hanya untuk kata ≥ 3 karakter
- Memberikan saran: "Apakah yang Anda maksud adalah **xxx**?"

### 13.2 OCR Receipt Parsing (extractReceiptData)

```
Raw OCR Text
    │
    ▼ Text Normalization
    │
    ├── Strategy A: Keyword Search (paling akurat)
    │   Cari "total", "grand total", "jumlah", "netto", "amount", "bayar"
    │   → Ambil angka di baris yang sama atau baris berikutnya
    │
    ├── Strategy B: Highest Number (fallback)
    │   Regex: /(?:\d{1,3}(?:\.\d{3})+|\d{4,})/
    │   → Ambil angka terbesar (100 < x < 100.000.000)
    │
    ├── Category Detection
    │   ├── Makanan: makan, resto, cafe, kopi, kfc, mcd...
    │   ├── Belanja: beli, shop, indomaret, alfamart, tokopedia...
    │   ├── Transportasi: grab, gojek, bensin, parkir, tol...
    │   ├── Hiburan: nonton, cinema, spotify, netflix, game...
    │   ├── Kesehatan: apotek, obat, rumah sakit, klinik...
    │   └── Default: Lainnya
    │
    └── Title Detection
        Cari baris pertama tanpa angka (biasanya nama toko)
        → UPPERCASE sebagai judul transaksi
```

**Output:**
```dart
{
  'amount': 150000.0,        // Total dari struk
  'category': 'Makanan',     // Auto-detect
  'title': 'RESTORAN XYZ',  // Nama toko dari OCR
}
```

---

## 14. Notification System

### 14.1 Architecture

```
NotificationService (Singleton)
    │
    ├── init()                    → Initialize timezone, plugin, channels
    ├── requestPermissions()      → POST_NOTIFICATIONS + exact alarms
    ├── scheduleBillReminders()   → H-Day + H-1 scheduled notifications
    ├── cancelBillReminders()     → Cancel by bill ID
    ├── showSmartAlert()          → Immediate push for spending anomaly
    └── showTestNotification()    → Verify notification works
```

### 14.2 Notification ID Strategy

```
Bill Reminders:
  H-Day notification ID = bill.id * 2
  H-1   notification ID = bill.id * 2 + 1

Smart Alerts:  ID = 888 (static, latest overrides)
Test:          ID = 999 (static)
```

### 14.3 Platform Support

| Feature | Android | iOS | Web |
|---------|---------|-----|-----|
| Local Notifications | ✅ | ✅ | ❌ |
| Scheduled (Exact) | ✅ | ✅ | ❌ |
| Permission Request | ✅ (Android 13+) | ✅ | ❌ |
| Channels | ✅ (3 channels) | N/A | N/A |

---

## 15. Dependency Map

### 15.1 Pub Dependencies

| Package | Versi | Kategori | Fungsi |
|---------|-------|----------|--------|
| `flutter_riverpod` | ^2.5.1 | State Management | Provider-based state |
| `sqflite` | ^2.3.2 | Database | SQLite local storage |
| `path` | ^1.9.0 | Database | Path utilities |
| `flutter_local_notifications` | ^17.1.2 | Notifications | Local push notifications |
| `timezone` | ^0.9.2 | Notifications | Timezone-aware scheduling |
| `flutter_timezone` | ^5.0.0 | Notifications | Get device timezone |
| `intl` | ^0.19.0 | UI | Number/date formatting |
| `google_fonts` | ^6.2.1 | UI | Plus Jakarta Sans font |
| `percent_indicator` | ^4.2.3 | UI | Circular/linear progress |
| `fl_chart` | ^1.2.0 | UI | Bar/pie charts |
| `shared_preferences` | ^2.5.5 | Storage | Settings persistence |
| `flutter_markdown` | ^0.7.7+1 | UI | Render AI responses |
| `http` | ^1.2.1 | Network | HTTP client |
| `firebase_core` | ^3.1.0 | Firebase | Core initialization |
| `cloud_firestore` | ^5.0.1 | Firebase | NoSQL cloud database |
| `firebase_auth` | ^5.1.1 | Firebase | Authentication |
| `google_sign_in` | ^6.2.1 | Auth | Google OAuth |
| `qr_flutter` | ^4.1.0 | Social | QR code generator |
| `mobile_scanner` | ^5.1.1 | Social | QR code scanner |
| `image_picker` | ^1.1.2 | OCR | Camera/gallery picker |
| `google_mlkit_text_recognition` | ^0.13.0 | OCR | On-device text recognition |
| `flutter_launcher_icons` | ^0.13.1 | Build | App icon generation |
| `home_widget` | ^0.8.0 | Widget | Android home screen widget |
| `sqflite_common_ffi` | ^2.4.0+3 | Dev/Test | `databaseFactoryFfi` untuk widget test yang menyentuh `DatabaseService` sungguhan (lihat `test/app_ui_test.dart`) |

### 15.2 Internal Dependency Graph

```
main.dart
  ├── screens/splash_screen.dart
  │     ├── services/notification_service.dart
  │     ├── services/auth_service.dart
  │     ├── services/cloud_sync_service.dart
  │     └── services/database_service.dart
  ├── theme/app_theme.dart
  │     └── theme/colors.dart
  ├── providers/settings_provider.dart
  └── services/streak_service.dart

providers/database_provider.dart  (BARREL FILE)
  ├── providers/budget_provider.dart
  ├── providers/wallet_provider.dart
  ├── providers/transaction_provider.dart
  ├── providers/bill_provider.dart
  └── providers/goal_provider.dart

providers/wallet_provider.dart dkk
  ├── services/database_service.dart
  ├── providers/database_provider.dart  (DatabaseBackupHelper.triggerBackup)
  └── models/* (semua model)

providers/social_provider.dart
  ├── services/firebase_service.dart
  └── providers/settings_provider.dart

providers/auth_provider.dart
  └── services/auth_service.dart
```

---

## 16. Konvensi & Panduan Pengembangan

### 16.1 Naming Conventions

| Item | Convention | Contoh |
|------|-----------|--------|
| File | `snake_case.dart` | `database_service.dart` |
| Class | `PascalCase` | `DatabaseService` |
| Variable/Method | `camelCase` | `loadTransactions()` |
| Constant | `camelCase` | `_storageKey` |
| Enum | `PascalCase.camelCase` | `TransactionType.income` |
| Provider | `camelCase + Provider` | `walletsProvider` |
| Screen | `PascalCase + Screen` | `DashboardScreen` |

### 16.2 Architecture Rules

1. **Model Layer**
   - Semua field `final` (immutable)
   - Wajib punya `toMap()` dan `factory fromMap()`
   - Wajib punya `copyWith()` jika model bisa di-update
   - Tidak boleh import package Flutter (kecuali `Color` di `Wallet`)

2. **Service Layer**
   - Singleton via `factory` constructor
   - Tidak boleh import/menggunakan Riverpod
   - Tidak boleh import Widgets/Screens
   - Error handling dengan try-catch + `debugPrint()`

3. **Provider Layer**
   - `StateNotifier` untuk mutable state collections
   - `StateProvider` untuk single value state
   - `Provider` untuk computed/derived values
   - `StreamProvider` untuk reactive streams
   - Semua mutasi harus memanggil `_triggerBackup()`

4. **Screen Layer**
   - Extend `ConsumerWidget` atau `ConsumerStatefulWidget`
   - Gunakan `ref.watch()` untuk reactive data
   - Gunakan `ref.read()` untuk one-time actions
   - Navigasi via `Navigator.push()` / `Navigator.pop()`

### 16.3 Error Handling Pattern

```dart
// Service level: catch + debugPrint (never crash)
try {
  await someOperation();
} catch (e) {
  debugPrint('ServiceName: Operation failed: $e');
}

// Provider level: catch in notifier methods
// Screen level: show SnackBar/Dialog to user
```

### 16.4 Testing

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

> ✅ **Status Testing (diverifikasi ulang 19 Agustus 2026 via `flutter test`):**
> 9 dari 9 pengujian (Unit & Integration Tests) berhasil dilalui (100% passed, exit code 0).
> 
> Area utama yang telah diuji:
> 1. `walletBalanceProvider` — Kalkulasi kritis & filter cache (`walletTransactionsProvider`)
> 2. Integration: Interaksi komponen & inisialisasi dengan mock `SharedPreferences`
> 3. Singleton/DI (`LocalAIEngine`, `OCRService`, `StreakService`), serialisasi model, benchmark performa `LocalAIEngine`
>
> ✅ **Update 19 Agustus 2026:** `test/app_ui_test.dart` ("Button Click Test") sebelumnya hanya mencetak jumlah tombol tanpa `expect()` apa pun (selalu "lulus" walau 0 tombol ditemukan). Sudah ditulis ulang dengan assertion nyata (`expect(totalTappable, greaterThan(0))`), memompa `MainScreen` langsung dengan `databaseFactoryFfi` (`sqflite_common_ffi`, dev dependency baru) agar provider berbasis database bisa diuji sungguhan. Detail riwayat bug ini ada di [Bagian 18](#18-known-issues--bug-backlog).

### 16.5 Environment Setup

1. Install [Flutter SDK](https://docs.flutter.dev/get-started/install) (≥3.0.0 <4.0.0)
2. Clone repository
3. Copy `.env.example` → `.env` (isi API keys)
4. `flutter pub get`
5. Tambahkan `google-services.json` ke `android/app/`
6. `flutter run`

### 16.6 Checklist Sebelum PR

- [ ] Semua model baru punya `toMap()`, `fromMap()`, `copyWith()`
- [ ] Service baru menggunakan Singleton pattern
- [ ] Provider baru memanggil `_triggerBackup()` setelah mutasi
- [ ] Migration DB di-handle di `_upgradeDB()` dengan version bump
- [ ] Error handling: tidak ada uncaught exceptions
- [ ] Responsive: test di light mode & dark mode
- [ ] Tidak ada hardcoded strings (gunakan variable/constant)

---

## 17. Platform Integrations

### 17.1 Android Home Widget (Streak Tracking)

Aplikasi memiliki Android Home Widget asli (`FinaWidgetProvider.kt`) untuk melacak status aktivitas harian (streak) di layar beranda perangkat.
- **Happy State**: Menampilkan ikon ceria (bunga matahari) jika pengguna telah mencatat aktivitas hari ini.
- **Withered State**: Menampilkan ikon layu jika pengguna belum mencatat aktivitas hari ini. Latar belakang widget berubah warna dinamis berdasarkan waktu sebagai peringatan visual:
  - Sebelum 15:00: Normal
  - 15:00 - 17:00: Warning (Orange)
  - Setelah 17:00: Alert (Red)
- **Komunikasi Data**: Data disinkronisasi menggunakan library `home_widget` yang membaca dan menulis state (`streak_count` dan `last_logged_date`) ke `SharedPreferences`. Sinkronisasi di-trigger oleh `StreakService` (Flutter).

---

## 18. Known Issues & Bug Backlog

> Hasil audit codebase 19 Agustus 2026 (analisis statis + `flutter test`). **Status: semua 20 item di bawah sudah diperbaiki pada 19 Agustus 2026** (lihat commit terkait) dan diverifikasi lulus `flutter analyze` + `flutter test` (9/9 pass). Bagian ini dipertahankan sebagai riwayat/referensi — jangan dihapus. Jika menemukan bug baru, tambahkan entri baru dengan format yang sama.

### 🔴 Kritis (crash / kehilangan data diam-diam)

- [x] **Crash: `double.parse` tanpa validasi di form Target Finansial**
  `lib/screens/add_goal_screen.dart` (field `_savedController`). Jika field "SUDAH TERKUMPUL" dikosongkan lalu tombol simpan ditekan, `double.parse('')` melempar `FormatException` yang tidak tertangkap → aplikasi crash saat edit goal.
  **Fix diterapkan**: tambah `validator` pada field + ganti `double.parse` jadi `double.tryParse(...) ?? 0` di `_saveGoal()`.

- [x] **Crash relokasi: kegagalan Firebase init hanya di-`debugPrint`, lalu crash di layar lain**
  `lib/main.dart` menelan error `Firebase.initializeApp()` dan tetap `runApp()`, tapi `AuthService`/`FirebaseService`/`CloudSyncService` mengakses `FirebaseAuth.instance`/`FirebaseFirestore.instance` sebagai field initializer yang throw sinkron jika belum ada default Firebase App.
  **Fix diterapkan**: ketiga service diubah agar mengecek `Firebase.apps.isNotEmpty` sebelum menyentuh instance Firebase — `AuthService`/`FirebaseService` via getter nullable (`_authOrNull`/`_dbOrNull`, return `null`/no-op jika belum siap), `CloudSyncService` via lazy getter yang throw *di dalam* try/catch method publiknya (bukan saat konstruksi). Konstruksi singleton-nya sendiri kini aman dipanggil kapan pun.

- [x] **Silent data loss: status koneksi sosial bisa ter-overwrite balik ke `pending`**
  `lib/services/firebase_service.dart` (`requestRelationship`) menulis dengan `.set()` tanpa `merge` ke doc id yang sama yang dipakai kedua user; `removeConnection` hanya filter state lokal, tidak pernah hapus dokumen Firestore.
  **Fix diterapkan**: `requestRelationship` sekarang cek dokumen existing dulu — no-op jika status sudah `accepted` (tidak ditimpa balik jadi pending) — dan pakai `SetOptions(merge: true)`. Ditambahkan `FirebaseService.deleteRelationship()` yang benar-benar dipanggil dari `SocialNotifier.removeConnection()`. UI tolak/hapus koneksi ditambahkan di `connections_screen.dart` (swipe-to-delete + tombol TOLAK untuk request masuk).

- [x] **Silent data loss: kegagalan auto-backup ke cloud sepenuhnya tidak terlihat**
  `CloudSyncService.backupAll`/`DatabaseBackupHelper.triggerBackup` menelan semua exception dengan `debugPrint` saja, tanpa jalur feedback UI.
  **Fix diterapkan**: `SettingsState` sekarang punya `lastBackupStatus`/`lastBackupAt` (persisted via SharedPreferences), diisi oleh `SettingsNotifier.recordBackupResult()` yang dipanggil dari `DatabaseBackupHelper.triggerBackup` di kedua cabang (sukses/gagal). Settings screen menampilkan banner merah "Backup otomatis terakhir gagal" saat status terakhir `failed`.

### 🟠 Tinggi (kesimpulan finansial yang salah ke pengguna)

- [x] **Salah hitung dana darurat: memakai total pengeluaran *seumur hidup* sebagai "rata-rata bulanan"**
  `local_ai_engine.dart` `_getSavingsResponse` memakai `expense` (lifetime) sebagai `monthlyAvg`, melipatgandakan target dana darurat untuk user dengan riwayat panjang.
  **Fix diterapkan**: `processQuery` sekarang menghitung `thisMonthExpense` (difilter ke bulan berjalan, pola yang sama dengan `_getInflationResponse`) dan meneruskannya ke `_getSavingsResponse` sebagai basis "rata-rata bulanan", bukan total lifetime.

- [x] **Kategori "Needs" tidak mencakup semua kategori tagihan → skor kesehatan finansial terlalu optimis**
  Daftar needs tidak mencakup `internet`, `sewa`, `asuransi` (kategori tagihan asli di `constants.dart`), dan kategori tak dikenal (termasuk `lainnya`) di-drop total dari perhitungan.
  **Fix diterapkan**: `internet`, `sewa`, `asuransi` ditambahkan ke daftar needs; semua kategori lain yang tak dikenal kini jatuh ke bucket `wants` (default konservatif) alih-alih hilang dari perhitungan sama sekali.

- [x] **Silent failure: publish snapshot ke cloud tanpa error handling**
  `share_data_screen.dart` `_publishData()` punya `try { ... } finally { ... }` tanpa `catch`, dan selalu menampilkan pesan sukses walau publish gagal secara internal.
  **Fix diterapkan**: `FirebaseService.publishSnapshot()` sekarang mengembalikan `bool` (sukses/gagal), dan `_publishData()` menampilkan SnackBar sukses/gagal sesuai hasil sebenarnya, plus `catch` untuk exception tak terduga.

### 🟡 Sedang (fitur tidak berfungsi / diam-diam gagal)

- [x] **Tidak ada tombol tolak/hapus koneksi** — ditambahkan swipe-to-delete (dengan dialog konfirmasi) untuk koneksi accepted/outgoing-pending, dan tombol TOLAK (ikon X merah) di samping ACC untuk request masuk, di `connections_screen.dart`.
- [x] **Pengaturan Bahasa (language selector) tidak berefek apa pun** — opsi "English" sekarang ditandai badge "SEGERA HADIR" dan menampilkan dialog info jujur (mengikuti pola `_showBiometricInfo` yang sudah ada) alih-alih pura-pura berhasil menerapkan bahasa yang sebenarnya tidak berubah.
- [x] **Reminder tagihan tidak dibatalkan saat lunas** — `BillsNotifier.payBill()` sekarang memanggil `NotificationService().cancelBillReminders(bill.id!)` sebelum membuat transaksi pembayaran.
- [x] **Tabrakan ID notifikasi** — skema ID reminder tagihan diberi offset besar (`100000 + bill.id*2` / `+1`) via helper `_dayOfReminderId`/`_h1ReminderId`, sehingga tidak mungkin lagi bertabrakan dengan ID statis `888`/`999`.
- [x] **Exact-alarm permission gagal tanpa fallback** — ditambahkan `_zonedScheduleWithFallback()`: coba `exactAllowWhileIdle` dulu, jika gagal (mis. izin dicabut) otomatis fallback ke `inexactAllowWhileIdle` alih-alih diam-diam tidak menjadwalkan apa pun.
- [x] **Off-by-one batas "bulan lalu" di deteksi anomali** — `lastMonthEnd` diubah dari `DateTime(y, m, 0)` (00:00:00) menjadi `DateTime(y, m, 0, 23, 59, 59)`, konsisten dengan pola di `stats_screen.dart`.
- [x] **Pembagian oleh nol pada Budget** — ditambahkan guard `limitAmount > 0` sebelum pembagian di `local_ai_engine.dart` (`_getBudgetResponse`), `dashboard_screen.dart`, dan `stats_screen.dart`; form "Atur Anggaran" di `stats_screen.dart` sekarang menolak input ≤ 0 dengan SnackBar.

### 🟢 Rendah (edge case / kosmetik)

- [x] Saldo awal wallet negatif — `.abs()` dihapus dari `wallet_provider.dart` sehingga saldo awal negatif (representasi utang) benar-benar mengurangi saldo, bukan ditambahkan sebagai kredit.
- [x] `wallets_screen.dart` — input saldo awal sekarang divalidasi; input non-numerik menampilkan SnackBar error alih-alih diam-diam jadi `0`.
- [x] `goals_screen.dart` — dialog "Tambah Tabungan" sekarang menampilkan SnackBar jika input invalid/≤0, alih-alih diam saja.
- [x] `AuthService.signOut()` — dipecah jadi 2 try/catch terpisah (Google, Firebase) supaya satu kegagalan tidak menutupi kegagalan lainnya.
- [x] `FinancialGoal.fromMap`, `Bill.fromMap`, dan `Transaction.fromMap` — ditambahkan `.toDouble()` yang konsisten pada semua field numerik (sebelumnya `Transaction.amount`/`Bill.amount`/`FinancialGoal.targetAmount`/`savedAmount` tidak dikonversi, berisiko error tipe saat restore dari cloud jika Firestore mengembalikan `int`).
- [x] Test `app_ui_test.dart` "Button Click Test" — ditulis ulang dengan assertion nyata (`expect(totalTappable, greaterThan(0))`), memompa `MainScreen` langsung dengan `sqflite_common_ffi` (`databaseFactoryFfi`) supaya provider berbasis database bisa diuji sungguhan tanpa perlu mock manual.

### Catatan untuk audit berikutnya

Saat menemukan bug baru, tambahkan entri dengan format yang sama (file:line, skenario kegagalan, fix) di bagian yang sesuai tingkat keparahannya, dan jangan hapus histori item yang sudah `[x]` — itu adalah dokumentasi bahwa bug tersebut sudah pernah ada dan sudah ditangani.

### Audit Round 2 — 20 Agustus 2026 (semua sudah diperbaiki `[x]`)

Dipicu oleh dua perubahan sebelumnya (perluasan kategori OCR `local_ai_engine.dart` + retheme warna aksen ke hijau logo `colors.dart`). Semua item di bawah sudah diverifikasi manual dan di-fix, lulus `flutter analyze` + `flutter test` (9/9).

- [x] **Keyword `'mart'` di kategori Makanan menutupi semua deteksi Belanja** — `local_ai_engine.dart` (Category Detection): `'mart'` sebagai substring generic membuat `indomaret`/`alfamart`/`supermarket`/`transmart`/`hypermart` (semua mengandung substring "mart") tidak pernah ter-reach karena Makanan dicek lebih dulu di rantai if/else-if. **Fix**: hapus `'mart'` dari daftar Makanan.
- [x] **Warna teal lama (`0xFF00BFA5`) masih hardcoded di beberapa tempat, tidak ikut retheme** — `models/financial_goal.dart` (default `color`), `screens/add_goal_screen.dart` (termasuk swatch yang dilabeli **"Hijau" tapi nilainya teal**, bukan hijau), `screens/goals_screen.dart` (fallback parse warna), `services/database_service.dart` (2 tempat, DEFAULT kolom SQL `financial_goals.color`). **Fix**: semua diganti ke `0xFF4CAF50` (hijau logo, sama dengan `AppColors.ctaAqua`).
- [x] **Wallet bisa dihapus meski masih punya transaksi → transaksi jadi orphan** — `database_service.dart` `deleteWallet()` tidak cascade-delete/cek transaksi terkait; `totalNetWorthProvider` cuma jumlah wallet yang masih ada, jadi saldo wallet yang dihapus hilang diam-diam dari net worth sementara transaksinya tetap nongkrong di riwayat selamanya. **Fix**: `wallets_screen.dart` `confirmDismiss` sekarang cek `walletTransactionsProvider(wallet.id)` dan blokir penghapusan (dengan SnackBar) kalau masih ada transaksi.
- [x] **StreakBadge di dashboard nampilin angka basi, beda sama Home Widget Android** — `streak_provider.dart` cuma baca `streak_count` mentah dari prefs, gak pernah re-validasi apakah sudah lewat > 1 hari sejak aktivitas terakhir (`FinaWidgetProvider.kt` di sisi native sudah benar melakukan ini). User yang skip 1 hari dan buka app tanpa nambah transaksi akan lihat streak lama di dashboard padahal home widget udah benar nampilin 0. **Fix**: `streakProvider` sekarang menghitung ulang "masih hidup atau nggak" pakai `last_logged_date`, sama persis logika Kotlin-nya.
- [x] **AI chat macet permanen di "sedang mengetik" kalau `processQuery()` error** — `ai_screen.dart` gak ada try/catch di sekitar pemanggilan engine; exception apa pun bikin `_isTyping` gak pernah balik ke `false`. **Fix**: dibungkus try/catch, tampilkan pesan error yang wajar ke user kalau gagal.
- [x] **Empty-state card di Dashboard hardcode putih, rusak di dark mode** — `dashboard_screen.dart` `_buildEmptyState` pakai `Colors.white`/`AppColors.cardPaleBlue`/`AppColors.textMuted` langsung (semua warna mode terang), beda sendiri dari card lain yang sudah theme-aware. **Fix**: ganti ke `Theme.of(context).cardTheme.color`/`colorScheme.surfaceContainerHighest`/`colorScheme.onSurface`.
- [x] **Off-by-milidetik di filter "Bulan Lalu"** — `stats_screen.dart` batas atas `DateTime(y, m, 0, 23, 59, 59)` (milidetik = 0) membuang transaksi di detik terakhir bulan lalu yang punya milidetik non-nol. **Fix**: batas atas diganti jadi awal bulan berjalan (`isBefore(currentMonthStart)`), otomatis mencakup seluruh hari terakhir tanpa peduli jam/menit/detik/milidetik.
- [x] **OCRService (singleton) bisa di-dispose dari satu screen** — `dashboard_screen.dart` memanggil `_ocrService.dispose()` di `dispose()`-nya sendiri, padahal `TextRecognizer` di dalamnya dipakai bersama seumur hidup app. Latent bug (belum kejadian karena Dashboard tetap hidup di `IndexedStack`), tapi begitu ada alur yang benar-benar dispose `DashboardScreen`, semua scan struk berikutnya di sesi itu gagal permanen. **Fix**: hapus pemanggilan dispose dari screen; siklus hidup `TextRecognizer` singleton diserahkan ke seumur hidup app.

**Dicek tapi tidak ada bug** (untuk referensi, jangan diaudit ulang tanpa alasan baru): migrasi DB `_upgradeDB` (guard `if (oldVersion < N)` independen, aman untuk lompat dari versi manapun ke versi terbaru), error handling `ocr_service.dart` (sudah benar), `ai_screen.dart` sudah benar mengirim `budgets`/`wallets` ke `processQuery`, `settings_tiles.dart` sudah benar `ref.watch`/`ref.read`, Dismissible swipe-to-delete di semua screen sudah benar pakai dialog konfirmasi.

---

> **Dokumen ini adalah sumber kebenaran (source of truth) untuk arsitektur FINA.**  
> Update dokumen ini setiap kali ada perubahan arsitektural yang signifikan.
