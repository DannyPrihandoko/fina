import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/database_provider.dart';
import '../models/transaction.dart';
import '../theme/colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'add_transaction_screen.dart';
import 'settings_screen.dart';
import '../models/bill.dart'; // Added missing Bill model import for upcoming bills section

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _timeRange = '7D'; // '7D' or '30D'

  @override
  Widget build(BuildContext context) {
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
        title: const Text('fina', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
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

              // Chart Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rekapitulasi Keuangan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.cardPaleBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildTimeRangeToggle('7D'),
                        _buildTimeRangeToggle('30D'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Chart
              _buildChartSection(transactions),
              
              const SizedBox(height: 32),
              
              // Recent Transactions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    return Dismissible(
                      key: Key('tx_${tx.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.redAccent.withValues(alpha: 0.8),
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        ref.read(transactionsProvider.notifier).removeTransaction(tx.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${tx.title} dihapus'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            action: SnackBarAction(
                              label: 'URUNG',
                              onPressed: () {
                                ref.read(transactionsProvider.notifier).addTransaction(tx);
                              },
                            ),
                          ),
                        );
                      },
                      child: _buildTransactionItem(context, tx, currencyFormat),
                    );
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
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bills.length > 3 ? 3 : bills.length,
                  itemBuilder: (context, index) {
                    final bill = bills[index];
                    return _buildMinimalBillItem(bill, currencyFormat);
                  },
                ),
                
              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'dashboard_fab',
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

  Widget _buildTimeRangeToggle(String range) {
    final isSelected = _timeRange == range;
    return GestureDetector(
      onTap: () => setState(() => _timeRange = range),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textDarkBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          range,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection(List<Transaction> transactions) {
    final now = DateTime.now();
    final daysToSubtract = _timeRange == '7D' ? 7 : 30;
    final startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract - 1));

    Map<DateTime, double> incomeData = {};
    Map<DateTime, double> expenseData = {};

    for (int i = 0; i < daysToSubtract; i++) {
      final date = startDate.add(Duration(days: i));
      incomeData[date] = 0;
      expenseData[date] = 0;
    }

    for (var tx in transactions) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      if (txDate.isAtSameMomentAs(startDate) || txDate.isAfter(startDate)) {
        if (tx.type == TransactionType.income) {
          incomeData[txDate] = (incomeData[txDate] ?? 0) + tx.amount;
        } else {
          expenseData[txDate] = (expenseData[txDate] ?? 0) + tx.amount;
        }
      }
    }

    final barGroups = List.generate(daysToSubtract, (index) {
      final date = startDate.add(Duration(days: index));
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: incomeData[date]!,
            color: AppColors.ctaAqua,
            width: _timeRange == '7D' ? 12 : 4,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: expenseData[date]!,
            color: AppColors.textDarkBlue.withValues(alpha: 0.5),
            width: _timeRange == '7D' ? 12 : 4,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(incomeData, expenseData) * 1.2,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (_timeRange == '30D' && value % 5 != 0) return const SizedBox.shrink();
                  final date = startDate.add(Duration(days: value.toInt()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat(_timeRange == '7D' ? 'E' : 'dd').format(date),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }

  double _getMaxY(Map<DateTime, double> income, Map<DateTime, double> expense) {
    double max = 0;
    income.values.forEach((v) => if (v > max) max = v);
    expense.values.forEach((v) => if (v > max) max = v);
    return max == 0 ? 1000 : max;
  }

  Widget _buildMinimalBillItem(Bill bill, NumberFormat format) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_outlined, color: AppColors.textDarkBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bill.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  'Jatuh tempo: ${DateFormat('dd MMM').format(bill.dueDate)}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            format.format(bill.amount),
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDarkBlue),
          ),
        ],
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
                  color: Colors.white.withValues(alpha: 0.7),
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
            style: const TextStyle(
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
        decoration: const BoxDecoration(
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
        color: AppColors.cardPaleBlue.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.5), style: BorderStyle.none),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, color: AppColors.textMuted.withValues(alpha: 0.5), size: 48),
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
