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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tagihan', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: bills.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: bills.length,
              itemBuilder: (context, index) {
                final bill = bills[index];
                
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
                      color: Colors.redAccent.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    ref.read(billsProvider.notifier).removeBill(bill.id!);
                    NotificationService().cancelBillReminders(bill.id!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tagihan ${bill.title} dihapus'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        action: SnackBarAction(
                          label: 'URUNG',
                          onPressed: () {
                            ref.read(billsProvider.notifier).addBill(bill);
                          },
                        ),
                      ),
                    );
                  },
                  child: _buildBillCard(context, bill, currencyFormat, isDueSoon, isOverdue),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'bills_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBillScreen()),
          );
        },
        backgroundColor: AppColors.ctaAqua,
        child: const Icon(Icons.add, color: AppColors.textDarkBlue),
      ),
    );
  }

  Widget _buildBillCard(BuildContext context, Bill bill, NumberFormat format, bool isDueSoon, bool isOverdue) {
    Color cardColor = Colors.white;
    Color accentColor = AppColors.textDarkBlue;
    Color textColor = AppColors.textDarkBlue;

    if (isOverdue) {
      cardColor = const Color(0xFFFFF1F1);
      accentColor = Colors.red;
    } else if (isDueSoon) {
      cardColor = const Color(0xFFFFF8F8);
      accentColor = Colors.orange.shade800;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverdue ? Colors.red.withValues(alpha: 0.3) : (isDueSoon ? Colors.orange.withValues(alpha: 0.3) : AppColors.borderColor),
          width: isOverdue || isDueSoon ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.receipt_outlined, color: accentColor, size: 20),
                    ),
                    Row(
                      children: [
                        if (isOverdue || isDueSoon)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: isOverdue ? Colors.red : Colors.orange.shade800,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isOverdue ? 'TERLAMBAT' : 'SEGARA',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textMuted),
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
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.title,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.category_outlined, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            bill.category,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM yyyy').format(bill.dueDate),
                            style: TextStyle(
                              color: isOverdue ? Colors.red : AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('JUMLAH', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      format.format(bill.amount),
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: textColor),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    // Logic to mark as paid if we implement it, 
                    // otherwise just visual for now or same as delete
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('BAYAR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: AppColors.textMuted.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('Belum ada tagihan terdaftar.', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Tambah tagihan rutin Anda di sini.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
