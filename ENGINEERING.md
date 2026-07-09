# 🏗️ FINA — Engineering Documentation

> **Versi**: 1.0.0 · **Terakhir diperbarui**: 9 Juni 2026  
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
  color        TEXT NOT NULL DEFAULT '0xFF00BFA5'
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
| `stats_screen` | 22KB | Bar chart, pie chart, budget monitor |
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
| `home_widget` | ^0.9.1 | Widget | Android home screen widget |

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
  ├── utils/database_backup_helper.dart
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

> ✅ **Status Testing:**
> 9 dari 9 pengujian (Unit & Integration Tests) berhasil dilalui (100% passed).
> 
> Area utama yang telah diuji:
> 1. `walletBalanceProvider` — Kalkulasi kritis & filter cache (`walletTransactionsProvider`)
> 2. Integration: Interaksi komponen & inisialisasi dengan mock `SharedPreferences`

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

> **Dokumen ini adalah sumber kebenaran (source of truth) untuk arsitektur FINA.**  
> Update dokumen ini setiap kali ada perubahan arsitektural yang signifikan.
