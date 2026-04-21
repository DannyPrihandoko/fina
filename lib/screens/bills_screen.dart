import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/bill.dart';
import '../providers/database_provider.dart';
import '../theme/colors.dart';
import '../services/notification_service.dart';
import 'add_bill_screen.dart';
import '../providers/navigation_provider.dart';

class BillsScreen extends ConsumerStatefulWidget {
  final bool showSuccessModal;
  final String? successMessage;
  const BillsScreen({super.key, this.showSuccessModal = false, this.successMessage});

  @override
  ConsumerState<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.showSuccessModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showSuccessDialog(widget.successMessage ?? 'Tagihan Berhasil!');
        }
      });
    }
  }

  void _showSuccessDialog(String message) {
    if (!mounted) return;
    
    final isUpdate = message.toLowerCase().contains('update') || 
                     message.toLowerCase().contains('perubahan') || 
                     message.toLowerCase().contains('simpan');
    final isPayment = message.toLowerCase().contains('pembayaran');
    final subtitle = isPayment
        ? 'Tagihan telah dibayarkan dan dicatat sebagai pengeluaran.'
        : isUpdate
            ? 'Data tagihan Anda telah diperbarui ke sistem.'
            : 'Data tagihan Anda telah berhasil disimpan.';

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Success Dialog',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return Container();
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curvedAnim = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curvedAnim,
          child: FadeTransition(
            opacity: anim1,
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              backgroundColor: Theme.of(ctx).cardTheme.color,
              elevation: 20,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated check icon
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(ctx).colorScheme.secondary.withOpacity(0.2),
                              Theme.of(ctx).colorScheme.primary.withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: Theme.of(ctx).colorScheme.secondary,
                          size: 56,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(ctx).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(ctx).colorScheme.primary,
                          foregroundColor: Theme.of(ctx).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: Theme.of(ctx).colorScheme.primary.withOpacity(0.3),
                        ),
                        child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bills = ref.watch(billsProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rp', decimalDigits: 0);

    // Calculate total bills this month
    double totalBills = 0;
    for (var b in bills) {
      totalBills += b.amount;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () {
            ref.read(navigationProvider.notifier).state = 0;
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text('Tagihan Rutin', style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
        centerTitle: false,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 70, left: 20, right: 20),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  // Monthly Bills Summary (Glassmorphic)
                  _buildBillsSummary(totalBills, currencyFormat),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
                  child: Text(
                    'Tagihan Aktif',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
                if (bills.where((b) => !b.isPaid).isEmpty)
                  _buildEmptyState(context)
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: bills.where((b) => !b.isPaid).map((bill) {
                        final now = DateTime.now();
                        final diff = bill.dueDate.difference(DateTime(now.year, now.month, now.day)).inDays;
                        final isDueSoon = diff >= 0 && diff <= 3;
                        final isOverdue = diff < 0;

                        return _buildDismissibleBill(context, bill, currencyFormat, isDueSoon, isOverdue);
                      }).toList(),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 48, 28, 16),
                  child: Text(
                    'Riwayat Pembayaran',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
                if (bills.where((b) => b.isPaid).isEmpty)
                   Center(
                     child: Padding(
                       padding: const EdgeInsets.symmetric(vertical: 40),
                       child: Text('Belum ada tagihan yang dibayar.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 13)),
                     ),
                   )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: bills.where((b) => b.isPaid).map((bill) {
                        return _buildBillCard(context, bill, currencyFormat, false, false);
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'bills_fab',
        onPressed: () async {
          await Navigator.push<String>(
            context,
            MaterialPageRoute(builder: (context) => const AddBillScreen()),
          );
        },
        label: const Text('TAMBAH TAGIHAN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        icon: const Icon(Icons.add_rounded, size: 24),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        elevation: 8,
      ),
    );
  }

  Widget _buildBillsSummary(double total, NumberFormat format) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL TAGIHAN BULAN INI',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          Text(
            format.format(total),
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissibleBill(BuildContext context, Bill bill, NumberFormat format, bool isDueSoon, bool isOverdue) {
    return Dismissible(
      key: Key('bill_${bill.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.8),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        ref.read(billsProvider.notifier).removeBill(bill.id!);
        NotificationService().cancelBillReminders(bill.id!);
      },
      child: _buildBillCard(context, bill, format, isDueSoon, isOverdue),
    );
  }

  Widget _buildBillCard(BuildContext context, Bill bill, NumberFormat format, bool isDueSoon, bool isOverdue) {
    Color accentColor = bill.isPaid ? Colors.green : (isOverdue ? Colors.red : (isDueSoon ? Colors.orange : Theme.of(context).colorScheme.secondary));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(bill.isPaid ? Icons.check_circle_rounded : Icons.receipt_rounded, color: accentColor, size: 24),
                    ),
                    Row(
                      children: [
                        if (bill.isPaid)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.withOpacity(0.3)),
                            ),
                            child: const Text(
                              'SUDAH DIBAYAR',
                              style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            ),
                          )
                        else if (isOverdue || isDueSoon)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isOverdue ? 'TERLAMBAT' : 'SEGERA',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            ),
                          ),
                        if (!bill.isPaid)
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(Icons.edit_note_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 26),
                            onPressed: () async {
                              await Navigator.push<String>(
                                context,
                                MaterialPageRoute(builder: (context) => AddBillScreen(existingBill: bill)),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.title,
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.category_rounded, size: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                          const SizedBox(width: 6),
                          Text(
                            bill.category.toUpperCase(),
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.notifications_active_rounded, size: 12, color: bill.reminderEnabled ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.isPaid ? 'DIBAYAR PADA' : (isOverdue ? 'JATUH TEMPO PADA' : 'TANGGAL PENAGIHAN'),
                      style: TextStyle(color: isOverdue && !bill.isPaid ? Colors.red : Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMMM yyyy').format(bill.dueDate),
                      style: TextStyle(
                        color: isOverdue && !bill.isPaid ? Colors.red : Theme.of(context).colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                if (!bill.isPaid)
                  ElevatedButton(
                    onPressed: () => _showWalletSelector(context, bill),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOverdue ? Colors.red : Theme.of(context).colorScheme.primary,
                      foregroundColor: isOverdue ? Colors.white : Theme.of(context).colorScheme.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('BAYAR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('JUMLAH', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(
                        format.format(bill.amount),
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showWalletSelector(BuildContext context, Bill bill) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final wallets = ref.watch(walletsProvider);
            return Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pilih Dompet Pembayaran', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 24),
                  if (wallets.isEmpty)
                    Text('Silakan buat dompet terlebih dahulu.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)))
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: wallets.length,
                        itemBuilder: (context, index) {
                          final wallet = wallets[index];
                          final balance = ref.watch(walletBalanceProvider(wallet.id!));
                          final currencyFormat = NumberFormat.currency(symbol: 'Rp', decimalDigits: 0);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: wallet.color.withOpacity(0.1), shape: BoxShape.circle),
                              child: Icon(Icons.account_balance_wallet_rounded, color: wallet.color),
                            ),
                            title: Text(wallet.name, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                            subtitle: Text('Saldo: ${currencyFormat.format(balance)}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                            onTap: () {
                              Navigator.pop(context);
                              ref.read(billsProvider.notifier).payBill(bill, wallet.id!);
                              _showPaymentSuccess(context);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPaymentSuccess(BuildContext context) {
    _showSuccessDialog('Pembayaran Berhasil!');
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_rounded, size: 56, color: Theme.of(context).colorScheme.secondary.withOpacity(0.4)),
            ),
            const SizedBox(height: 24),
            Text('Belum ada tagihan terdaftar.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Tambah tagihan rutin Anda di sini.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
