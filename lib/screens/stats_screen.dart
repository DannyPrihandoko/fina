import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/database_provider.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../theme/colors.dart';
import '../providers/navigation_provider.dart';

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
    final budgets = ref.watch(budgetsProvider);
    final filteredTx = _filterTransactions(transactions, _timeRange);

    double totalIncome = 0;
    double totalExpense = 0;
    Map<String, double> categorySums = {};

    for (var tx in filteredTx) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        totalExpense += tx.amount;
        categorySums[tx.category] = (categorySums[tx.category] ?? 0) + tx.amount;
      }
    }

    final netBalance = totalIncome - totalExpense;
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final sortedCategories = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => ref.read(navigationProvider.notifier).state = 0,
        ),
        title: Text('Rekapitulasi', style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
        centerTitle: false,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 70),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  // Filter Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  const SizedBox(height: 24),

                  // Main Summary Card (Glassmorphic)
                  _buildMainSummaryCard(netBalance, totalIncome, totalExpense, currencyFormat),
                ],
              ),
            ),
          ),

          // Chart Section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tren Arus Kas',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Text('LIVE', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w900, fontSize: 10)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildTrendChart(filteredTx, _timeRange),
                ),
                
                const SizedBox(height: 32),

                // Category Insights Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detail Pengeluaran',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Text('Ketuk kategori untuk mengatur anggaran', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                      const SizedBox(height: 24),
                      if (sortedCategories.isEmpty)
                        _buildEmptyState('Tidak ada data pengeluaran.')
                      else
                        ...sortedCategories.map((entry) => _buildCategoryCard(
                              entry.key,
                              entry.value,
                              totalExpense,
                              currencyFormat,
                              budgets,
                            )),
                    ],
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
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
        return list.where((tx) => tx.date.year == now.year && tx.date.month == now.month).toList();
      case 'Bulan Lalu':
        final prevMonth = DateTime(now.year, now.month - 1, 1);
        final monthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
        return list.where((tx) => tx.date.isAfter(prevMonth.subtract(const Duration(seconds: 1))) && tx.date.isBefore(monthEnd)).toList();
      default:
        return list;
    }
  }

  Widget _buildMainSummaryCard(double net, double income, double expense, NumberFormat format) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'SELISIH KAS PERIODE INI',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              format.format(net),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(context, 'Pemasukan', income, Theme.of(context).colorScheme.secondary),
                  Container(width: 1, height: 30, color: Theme.of(context).dividerColor),
                  _buildSummaryItem(context, 'Pengeluaran', expense, Colors.redAccent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, double amount, Color color) {
    final format = NumberFormat.compactCurrency(symbol: 'Rp', locale: 'id_ID');
    return Column(
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
          format.format(amount),
          style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900),
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
      days = DateTime(now.year, now.month + 1, 0).day;
      start = DateTime(now.year, now.month, 1);
    } else {
      final prev = DateTime(now.year, now.month - 1, 1);
      days = DateTime(now.year, now.month, 0).day;
      start = prev;
    }

    Map<int, double> dailyIncome = Map.fromIterable(List.generate(days, (i) => i), value: (_) => 0.0);
    Map<int, double> dailyExpense = Map.fromIterable(List.generate(days, (i) => i), value: (_) => 0.0);

    for (var tx in list) {
      final diff = tx.date.difference(start).inDays;
      if (diff >= 0 && diff < days) {
        if (tx.type == TransactionType.income) {
          dailyIncome[diff] = (dailyIncome[diff] ?? 0) + tx.amount;
        } else if (tx.type == TransactionType.expense) {
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
            color: Theme.of(context).colorScheme.secondary,
            width: days > 10 ? 4 : 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: dailyExpense[index]!,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            width: days > 10 ? 4 : 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.3,
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
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      DateFormat(days > 7 ? 'dd' : 'E').format(date),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w900),
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

  Widget _buildCategoryCard(String category, double amount, double total, NumberFormat format, List<Budget> budgets) {
    final percentageOfTotal = total == 0 ? 0.0 : amount / total;
    final budget = budgets.where((b) => b.category == category).firstOrNull;
    final hasBudget = budget != null;
    final budgetLimit = budget?.limitAmount ?? 0;
    final budgetUsage = hasBudget ? (amount / budgetLimit).clamp(0.0, 1.0) : 0.0;
    final isExceeded = hasBudget && amount > budgetLimit;

    return GestureDetector(
      onTap: () => _showBudgetDialog(context, category, budget?.limitAmount),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).dividerColor.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isExceeded ? Colors.red.withOpacity(0.2) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(_getCategoryIcon(category), color: _getCategoryColor(category), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), letterSpacing: 1.2)),
                      const SizedBox(height: 4),
                      if (hasBudget)
                        Row(
                          children: [
                            Text(
                              format.format(amount),
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isExceeded ? Colors.red : Theme.of(context).colorScheme.onSurface),
                            ),
                            Text(
                              ' / ${format.format(budgetLimit)}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                            ),
                          ],
                        )
                      else
                        Text(format.format(amount), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Theme.of(context).colorScheme.onSurface)),
                    ],
                  ),
                ),
                Icon(isExceeded ? Icons.warning_amber_rounded : Icons.chevron_right_rounded, 
                     color: isExceeded ? Colors.red : Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
              ],
            ),
            const SizedBox(height: 20),
            if (hasBudget)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: budgetUsage,
                      minHeight: 10,
                      backgroundColor: Theme.of(context).dividerColor.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isExceeded ? Colors.red : (budgetUsage > 0.8 ? Colors.orange : Theme.of(context).colorScheme.secondary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isExceeded ? 'Melebihi Anggaran' : 'Sisa Anggaran: ${format.format(budgetLimit - amount)}',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isExceeded ? Colors.red : Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      ),
                      Text('${(budgetUsage * 100).toInt()}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
                    ],
                  ),
                ],
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentageOfTotal,
                  minHeight: 6,
                  backgroundColor: Theme.of(context).dividerColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(category).withOpacity(0.5)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, String category, double? currentLimit) {
    final controller = TextEditingController(text: currentLimit?.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Atur Anggaran: $category', style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Batas Maksimal Bulanan',
            prefixText: 'Rp ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('BATAL', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              ref.read(budgetsProvider.notifier).setBudget(category, amount);
              Navigator.pop(context);
            },
            child: const Text('SIMPAN'),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'makanan': return Icons.restaurant_rounded;
      case 'belanja': return Icons.shopping_bag_outlined;
      case 'transportasi': return Icons.directions_bus_filled_outlined;
      case 'hiburan': return Icons.movie_filter_outlined;
      case 'kesehatan': return Icons.health_and_safety_outlined;
      case 'transfer': return Icons.swap_horiz_rounded;
      default: return Icons.category_outlined;
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
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)))),
    );
  }
}
