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
  String _timeRange = '7D';

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

    final netBalance = totalIncome - totalExpense;
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final sortedCategories = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Rekapitulasi', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: false,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Filter Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: SingleChildScrollView(
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
            ),
          ),

          // Main Summary Card
          SliverToBoxAdapter(
            child: _buildMainSummaryCard(netBalance, totalIncome, totalExpense, currencyFormat),
          ),

          // Chart Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tren Keuangan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDarkBlue),
                      ),
                      Icon(Icons.auto_graph_rounded, color: AppColors.ctaAqua.withValues(alpha: 0.8)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTrendChart(filteredTx, _timeRange),
                ],
              ),
            ),
          ),

          // Category Insights Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detail Pengeluaran',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDarkBlue),
                  ),
                  const SizedBox(height: 16),
                  if (sortedCategories.isEmpty)
                    _buildEmptyState('Tidak ada data pengeluaran.')
                  else
                    ...sortedCategories.map((entry) => _buildCategoryCard(
                          entry.key,
                          entry.value,
                          totalExpense,
                          currencyFormat,
                        )),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildMainSummaryCard(double net, double income, double expense, NumberFormat format) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.mainGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDarkBlue.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SALDO BERSIH PERIODE INI',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  format.format(net),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem('Pemasukan', income, AppColors.ctaAqua),
                      Container(width: 1, height: 30, color: Colors.white24),
                      _buildSummaryItem('Pengeluaran', expense, Colors.redAccent),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          format.format(amount),
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _buildTrendChart(List<Transaction> list, String range) {
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
      days = DateTime(now.year, now.month, 0).day;
      start = DateTime(now.year, now.month, 1);
    } else {
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
            width: days > 10 ? 4 : 10,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: dailyExpense[index]!,
            color: AppColors.textDarkBlue.withValues(alpha: 0.3),
            width: days > 10 ? 4 : 10,
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
      height: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.3,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  NumberFormat.compactCurrency(symbol: 'Rp', locale: 'id_ID').format(rod.toY),
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (days > 7 && value % 5 != 0) return const SizedBox.shrink();
                  final date = start.add(Duration(days: value.toInt()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
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

  Widget _buildCategoryCard(String category, double amount, double total, NumberFormat format) {
    final percentage = total == 0 ? 0.0 : amount / total;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getCategoryIcon(category), color: _getCategoryColor(category), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDarkBlue),
                    ),
                    Text(
                      '${(percentage * 100).toStringAsFixed(1)}% dari pengeluaran',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Text(
                format.format(amount),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textDarkBlue),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearPercentIndicator(
            lineHeight: 8.0,
            percent: percentage,
            padding: EdgeInsets.zero,
            backgroundColor: AppColors.borderColor.withValues(alpha: 0.3),
            progressColor: _getCategoryColor(category),
            barRadius: const Radius.circular(10),
            animation: true,
            animationDuration: 1000,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _timeRange == label;
    return GestureDetector(
      onTap: () => setState(() => _timeRange = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textDarkBlue : AppColors.cardPaleBlue.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textDarkBlue.withValues(alpha: 0.7),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'makanan': return Icons.fastfood_rounded;
      case 'belanja': return Icons.shopping_bag_rounded;
      case 'transportasi': return Icons.directions_car_rounded;
      case 'hiburan': return Icons.movie_rounded;
      case 'kesehatan': return Icons.medical_services_rounded;
      default: return Icons.category_rounded;
    }
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
            Icon(Icons.analytics_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
