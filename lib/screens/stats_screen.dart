import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../providers/database_provider.dart';
import '../models/transaction.dart';
import '../theme/colors.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  String _timeRange = '7D'; // '7D', '30D', 'Bulan Ini', 'Bulan Lalu'

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final filteredTx = _filterTransactions(transactions, _timeRange);

    double totalIncome = 0;
    double totalExpense = 0;
    Map<String, double> categorySums = {};

    for (var tx in filteredTx) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
        categorySums[tx.category] = (categorySums[tx.category] ?? 0) + tx.amount;
      }
    }

    final currencyFormat = NumberFormat.currency(symbol: 'Rp', decimalDigits: 0);
    final sortedCategories = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekapitulasi', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Range Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('7D'),
                  _buildFilterChip('30D'),
                  _buildFilterChip('Bulan Ini'),
                  _buildFilterChip('Bulan Lalu'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Summary Header
            _buildSummaryRow(totalIncome, totalExpense, currencyFormat),
            const SizedBox(height: 32),

            // Trend Chart Section
            Text(
              'Tren Keuangan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTrendChart(filteredTx, _timeRange),
            const SizedBox(height: 32),

            // Category Progress Section
            Text(
              'Detail Pengeluaran per Kategori',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (sortedCategories.isEmpty)
              _buildEmptyState('Tidak ada data pengeluaran untuk periode ini.')
            else
              ...sortedCategories.map((entry) => _buildCategoryProgress(
                    entry.key,
                    entry.value,
                    totalExpense,
                    currencyFormat,
                  )),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  List<Transaction> _filterTransactions(List<Transaction> list, String range) {
    final now = DateTime.now();
    DateTime start;

    switch (range) {
      case '7D':
        start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
        return list.where((tx) => tx.date.isAfter(start.subtract(const Duration(seconds: 1)))).toList();
      case '30D':
        start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
        return list.where((tx) => tx.date.isAfter(start.subtract(const Duration(seconds: 1)))).toList();
      case 'Bulan Ini':
        start = DateTime(now.year, now.month, 1);
        return list.where((tx) => tx.date.year == now.year && tx.date.month == now.month).toList();
      case 'Bulan Lalu':
        final prevMonth = DateTime(now.year, now.month - 1, 1);
        return list.where((tx) => tx.date.year == prevMonth.year && tx.date.month == prevMonth.month).toList();
      default:
        return list;
    }
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _timeRange == label;
    return GestureDetector(
      onTap: () => setState(() => _timeRange = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textDarkBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.textDarkBlue : AppColors.borderColor),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.textDarkBlue.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(double income, double expense, NumberFormat format) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard('PEMASUKAN', income, AppColors.ctaAqua, Icons.arrow_downward),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard('PENGELUARAN', expense, Colors.redAccent, Icons.arrow_upward),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, double amount, Color color, IconData icon) {
    final format = NumberFormat.currency(symbol: 'Rp', decimalDigits: 0);
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
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            format.format(amount),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDarkBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<Transaction> list, String range) {
    // Reusing logic from Dashboard but optimized for reports
    final now = DateTime.now();
    int days;
    DateTime start;

    if (range == '7D') {
      days = 7;
      start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    } else if (range == '30D') {
      days = 30;
      start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
    } else if (range == 'Bulan Ini') {
      days = DateTime(now.year, now.month + 1, 0).day;
      start = DateTime(now.year, now.month, 1);
    } else { // Bulan Lalu
      final prev = DateTime(now.year, now.month - 1, 1);
      days = DateTime(now.year, now.month, 0).day;
      start = prev;
    }

    Map<int, double> dailyIncome = {};
    Map<int, double> dailyExpense = {};

    for (int i = 0; i < days; i++) {
      dailyIncome[i] = 0;
      dailyExpense[i] = 0;
    }

    for (var tx in list) {
      final diff = tx.date.difference(start).inDays;
      if (diff >= 0 && diff < days) {
        if (tx.type == TransactionType.income) {
          dailyIncome[diff] = (dailyIncome[diff] ?? 0) + tx.amount;
        } else {
          dailyExpense[diff] = (dailyExpense[diff] ?? 0) + tx.amount;
        }
      }
    }

    final barGroups = List.generate(days, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: dailyIncome[index]!,
            color: AppColors.ctaAqua,
            width: days > 10 ? 4 : 12,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: dailyExpense[index]!,
            color: AppColors.textDarkBlue.withValues(alpha: 0.5),
            width: days > 10 ? 4 : 12,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    double maxVal = 0;
    for (var v in dailyIncome.values) { if (v > maxVal) maxVal = v; }
    for (var v in dailyExpense.values) { if (v > maxVal) maxVal = v; }
    if (maxVal == 0) maxVal = 1000;

    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.2,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (days > 7 && value % 5 != 0) return const SizedBox.shrink();
                  final date = start.add(Duration(days: value.toInt()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat(days > 7 ? 'dd' : 'E').format(date),
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

  Widget _buildCategoryProgress(String category, double amount, double total, NumberFormat format) {
    final percentage = total == 0 ? 0.0 : amount / total;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDarkBlue),
              ),
              Text(
                format.format(amount),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textDarkBlue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            lineHeight: 8.0,
            percent: percentage,
            padding: EdgeInsets.zero,
            backgroundColor: AppColors.borderColor,
            progressColor: _getCategoryColor(category),
            barRadius: const Radius.circular(4),
            animation: true,
            animationDuration: 1000,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'makanan': return Colors.orange;
      case 'belanja': return Colors.purple;
      case 'transportasi': return Colors.blue;
      case 'hiburan': return Colors.pink;
      case 'kesehatan': return Colors.teal;
      default: return AppColors.textDarkBlue;
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.bar_chart_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
