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
        _showSuccessDialogWith(widget.successMessage ?? 'Tagihan Berhasil!');
      });
    }
  }

  void _showSuccessDialogWith(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.ctaAqua.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.ctaAqua, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                message,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDarkBlue),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message == 'Update Berhasil!' 
                    ? 'Data tagihan Anda telah diperbarui ke sistem.'
                    : 'Data tagihan Anda telah berhasil disimpan.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textDarkBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDarkBlue, size: 20),
          onPressed: () => ref.read(navigationProvider.notifier).state = 0,
        ),
        title: const Text('Tagihan Rutin', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDarkBlue)),
        centerTitle: false,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, left: 20, right: 20),
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
                const Padding(
                  padding: EdgeInsets.fromLTRB(28, 32, 28, 16),
                  child: Text(
                    'Tagihan Aktif',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDarkBlue),
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

                const Padding(
                  padding: EdgeInsets.fromLTRB(28, 48, 28, 16),
                  child: Text(
                    'Riwayat Pembayaran',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDarkBlue),
                  ),
                ),
                if (bills.where((b) => b.isPaid).isEmpty)
                   const Center(
                     child: Padding(
                       padding: EdgeInsets.symmetric(vertical: 40),
                       child: Text('Belum ada tagihan yang dibayar.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
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
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddBillScreen()));
          if (result != null && mounted) {
            _showSuccessDialogWith(result == 'update' ? 'Update Berhasil!' : 'Tagihan Berhasil!');
          }
        },
        label: const Text('TAMBAH TAGIHAN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        icon: const Icon(Icons.add_rounded, size: 24),
        backgroundColor: AppColors.ctaAqua,
        foregroundColor: AppColors.textDarkBlue,
        elevation: 8,
      ),
    );
  }

  Widget _buildBillsSummary(double total, NumberFormat format) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.cardPaleBlue,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDarkBlue.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL TAGIHAN BULAN INI',
            style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          Text(
            format.format(total),
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.textDarkBlue, letterSpacing: -0.5),
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
    Color accentColor = bill.isPaid ? Colors.green : (isOverdue ? Colors.red : (isDueSoon ? Colors.orange : AppColors.ctaAqua));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.borderColor.withOpacity(0.2),
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
                              isOverdue ? 'TERLAMBAT' : 'SEGARA',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            ),
                          ),
                        if (!bill.isPaid)
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.edit_note_rounded, color: AppColors.textMuted, size: 26),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AddBillScreen(existingBill: bill)),
                              );
                              if (result != null && mounted) {
                                _showSuccessDialogWith(result == 'update' ? 'Update Berhasil!' : 'Tagihan Berhasil!');
                              }
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
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.textDarkBlue),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.category_rounded, size: 12, color: AppColors.textMuted.withOpacity(0.5)),
                          const SizedBox(width: 6),
                          Text(
                            bill.category.toUpperCase(),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.notifications_active_rounded, size: 12, color: bill.reminderEnabled ? AppColors.ctaAqua : AppColors.textMuted.withOpacity(0.5)),
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
              color: AppColors.cardPaleBlue.withOpacity(0.2),
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
                      style: TextStyle(color: isOverdue && !bill.isPaid ? Colors.red : AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMMM yyyy').format(bill.dueDate),
                      style: TextStyle(
                        color: isOverdue && !bill.isPaid ? Colors.red : AppColors.textDarkBlue,
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
                      backgroundColor: isOverdue ? Colors.red : AppColors.textDarkBlue,
                      foregroundColor: Colors.white,
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
                      const Text('JUMLAH', style: TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(
                        format.format(bill.amount),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textDarkBlue),
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
                  const Text('Pilih Dompet Pembayaran', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDarkBlue)),
                  const SizedBox(height: 24),
                  if (wallets.isEmpty)
                    const Text('Silakan buat dompet terlebih dahulu.')
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
                            title: Text(wallet.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDarkBlue)),
                            subtitle: Text('Saldo: ${currencyFormat.format(balance)}', style: const TextStyle(fontSize: 12)),
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
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 64),
              const SizedBox(height: 24),
              const Text('Pembayaran Berhasil!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDarkBlue)),
              const SizedBox(height: 12),
              const Text('Tagihan telah dibayarkan dan dicatat sebagai pengeluaran.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textDarkBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                color: AppColors.cardPaleBlue.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_rounded, size: 56, color: AppColors.textMuted.withOpacity(0.2)),
            ),
            const SizedBox(height: 24),
            const Text('Belum ada tagihan terdaftar.', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Tambah tagihan rutin Anda di sini.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
