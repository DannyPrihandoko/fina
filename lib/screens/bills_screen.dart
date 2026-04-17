import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/bill.dart';
import '../providers/database_provider.dart';
import '../theme/colors.dart';
import '../services/notification_service.dart';
import 'add_bill_screen.dart';

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(billsProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rp', decimalDigits: 0);

    // Calculate total bills this month
    double totalBills = 0;
    for (var b in bills) {
      totalBills += b.amount;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tagihan Rutin', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          // BACKGROUND GRADIENT
          Container(
            height: 350,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.mainGradient,
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 64, left: 20, right: 20),
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
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(28, 32, 28, 16),
                        child: Text(
                          'Daftar Tagihan',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDarkBlue),
                        ),
                      ),
                      if (bills.isEmpty)
                        _buildEmptyState(context)
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: bills.map((bill) {
                              // Due soon logic (3 days)
                              final now = DateTime.now();
                              final diff = bill.dueDate.difference(DateTime(now.year, now.month, now.day)).inDays;
                              final isDueSoon = diff >= 0 && diff <= 3;
                              final isOverdue = diff < 0;

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
                                child: _buildBillCard(context, bill, currencyFormat, isDueSoon, isOverdue),
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'bills_fab',
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddBillScreen()));
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
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          Text(
            format.format(total),
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBillCard(BuildContext context, Bill bill, NumberFormat format, bool isDueSoon, bool isOverdue) {
    Color accentColor = isOverdue ? Colors.red : (isDueSoon ? Colors.orange : AppColors.ctaAqua);
    
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
                      child: Icon(Icons.receipt_rounded, color: accentColor, size: 24),
                    ),
                    Row(
                      children: [
                        if (isOverdue || isDueSoon)
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
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.edit_note_rounded, color: AppColors.textMuted, size: 26),
                          onPressed: () {
                            Navigator.push(
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
                      isOverdue ? 'JATUH TEMPO PADA' : 'TANGGAL PENAGIHAN',
                      style: TextStyle(color: isOverdue ? Colors.red : AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMMM yyyy').format(bill.dueDate),
                      style: TextStyle(
                        color: isOverdue ? Colors.red : AppColors.textDarkBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
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
}
