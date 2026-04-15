import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/database_provider.dart';
import '../models/transaction.dart';
import '../theme/colors.dart';
import 'add_transaction_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);
    final bills = ref.watch(billsProvider);

    double totalIncome = 0;
    double totalExpenses = 0;

    for (var tx in transactions) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else {
        totalExpenses += tx.amount;
      }
    }

    double balance = totalIncome - totalExpenses;
    final currencyFormat = NumberFormat.currency(symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('fina', style: TextStyle(fontWeight: FontWeight.black, fontSize: 24)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(transactionsProvider.notifier).loadTransactions(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              _buildSummarySection(balance, totalIncome, totalExpenses, currencyFormat),
              const SizedBox(height: 32),
              
              // Recent Transactions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.between,
                children: [
                  Text(
                    'Aktivitas Terbaru',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Transactions List
              if (transactions.isEmpty)
                _buildEmptyState(context, 'Belum ada transaksi.')
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length > 5 ? 5 : transactions.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderColor),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return _buildTransactionItem(context, tx, currencyFormat);
                  },
                ),
              
              const SizedBox(height: 32),
              
              // Upcoming Bills Header
              Text(
                'Tagihan Mendatang',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              
              if (bills.isEmpty)
                _buildEmptyState(context, 'Tidak ada tagihan mendesak.')
              else
                // Simple horizontal list or vertical list for bills
                const SizedBox.shrink(), // Placeholder for now
                
              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
          );
        },
        label: const Text('TAMBAH TRANSAKSI'),
        icon: const Icon(Icons.add_circle_outline),
        backgroundColor: AppColors.ctaAqua,
        foregroundColor: AppColors.textDarkBlue,
      ),
    );
  }

  Widget _buildSummarySection(double balance, double income, double expense, NumberFormat format) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.textDarkBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SALDO UTAMA',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                format.format(balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMiniSummaryCard('PENDAPATAN', income, AppColors.ctaAqua, format),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMiniSummaryCard('PENGELUARAN', expense, AppColors.textDarkBlue, format),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniSummaryCard(String label, double amount, Color color, NumberFormat format) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            format.format(amount),
            style: TextStyle(
              color: AppColors.textDarkBlue,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction tx, NumberFormat format) {
    final isIncome = tx.type == TransactionType.income;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.cardPaleBlue,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getCategoryIcon(tx.category),
          color: AppColors.textDarkBlue,
          size: 20,
        ),
      ),
      title: Text(
        tx.title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        '${tx.category} • ${DateFormat('dd MMM').format(tx.date)}',
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      trailing: Text(
        '${isIncome ? '+' : '-'}${format.format(tx.amount)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: isIncome ? AppColors.ctaAqua : AppColors.textDarkBlue,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardPaleBlue.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.5), style: BorderStyle.none),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, color: AppColors.textMuted.withOpacity(0.5), size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'makanan':
      case 'belanja':
        return Icons.shopping_cart_outlined;
      case 'transportasi':
        return Icons.directions_car_outlined;
      case 'hiburan':
        return Icons.movie_outlined;
      case 'kesehatan':
        return Icons.medical_services_outlined;
      case 'pendapatan':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}
