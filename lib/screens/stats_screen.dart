import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/database_provider.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../theme/colors.dart';
import '../providers/navigation_provider.dart';
import '../utils/category_style.dart';
import 'manage_categories_screen.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  String _timeRange = '7D';
  // Dipakai saat _timeRange == 'Per Bulan' — memungkinkan lihat rekap mundur ke
  // bulan manapun di riwayat (bukan cuma "Bulan Ini"/"Bulan Lalu" yang fixed).
  // Pola & rentang (12 bulan) sengaja disamakan dengan _months di transactions_screen.dart.
  late DateTime _selectedMonth;
  final List<DateTime> _months = [];
  // Filter kelompok pengeluaran di section "Detail Pengeluaran". Set kosong = tampilkan semua.
  final Set<String> _selectedExpenseCategories = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    for (int i = 0; i < 12; i++) {
      _months.add(DateTime(now.year, now.month - i, 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final budgets = ref.watch(budgetsProvider);
    final filteredTx = _filterTransactions(transactions, _timeRange);

    double totalIncome = 0;
    double totalExpense = 0;
    Map<String, double> categorySums = {};
    Map<String, double> incomeSums = {};

    for (var tx in filteredTx) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
        incomeSums[tx.category] = (incomeSums[tx.category] ?? 0) + tx.amount;
      } else if (tx.type == TransactionType.expense) {
        totalExpense += tx.amount;
        categorySums[tx.category] = (categorySums[tx.category] ?? 0) + tx.amount;
      }
    }

    final netBalance = totalIncome - totalExpense;
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    
    final sortedCategories = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sortedIncomeCategories = incomeSums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // "Kelompok pengeluaran" yang dipilih user di filter section "Detail Pengeluaran".
    // Set kosong berarti tidak ada filter aktif (tampilkan semua kategori).
    final visibleExpenseCategories = _selectedExpenseCategories.isEmpty
        ? sortedCategories
        : sortedCategories.where((e) => _selectedExpenseCategories.contains(e.key)).toList();

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
        actions: [
          IconButton(
            icon: Icon(Icons.category_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
            tooltip: 'Kelola Kategori',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageCategoriesScreen())),
          ),
        ],
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
                          _buildFilterChip('Per Bulan'),
                        ],
                      ),
                    ),
                  ),
                  if (_timeRange == 'Per Bulan') ...[
                    const SizedBox(height: 12),
                    _buildMonthSelector(),
                  ],
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

                // Income Insights Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detail Pemasukan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 24),
                      if (sortedIncomeCategories.isEmpty)
                        _buildEmptyState('Tidak ada data pemasukan.')
                      else
                        ...sortedIncomeCategories.map((entry) {
                          final categoryTransactions = filteredTx
                              .where((tx) => tx.type == TransactionType.income && tx.category == entry.key)
                              .toList();
                          return _buildCategoryCard(
                            entry.key,
                            entry.value,
                            totalIncome,
                            currencyFormat,
                            budgets,
                            categoryTransactions,
                          );
                        }),
                    ],
                  ),
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
                      const SizedBox(height: 16),
                      if (sortedCategories.isNotEmpty)
                        _buildExpenseCategoryFilter(sortedCategories.map((e) => e.key).toList()),
                      const SizedBox(height: 16),
                      if (visibleExpenseCategories.isEmpty)
                        _buildEmptyState(sortedCategories.isEmpty
                            ? 'Tidak ada data pengeluaran.'
                            : 'Tidak ada kategori yang cocok dengan filter.')
                      else
                        ...visibleExpenseCategories.map((entry) {
                          final categoryTransactions = filteredTx
                              .where((tx) => tx.type == TransactionType.expense && tx.category == entry.key)
                              .toList();
                          return _buildCategoryCard(
                            entry.key,
                            entry.value,
                            totalExpense,
                            currencyFormat,
                            budgets,
                            categoryTransactions,
                          );
                        }),
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
        // Batas atas pakai awal bulan berjalan (bukan "akhir bulan lalu jam 23:59:59"),
        // supaya transaksi dengan milidetik non-nol di hari terakhir bulan lalu
        // (mis. 23:59:59.500) tidak ikut ke-exclude oleh isBefore().
        final currentMonthStart = DateTime(now.year, now.month, 1);
        return list.where((tx) => tx.date.isAfter(prevMonth.subtract(const Duration(seconds: 1))) && tx.date.isBefore(currentMonthStart)).toList();
      case 'Per Bulan':
        // Bisa mundur ke bulan manapun (dipilih via _buildMonthSelector), tidak
        // dibatasi cuma "bulan ini"/"bulan lalu".
        return list.where((tx) => tx.date.year == _selectedMonth.year && tx.date.month == _selectedMonth.month).toList();
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
          barTouchData: const BarTouchData(enabled: true),
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

  Widget _buildCategoryCard(String category, double amount, double total, NumberFormat format, List<Budget> budgets, List<Transaction> categoryTransactions) {
    final percentageOfTotal = total == 0 ? 0.0 : amount / total;
    final budget = budgets.where((b) => b.category == category).firstOrNull;
    final hasBudget = budget != null;
    final budgetLimit = budget?.limitAmount ?? 0;
    final budgetUsage = (hasBudget && budgetLimit > 0) ? (amount / budgetLimit).clamp(0.0, 1.0) : 0.0;
    final isExceeded = hasBudget && amount > budgetLimit;

    return GestureDetector(
      onTap: () => _showCategoryActionSheet(context, category, budget?.limitAmount, categoryTransactions),
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
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Batas anggaran harus lebih besar dari Rp 0')),
                );
                return;
              }
              ref.read(budgetsProvider.notifier).setBudget(category, amount);
              Navigator.pop(context);
            },
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );
  }

  void _showCategoryActionSheet(BuildContext context, String category, double? currentLimit, List<Transaction> categoryTransactions) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.list_alt_rounded, color: Theme.of(context).colorScheme.primary),
                  ),
                  title: const Text('Lihat Detail Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _showTransactionsBottomSheet(context, category, categoryTransactions);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.edit_rounded, color: Theme.of(context).colorScheme.secondary),
                  ),
                  title: const Text('Atur Anggaran', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _showBudgetDialog(context, category, currentLimit);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTransactionsBottomSheet(BuildContext context, String category, List<Transaction> transactions) {
    transactions.sort((a, b) => b.date.compareTo(a.date));
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 16),
                Text('Detail $category', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 16),
                Expanded(
                  child: transactions.isEmpty 
                    ? _buildEmptyState('Tidak ada transaksi.') 
                    : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: transactions.length,
                      separatorBuilder: (context, index) => Divider(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(_getCategoryIcon(tx.category), size: 18, color: Theme.of(context).colorScheme.onSurface),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tx.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                                    const SizedBox(height: 4),
                                    Text(DateFormat('dd MMM yyyy').format(tx.date), style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                                  ],
                                ),
                              ),
                              Text(
                                currencyFormat.format(tx.amount),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.redAccent),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Chip multi-select buat filter kategori yang ditampilkan di "Detail Pengeluaran".
  /// `categories` cuma kategori yang benar-benar punya transaksi di rentang waktu
  /// terpilih (bukan semua kategori terdaftar), biar tidak ada chip kosong yang
  /// kalau dipilih malah tidak menampilkan apa pun.
  Widget _buildExpenseCategoryFilter(List<String> categories) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryFilterChip('Semua', _selectedExpenseCategories.isEmpty, () {
            setState(() => _selectedExpenseCategories.clear());
          }),
          ...categories.map((cat) {
            final isSelected = _selectedExpenseCategories.contains(cat);
            return _buildCategoryFilterChip(cat, isSelected, () {
              setState(() {
                if (isSelected) {
                  _selectedExpenseCategories.remove(cat);
                } else {
                  _selectedExpenseCategories.add(cat);
                }
              });
            });
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.secondary.withOpacity(0.15) : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.transparent, width: 1.2),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isSelected ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _months.length,
        itemBuilder: (context, index) {
          final month = _months[index];
          final isSelected = month.year == _selectedMonth.year && month.month == _selectedMonth.month;

          return GestureDetector(
            onTap: () => setState(() => _selectedMonth = month),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withOpacity(0.5)),
              ),
              child: Center(
                child: Text(
                  DateFormat('MMM yyyy').format(month),
                  style: TextStyle(
                    color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        },
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

  IconData _getCategoryIcon(String category) => CategoryStyle.icon(category);

  // Warna sekarang bersumber dari categoriesProvider (tabel `categories` di DB, termasuk
  // kategori custom yang ditambah user), bukan switch statement hardcoded lagi.
  Color _getCategoryColor(String category) => CategoryStyle.color(category, ref.watch(categoriesProvider));

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)))),
    );
  }
}
