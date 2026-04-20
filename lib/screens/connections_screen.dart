import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fina/theme/colors.dart';
import 'package:fina/providers/social_provider.dart';
import 'package:fina/screens/share_data_screen.dart';
import 'package:fina/screens/shared_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socialState = ref.watch(socialProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Hubungan Keuangan', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(socialProvider.notifier).refreshAll(),
          ),
        ],
      ),
      body: socialState.connections.isEmpty
          ? _buildEmptyState(context)
          : RefreshIndicator(
              onRefresh: () => ref.read(socialProvider.notifier).refreshAll(),
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: socialState.connections.length,
                itemBuilder: (context, index) {
                  final connection = socialState.connections[index];
                  return _buildConnectionCard(context, connection, isDark);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ShareDataScreen()),
        ),
        backgroundColor: AppColors.ctaAqua,
        foregroundColor: AppColors.textDarkBlue,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('BAGI DATA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.cardPaleBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline_rounded, size: 80, color: AppColors.textMuted),
          ),
          const SizedBox(height: 32),
          const Text(
            'Belum ada Hubungan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDarkBlue),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Scan QR code device lain untuk melihat rekap keuangan mereka di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(BuildContext context, Connection connection, bool isDark) {
    final data = connection.lastData;
    final totalBalance = data?['recap']?['totalBalance'] ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderColor),
      ),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SharedDetailScreen(connection: connection)),
        ),
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppColors.ctaAqua.withOpacity(0.2),
          child: const Icon(Icons.person_rounded, color: AppColors.ctaAqua),
        ),
        title: Text(
          connection.name,
          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDarkBlue),
        ),
        subtitle: Text(
          data != null 
              ? 'Terakhir update: ${DateFormat('dd MMM HH:mm').format(data['updatedAt'] is Timestamp ? (data['updatedAt'] as Timestamp).toDate() : DateTime.now())}'
              : 'Belum ada data',
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('SALDO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.textMuted)),
            Text(
              NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(totalBalance),
              style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ctaAqua),
            ),
          ],
        ),
      ),
    );
  }
}
