import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
                return Dismissible(
                  key: Key('bill_${bill.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
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
                  child: _buildBillCard(context, bill, currencyFormat),
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

  Widget _buildBillCard(BuildContext context, dynamic bill, NumberFormat format) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.textDarkBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_outlined, color: AppColors.textDarkBlue),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'JATUH TEMPO',
                    style: TextStyle(color: Color(0xFFD32F2F), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bill.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(bill.category, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.borderColor),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('JUMLAH', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(format.format(bill.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle_outline, color: AppColors.ctaAqua, size: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: AppColors.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('Belum ada tagihan terdaftar.', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Tambah tagihan rutin Anda di sini.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
