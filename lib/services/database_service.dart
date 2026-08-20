import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/bill.dart';
import '../models/wallet.dart';
import '../models/budget.dart';
import '../models/financial_goal.dart';
import '../models/category.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fina.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // Kategori bawaan — dipakai untuk seed tabel `categories` (baru & saat migrasi),
  // warnanya harus sama persis dengan yang sebelumnya hardcoded di stats_screen.dart
  // supaya tampilan kategori existing tidak berubah setelah upgrade.
  static const Map<String, int> _defaultCategorySeeds = {
    'Makanan': 0xFFFF9800, // orange
    'Belanja': 0xFF9C27B0, // purple
    'Transportasi': 0xFF2196F3, // blue
    'Hiburan': 0xFFE91E63, // pink
    'Kesehatan': 0xFF009688, // teal
    'Cicilan': 0xFF795548, // brown
    'Lainnya': 0xFF0D1B2A, // textDarkBlue
  };

  Future<void> _seedDefaultCategories(Database db) async {
    for (final entry in _defaultCategorySeeds.entries) {
      await db.insert(
        'categories',
        {'name': entry.key, 'color': entry.value, 'isDefault': 1},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const boolType = 'INTEGER NOT NULL';
    const numType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE wallets (
  id $idType,
  name $textType,
  type $textType,
  color INTEGER NOT NULL
)
''');

    await db.execute('''
CREATE TABLE transactions (
  id $idType,
  title $textType,
  amount $numType,
  type $textType,
  category $textType,
  date $textType,
  note TEXT,
  walletId INTEGER NOT NULL,
  toWalletId INTEGER,
  adminFee REAL NOT NULL DEFAULT 0,
  FOREIGN KEY (walletId) REFERENCES wallets (id),
  FOREIGN KEY (toWalletId) REFERENCES wallets (id)
)
''');

    await db.execute('''
CREATE TABLE bills (
  id $idType,
  title $textType,
  amount $numType,
  dueDate $textType,
  category $textType,
  isRecurring $boolType,
  reminderEnabled $boolType,
  isPaid $boolType DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE budgets (
  id $idType,
  category TEXT NOT NULL UNIQUE,
  limitAmount $numType
)
''');

    // Insert Default Wallet
    await db.insert('wallets', {
      'id': 1,
      'name': 'Dompet Utama',
      'type': 'bank',
      'color': 0xFF42A5F5, // Blue
    });

    await db.execute('''
CREATE TABLE financial_goals (
  id $idType,
  title $textType,
  targetAmount $numType,
  savedAmount REAL NOT NULL DEFAULT 0,
  deadline $textType,
  icon TEXT NOT NULL DEFAULT '🎯',
  color TEXT NOT NULL DEFAULT '0xFF4CAF50'
)
''');

    await db.execute('''
CREATE TABLE categories (
  id $idType,
  name TEXT NOT NULL UNIQUE,
  color INTEGER NOT NULL,
  isDefault INTEGER NOT NULL DEFAULT 0
)
''');
    await _seedDefaultCategories(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
CREATE TABLE wallets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  color INTEGER NOT NULL
)
''');
      await db.insert('wallets', {'id': 1, 'name': 'Dompet Utama', 'type': 'bank', 'color': 0xFF42A5F5});
      await db.execute('ALTER TABLE transactions ADD COLUMN walletId INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE transactions ADD COLUMN toWalletId INTEGER');
      await db.execute('ALTER TABLE transactions ADD COLUMN adminFee REAL NOT NULL DEFAULT 0');
    }
    
    if (oldVersion < 3) {
      await db.execute('''
CREATE TABLE budgets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category TEXT NOT NULL UNIQUE,
  limitAmount REAL NOT NULL
)
''');
    }

    if (oldVersion < 4) {
      await db.execute('ALTER TABLE bills ADD COLUMN isPaid INTEGER NOT NULL DEFAULT 0');
    }

    if (oldVersion < 5) {
      await db.execute('''
CREATE TABLE financial_goals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  targetAmount REAL NOT NULL,
  savedAmount REAL NOT NULL DEFAULT 0,
  deadline TEXT NOT NULL,
  icon TEXT NOT NULL DEFAULT '🎯',
  color TEXT NOT NULL DEFAULT '0xFF4CAF50'
)
''');
    }

    if (oldVersion < 6) {
      await db.execute('''
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  color INTEGER NOT NULL,
  isDefault INTEGER NOT NULL DEFAULT 0
)
''');
      await _seedDefaultCategories(db);
    }
  }

  // Budget CRUD
  Future<List<Budget>> getAllBudgets() async {
    final db = await instance.database;
    final result = await db.query('budgets');
    return result.map((json) => Budget.fromMap(json)).toList();
  }

  Future<int> saveBudget(Budget budget) async {
    final db = await instance.database;
    return await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteBudget(int id) async {
    final db = await instance.database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // Wallet CRUD
  Future<int> createWallet(Wallet wallet) async {
    final db = await instance.database;
    return await db.insert('wallets', wallet.toMap());
  }

  Future<List<Wallet>> getAllWallets() async {
    final db = await instance.database;
    final result = await db.query('wallets');
    return result.map((json) => Wallet.fromMap(json)).toList();
  }

  Future<int> deleteWallet(int id) async {
    final db = await instance.database;
    return await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateWallet(Wallet wallet) async {
    final db = await instance.database;
    return await db.update(
      'wallets',
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
  }

  // Transaction CRUD
  Future<int> createTransaction(Transaction transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<Transaction>> getAllTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', orderBy: 'date DESC');
    return result.map((json) => Transaction.fromMap(json)).toList();
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // Bill CRUD
  Future<int> createBill(Bill bill) async {
    final db = await instance.database;
    return await db.insert('bills', bill.toMap());
  }

  Future<List<Bill>> getAllBills() async {
    final db = await instance.database;
    final result = await db.query('bills', orderBy: 'dueDate ASC');
    return result.map((json) => Bill.fromMap(json)).toList();
  }

  Future<int> deleteBill(int id) async {
    final db = await instance.database;
    return await db.delete('bills', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateBill(Bill bill) async {
    final db = await instance.database;
    return await db.update(
      'bills',
      bill.toMap(),
      where: 'id = ?',
      whereArgs: [bill.id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }

  // Financial Goal CRUD
  Future<int> createGoal(FinancialGoal goal) async {
    final db = await instance.database;
    return await db.insert('financial_goals', goal.toMap());
  }

  Future<List<FinancialGoal>> getAllGoals() async {
    final db = await instance.database;
    final result = await db.query('financial_goals', orderBy: 'deadline ASC');
    return result.map((json) => FinancialGoal.fromMap(json)).toList();
  }

  Future<int> updateGoal(FinancialGoal goal) async {
    final db = await instance.database;
    return await db.update(
      'financial_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> deleteGoal(int id) async {
    final db = await instance.database;
    return await db.delete('financial_goals', where: 'id = ?', whereArgs: [id]);
  }

  // Category CRUD
  Future<int> createCategory(Category category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories', orderBy: 'name ASC');
    return result.map((json) => Category.fromMap(json)).toList();
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
