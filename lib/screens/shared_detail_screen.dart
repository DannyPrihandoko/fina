import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fina/theme/colors.dart';
import 'package:fina/providers/social_provider.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class SharedDetailScreen extends ConsumerWidget {
  final Connection connection;
  const SharedDetailScreen({super.key, required this.connection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = connection.lastData;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: Text(connection.name)),
        body: const Center(child: Text('Data belum tersedia. Silakan refresh Hubungan.')),
      );
    }

    final recap = data['recap'] as Map<String, dynamic>;
    final wallets = (data['wallets'] as List).cast<Map<String, dynamic>>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(connection.name, style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            onPressed: () => ref.read(socialProvider.notifier).refreshConnection(connection.uid),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(context, recap),
            const SizedBox(height: 32),
            _buildSectionLabel(context, 'REKAP BULAN INI'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard(context, 'Pemasukan', recap['totalIncomeMonth'], Theme.of(context).colorScheme.secondary, Icons.arrow_upward_rounded)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard(context, 'Pengeluaran', recap['totalExpenseMonth'], AppColors.error, Icons.arrow_downward_rounded)),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionLabel(context, 'DAFTAR DOMPET'),
            const SizedBox(height: 16),
            ...wallets.map((w) => _buildWalletItem(context, w, isDark)),
            const SizedBox(height: 48),
            Center(
              child: Text(
                'DATA INI ADALAH SALINAN TERAKHIR YANG DIPUBLIKASIKAN',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, Map<String, dynamic> recap) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.mainGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(color: AppColors.textDarkBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          const Text('TOTAL SALDO GABUNGAN', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(recap['totalBalance']),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), letterSpacing: 1.5));
  }

  Widget _buildStatCard(BuildContext context, String label, dynamic amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(amount ?? 0),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletItem(BuildContext context, Map<String, dynamic> wallet, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.ctaAqua.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.ctaAqua, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wallet['name'] ?? 'Dompet', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                Text(wallet['type'] ?? 'Cash', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
              ],
            ),
          ),
          Text(
            NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(wallet['balance'] ?? 0),
            style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
