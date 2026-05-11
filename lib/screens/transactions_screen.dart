import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/database_provider.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  late DateTime _selectedMonth;
  final List<DateTime> _months = [];

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    
    // Generate last 12 months
    for (int i = 0; i < 12; i++) {
      _months.add(DateTime(DateTime.now().year, DateTime.now().month - i, 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final wallets = ref.watch(walletsProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rp', decimalDigits: 0);
    
    // Calculate Monthly Flow
    double monthlyIncome = 0;
    double monthlyExpense = 0;
    
    final filteredTransactions = transactions.where((tx) {
      return tx.date.year == _selectedMonth.year && tx.date.month == _selectedMonth.month;
    }).toList();

    for (var tx in filteredTransactions) {
      if (tx.type == TransactionType.income) {
        monthlyIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        monthlyExpense += tx.amount;
      }
    }
    double monthlyBalance = monthlyIncome - monthlyExpense;

    // Group by date
    final groupedTransactions = <DateTime, List<Transaction>>{};
    for (var tx in filteredTransactions) {
      final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
      if (!groupedTransactions.containsKey(date)) {
        groupedTransactions[date] = [];
      }
      groupedTransactions[date]!.add(tx);
    }
    
    final sortedDates = groupedTransactions.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
        centerTitle: false,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 70),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  // Monthly Summary Card (Glassmorphic)
                  _buildSummaryCard(monthlyBalance, monthlyIncome, monthlyExpense, currencyFormat),
                  const SizedBox(height: 24),
                  // Month Selector
                  _buildMonthSelector(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                filteredTransactions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        itemCount: sortedDates.length,
                        itemBuilder: (context, index) {
                          final date = sortedDates[index];
                          final txs = groupedTransactions[date]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16, top: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today_rounded, size: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDateHeader(date),
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardTheme.color,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).dividerColor.withOpacity(0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: txs.asMap().entries.map((entry) {
                                    final i = entry.key;
                                    final tx = entry.value;
                                    final w = wallets.firstWhere((w) => w.id == tx.walletId, orElse: () => Wallet(name: 'Unknown', type: WalletType.cash, color: Colors.grey));
                                    Wallet? toW;
                                    if (tx.type == TransactionType.transfer && tx.toWalletId != null) {
                                      toW = wallets.firstWhere((w) => w.id == tx.toWalletId, orElse: () => w);
                                    }
                                    
                                    return Dismissible(
                                      key: Key('tx_${tx.id}'),
                                      direction: DismissDirection.endToStart,
                                      confirmDismiss: (direction) async {
                                        return await showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                            title: const Text('Hapus Transaksi?'),
                                            content: Text('Transaksi "${tx.title}" akan dihapus secara permanen.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, false),
                                                child: Text('BATAL', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, true),
                                                child: const Text('HAPUS', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      onDismissed: (direction) {
                                        ref.read(transactionsProvider.notifier).removeTransaction(tx.id!);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Transaksi "${tx.title}" telah dihapus.'),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          ),
                                        );
                                      },
                                      background: Container(
                                        margin: const EdgeInsets.only(bottom: 24),
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.symmetric(horizontal: 24),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                                      ),
                                      child: Column(
                                        children: [
                                          _buildTransactionItem(context, tx, w, toW, currencyFormat),
                                          if (i < txs.length - 1)
                                            Divider(height: 1, color: Theme.of(context).dividerColor, indent: 70, endIndent: 20),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double balance, double income, double expense, NumberFormat format) {
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
              'ARUS KAS ${DateFormat('MMMM yyyy').format(_selectedMonth).toUpperCase()}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              format.format(balance),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSimpleStat(context, 'MASUK', income, Theme.of(context).colorScheme.secondary),
                  Container(width: 1, height: 30, color: Theme.of(context).dividerColor),
                  _buildSimpleStat(context, 'KELUAR', expense, Colors.redAccent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleStat(BuildContext context, String label, double amount, Color color) {
    final format = NumberFormat.compactCurrency(symbol: 'Rp', locale: 'id_ID');
    return Column(
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
          format.format(amount),
          style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ],
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
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

  Widget _buildTransactionItem(BuildContext context, Transaction tx, Wallet wallet, Wallet? toWallet, NumberFormat format) {
    final isIncome = tx.type == TransactionType.income || tx.type == TransactionType.initial;
    final isTransfer = tx.type == TransactionType.transfer;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5), 
              borderRadius: BorderRadius.circular(16)
            ),
            child: Icon(_getCategoryIcon(tx.category), size: 22, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: wallet.color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(wallet.name.toUpperCase(), style: TextStyle(color: wallet.color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ),
                    if (isTransfer && toWallet != null) ...[
                      Icon(Icons.arrow_forward_rounded, size: 8, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: toWallet.color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(toWallet.name.toUpperCase(), style: TextStyle(color: toWallet.color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${format.format(tx.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: isTransfer ? Colors.orange : (isIncome ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurface),
                ),
              ),
              if (tx.adminFee > 0)
                Text('Fee: ${format.format(tx.adminFee)}', style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.history_rounded, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
          ),
          const SizedBox(height: 24),
          Text('Tidak ada transaksi di bulan ini', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (date == today) return 'HARI INI';
    if (date == yesterday) return 'KEMARIN';
    
    return DateFormat('EEEE, dd MMMM').format(date).toUpperCase();
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'makanan': return Icons.restaurant_rounded;
      case 'belanja': return Icons.shopping_bag_outlined;
      case 'transportasi': return Icons.directions_bus_filled_outlined;
      case 'hiburan': return Icons.movie_filter_outlined;
      case 'kesehatan': return Icons.health_and_safety_outlined;
      case 'transfer': return Icons.swap_horiz_rounded;
      case 'initial': return Icons.first_page_rounded;
      default: return Icons.category_outlined;
    }
  }
}
