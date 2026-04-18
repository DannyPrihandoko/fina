import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../providers/database_provider.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../theme/colors.dart';
import 'add_transaction_screen.dart';
import 'settings_screen.dart';
import 'transactions_screen.dart';
import 'wallets_screen.dart';
import '../models/bill.dart';
import '../models/budget.dart';
import '../providers/settings_provider.dart';
import '../providers/navigation_provider.dart';

import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final OCRService _ocrService = OCRService();
  bool _isScanning = false;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _processScan(ImageSource source) async {
    setState(() => _isScanning = true);
    
    final result = await _ocrService.scanReceipt(source);
    
    if (!mounted) return;
    setState(() => _isScanning = false);

    if (result == null) return; // User cancelled

    if (result.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Terjadi kesalahan saat scan.'), backgroundColor: Colors.red),
      );
      return;
    }

    // Success! Navigate to AddTransactionScreen with data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          initialAmount: result['amount'],
          initialTitle: result['title'],
          initialCategory: result['category'],
        ),
      ),
    );
  }

  void _showScanOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('SCAN STRUK BELANJA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
            const SizedBox(height: 8),
            const Text('AI akan otomatis mendeteksi nominal & kategori', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildScanOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'KAMERA',
                    onTap: () {
                      Navigator.pop(context);
                      _processScan(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildScanOption(
                    icon: Icons.photo_library_rounded,
                    label: 'GALERI',
                    onTap: () {
                      Navigator.pop(context);
                      _processScan(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildScanOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.cardPaleBlue,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.textDarkBlue, size: 32),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1, color: AppColors.textDarkBlue)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final wallets = ref.watch(walletsProvider);
    final bills = ref.watch(billsProvider);
    final netWorth = ref.watch(totalNetWorthProvider);
    final budgets = ref.watch(budgetsProvider);

    final currencyFormat = NumberFormat.currency(symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Image.asset(
          'assets/icon/logo_apps.png',
          height: 28,
          filterQuality: FilterQuality.high,
          color: Colors.white,
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner_rounded, color: AppColors.textDarkBlue),
            onPressed: _showScanOptions,
            tooltip: 'Scan Struk',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textDarkBlue),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(transactionsProvider.notifier).loadTransactions();
          await ref.read(walletsProvider.notifier).loadWallets();
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 70),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(netWorth, currencyFormat),
              const SizedBox(height: 32),
              _buildWalletCarousel(wallets, ref, currencyFormat),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletsScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.ctaAqua.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.settings_suggest_outlined, size: 14, color: AppColors.ctaAqua),
                        SizedBox(width: 8),
                        Text('KELOLA DOMPET', style: TextStyle(color: AppColors.ctaAqua, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Column(
                children: [
                  const SizedBox(height: 32),
                  if (budgets.isNotEmpty)
                    _buildBudgetSection(context, budgets, transactions, currencyFormat),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildSectionHeader(
                      context, 
                      'Aktivitas Hari Ini', 
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionsScreen()))
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildTransactionsList(context, transactions, currencyFormat),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tagihan Mendatang', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 16),
                        if (bills.isEmpty)
                          _buildEmptyState(context, 'Tidak ada tagihan mendesak.')
                        else
                          ...bills.take(3).map((bill) => _buildMinimalBillItem(bill, currencyFormat)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: const _SmartTransactionBubble(),
    );
  }

  Widget _buildHeader(double netWorth, NumberFormat format) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.cardPaleBlue,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDarkBlue.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded, color: AppColors.ctaAqua, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'TOTAL KEKAYAAN BERSIH',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              format.format(netWorth),
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.textDarkBlue, letterSpacing: -0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCarousel(List<Wallet> wallets, WidgetRef ref, NumberFormat format) {
    return SizedBox(
      height: 190,
      child: wallets.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
              controller: PageController(viewportFraction: 0.88),
              itemCount: wallets.length,
              itemBuilder: (context, index) {
                final wallet = wallets[index];
                final balance = ref.watch(walletBalanceProvider(wallet.id!));
                return _buildWalletCard(context, wallet, balance, format);
              },
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        GestureDetector(
          onTap: onTap,
          child: Text(
            'Lihat Semua',
            style: TextStyle(color: AppColors.ctaAqua, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletCard(BuildContext context, Wallet wallet, double balance, NumberFormat format) {
    return Container(
      margin: const EdgeInsets.only(right: 16, bottom: 12),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: wallet.color,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: wallet.color.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            wallet.color,
            wallet.color.withBlue(wallet.color.blue + 30).withRed(wallet.color.red + 10),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Wallet.getIcon(wallet.type), color: Colors.white, size: 28),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  wallet.type.name.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(wallet.name, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(
                format.format(balance), 
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSection(BuildContext context, List<Budget> budgets, List<Transaction> transactions, NumberFormat currencyFormat) {
    final now = DateTime.now();
    final thisMonthTx = transactions.where((tx) => 
      tx.type == TransactionType.expense && 
      tx.date.year == now.year && 
      tx.date.month == now.month
    ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('Status Anggaran', style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 110,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              final budget = budgets[index];
              final spent = thisMonthTx
                  .where((tx) => tx.category == budget.category)
                  .fold(0.0, (sum, tx) => sum + tx.amount);
              
              final percent = (spent / budget.limitAmount).clamp(0.0, 1.0);
              final isExceeded = spent > budget.limitAmount;

              return Container(
                width: 220,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.borderColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: isExceeded ? Colors.red.withOpacity(0.2) : AppColors.borderColor.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          budget.category,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textDarkBlue),
                        ),
                        Icon(
                          isExceeded ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded, 
                          color: isExceeded ? Colors.red : AppColors.ctaAqua, 
                          size: 16
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: percent,
                        backgroundColor: AppColors.borderColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isExceeded ? Colors.red : AppColors.ctaAqua,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sisa: ${currencyFormat.format((budget.limitAmount - spent).clamp(0, double.infinity))}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isExceeded ? Colors.red : AppColors.textMuted,
                          ),
                        ),
                        Text(
                          '${(percent * 100).toInt()}%',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textDarkBlue.withOpacity(0.5)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList(BuildContext context, List<Transaction> transactions, NumberFormat format) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayTransactions = transactions.where((tx) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      return txDate.isAtSameMomentAs(today);
    }).toList();

    if (todayTransactions.isEmpty) {
      return _buildEmptyState(context, 'Belum ada aktivitas hari ini.');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.borderColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(8),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: todayTransactions.length > 5 ? 5 : todayTransactions.length,
        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderColor, indent: 60),
        itemBuilder: (context, index) {
          final tx = todayTransactions[index];
          return _buildTransactionItem(context, tx, format);
        },
      ),
    );
  }

  Widget _buildMinimalBillItem(Bill bill, NumberFormat format) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.cardPaleBlue, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.receipt_long_rounded, color: AppColors.textDarkBlue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bill.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textDarkBlue)),
                const SizedBox(height: 2),
                Text('Tempo: ${DateFormat('dd MMM').format(bill.dueDate)}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Text(format.format(bill.amount), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDarkBlue, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction tx, NumberFormat format) {
    final isIncome = tx.type == TransactionType.income || tx.type == TransactionType.initial;
    final isTransfer = tx.type == TransactionType.transfer;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.cardPaleBlue.withOpacity(0.5), 
          borderRadius: BorderRadius.circular(16)
        ),
        child: Icon(_getCategoryIcon(tx.category), color: AppColors.textDarkBlue, size: 22),
      ),
      title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textDarkBlue)),
      subtitle: Text('${tx.category} • ${DateFormat('dd MMM').format(tx.date)}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
      trailing: Text(
        '${isIncome ? '+' : '-'}${format.format(tx.amount)}',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14,
          color: isTransfer ? Colors.orange : (isIncome ? AppColors.ctaAqua : AppColors.textDarkBlue),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.cardPaleBlue.withOpacity(0.5), shape: BoxShape.circle),
            child: Icon(Icons.inbox_rounded, color: AppColors.textMuted.withOpacity(0.3), size: 40),
          ),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
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
      case 'pendapatan': return Icons.attach_money_rounded;
      case 'transfer': return Icons.swap_horiz_rounded;
      case 'initial': return Icons.first_page_rounded;
      default: return Icons.category_outlined;
    }
  }
}

class _SmartTransactionBubble extends StatefulWidget {
  const _SmartTransactionBubble();

  @override
  State<_SmartTransactionBubble> createState() => _SmartTransactionBubbleState();
}

class _SmartTransactionBubbleState extends State<_SmartTransactionBubble> {
  bool _isExpanded = true;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  void _resetTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _isExpanded = false);
      }
    });
  }

  void _handleTap() {
    if (!_isExpanded) {
      setState(() => _isExpanded = true);
      _resetTimer();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
      ).then((_) => _resetTimer());
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        height: 56,
        width: _isExpanded ? 180 : 56,
        decoration: BoxDecoration(
          color: AppColors.ctaAqua,
          borderRadius: BorderRadius.circular(_isExpanded ? 28 : 28),
          boxShadow: [
            BoxShadow(
              color: AppColors.ctaAqua.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 14), // Padding to center the initial icon
              const Icon(Icons.add_rounded, color: AppColors.textDarkBlue, size: 28),
            if (_isExpanded) ...[
              const SizedBox(width: 8),
              Flexible(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isExpanded ? 1 : 0,
                  child: const Text(
                    'TRANSAKSI',
                    style: TextStyle(
                      color: AppColors.textDarkBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ],
        ),
      ),
    ),
  );
}
}
