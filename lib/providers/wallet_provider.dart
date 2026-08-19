import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import 'database_provider.dart';
import 'transaction_provider.dart';

final walletsProvider = StateNotifierProvider<WalletsNotifier, List<Wallet>>((ref) {
  return WalletsNotifier(ref.watch(databaseServiceProvider), ref);
});

class WalletsNotifier extends StateNotifier<List<Wallet>> {
  final DatabaseService _dbService;
  final Ref _ref;

  WalletsNotifier(this._dbService, this._ref) : super([]) {
    loadWallets();
  }

  Future<void> loadWallets() async {
    state = await _dbService.getAllWallets();
  }

  Future<void> addWallet(Wallet wallet, double initialBalance) async {
    final id = await _dbService.createWallet(wallet);
    await loadWallets();

    if (initialBalance != 0) {
      final initialTx = Transaction(
        title: 'Saldo Awal: ${wallet.name}',
        // Jangan di-abs(): saldo awal negatif (mis. representasi utang di wallet kartu kredit)
        // harus tetap mengurangi saldo, bukan malah ditambahkan sebagai kredit.
        amount: initialBalance,
        type: TransactionType.initial,
        category: 'Initial',
        date: DateTime.now(),
        walletId: id,
      );
      await _ref.read(transactionsProvider.notifier).addTransaction(initialTx);
    }
    DatabaseBackupHelper.triggerBackup(_ref);
  }

  Future<void> removeWallet(int id) async {
    await _dbService.deleteWallet(id);
    await loadWallets();
    DatabaseBackupHelper.triggerBackup(_ref);
  }

  Future<void> updateWallet(Wallet wallet) async {
    await _dbService.updateWallet(wallet);
    await loadWallets();
    DatabaseBackupHelper.triggerBackup(_ref);
  }
}

// CONVENIENCE PROVIDERS
final walletTransactionsProvider = Provider.family<List<Transaction>, int>((ref, walletId) {
  final transactions = ref.watch(transactionsProvider);
  return transactions
      .where((tx) => tx.walletId == walletId || (tx.toWalletId == walletId && tx.type == TransactionType.transfer))
      .toList();
});

final walletBalanceProvider = Provider.family<double, int>((ref, walletId) {
  final transactions = ref.watch(walletTransactionsProvider(walletId));
  double balance = 0;

  for (var tx in transactions) {
    if (tx.walletId == walletId) {
      if (tx.type == TransactionType.income || tx.type == TransactionType.initial) {
        balance += tx.amount;
      } else if (tx.type == TransactionType.expense || tx.type == TransactionType.transfer) {
        balance -= tx.amount;
        balance -= tx.adminFee;
      }
    } else if (tx.toWalletId == walletId && tx.type == TransactionType.transfer) {
      balance += tx.amount;
    }
  }

  return balance;
});

final totalNetWorthProvider = Provider((ref) {
  final wallets = ref.watch(walletsProvider);
  double total = 0;
  for (var wallet in wallets) {
    total += ref.watch(walletBalanceProvider(wallet.id!));
  }
  return total;
});
