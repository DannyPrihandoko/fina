import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/bill.dart';
import '../models/budget.dart';
import '../models/financial_goal.dart';

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Reference to the user's backup document
  DocumentReference _userRef(String uid) => _db.collection('users').doc(uid);
  CollectionReference _backupRef(String uid) => _userRef(uid).collection('backup');

  /// Backup ALL data to Firestore
  Future<void> backupAll({
    required String uid,
    required List<Transaction> transactions,
    required List<Wallet> wallets,
    required List<Bill> bills,
    required List<Budget> budgets,
    required List<FinancialGoal> goals,
    String? userName,
    String? photoUrl,
  }) async {
    try {
      final batch = _db.batch();

      // Update profile metadata
      batch.set(_userRef(uid), {
        'uid': uid,
        'userName': userName ?? 'User Fina',
        'photoUrl': photoUrl,
        'lastSyncAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Backup each collection
      batch.set(_backupRef(uid).doc('transactions'), {
        'data': transactions.map((t) => t.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.set(_backupRef(uid).doc('wallets'), {
        'data': wallets.map((w) => w.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.set(_backupRef(uid).doc('bills'), {
        'data': bills.map((b) => b.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.set(_backupRef(uid).doc('budgets'), {
        'data': budgets.map((b) => b.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.set(_backupRef(uid).doc('goals'), {
        'data': goals.map((g) => g.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      debugPrint('CloudSync: Backup completed for uid=$uid');
    } catch (e) {
      debugPrint('CloudSync: Backup failed: $e');
    }
  }

  /// Check if cloud data exists for this user
  Future<bool> isCloudDataAvailable(String uid) async {
    try {
      final doc = await _backupRef(uid).doc('transactions').get();
      return doc.exists;
    } catch (e) {
      debugPrint('CloudSync: Check availability failed: $e');
      return false;
    }
  }

  /// Restore all data from Firestore
  Future<CloudRestoreResult?> restoreAll(String uid) async {
    try {
      final results = await Future.wait([
        _backupRef(uid).doc('transactions').get(),
        _backupRef(uid).doc('wallets').get(),
        _backupRef(uid).doc('bills').get(),
        _backupRef(uid).doc('budgets').get(),
        _backupRef(uid).doc('goals').get(),
      ]);

      final txDoc = results[0];
      final walletDoc = results[1];
      final billDoc = results[2];
      final budgetDoc = results[3];
      final goalDoc = results[4];

      final transactions = txDoc.exists
          ? (txDoc.data() as Map<String, dynamic>)['data'] as List<dynamic>
          : [];
      final wallets = walletDoc.exists
          ? (walletDoc.data() as Map<String, dynamic>)['data'] as List<dynamic>
          : [];
      final bills = billDoc.exists
          ? (billDoc.data() as Map<String, dynamic>)['data'] as List<dynamic>
          : [];
      final budgets = budgetDoc.exists
          ? (budgetDoc.data() as Map<String, dynamic>)['data'] as List<dynamic>
          : [];
      final goals = goalDoc.exists
          ? (goalDoc.data() as Map<String, dynamic>)['data'] as List<dynamic>
          : [];

      debugPrint('CloudSync: Restore found ${transactions.length} transactions, '
          '${wallets.length} wallets, ${bills.length} bills, '
          '${budgets.length} budgets, ${goals.length} goals.');

      return CloudRestoreResult(
        transactions: transactions
            .map((e) => Transaction.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        wallets: wallets
            .map((e) => Wallet.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        bills: bills
            .map((e) => Bill.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        budgets: budgets
            .map((e) => Budget.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        goals: goals
            .map((e) => FinancialGoal.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
      );
    } catch (e) {
      debugPrint('CloudSync: Restore failed: $e');
      return null;
    }
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime(String uid) async {
    try {
      final doc = await _userRef(uid).get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>?;
      final ts = data?['lastSyncAt'] as Timestamp?;
      return ts?.toDate();
    } catch (e) {
      return null;
    }
  }
}

class CloudRestoreResult {
  final List<Transaction> transactions;
  final List<Wallet> wallets;
  final List<Bill> bills;
  final List<Budget> budgets;
  final List<FinancialGoal> goals;

  CloudRestoreResult({
    required this.transactions,
    required this.wallets,
    required this.bills,
    required this.budgets,
    required this.goals,
  });
}
