import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fina/theme/colors.dart';
import 'package:fina/providers/social_provider.dart';
import 'package:fina/screens/share_data_screen.dart';
import 'package:fina/screens/shared_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/success_modal.dart';

class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen> {

  String _formatTimestamp(dynamic value) {
    try {
      if (value == null) return '-';
      if (value is Timestamp) {
        return DateFormat('dd MMM HH:mm').format(value.toDate());
      }
      if (value is String) {
        return DateFormat('dd MMM HH:mm').format(DateTime.parse(value));
      }
    } catch (_) {}
    return '-';
  }



  @override
  Widget build(BuildContext context) {
    final socialState = ref.watch(socialProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Hubungan Keuangan', style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(socialProvider.notifier).refreshAll(),
          ),
        ],
      ),
      body: socialState.isLoading && socialState.connections.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : socialState.connections.isEmpty
          ? _buildEmptyState(context)
          : Stack(
              children: [
                RefreshIndicator(
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
                if (socialState.isLoading)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ShareDataScreen()),
          );
          if (result == 'added' && mounted) {
            SuccessModal.show(
              context: context,
              title: 'Hubungan Berhasil Ditambahkan!',
              subtitle: 'Hubungan baru Anda telah berhasil didaftarkan dan data akan disinkronkan.',
            );
          }
        },
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
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
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline_rounded, size: 80, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
          ),
          const SizedBox(height: 32),
          Text(
            'Belum ada Hubungan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Scan QR code device lain untuk melihat rekap keuangan mereka di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(BuildContext context, Connection connection, bool isDark) {
    final data = connection.lastData;
    final totalBalance = data?['recap']?['totalBalance'] ?? 0.0;
    final isPending = connection.status == 'pending';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPending 
            ? (connection.isIncoming ? Theme.of(context).colorScheme.primary.withOpacity(0.3) : Theme.of(context).dividerColor)
            : Theme.of(context).dividerColor,
        ),
      ),
      child: ListTile(
        onTap: isPending 
          ? null 
          : () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SharedDetailScreen(connection: connection)),
            ),
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: isPending 
            ? Colors.grey.withOpacity(0.1) 
            : AppColors.ctaAqua.withOpacity(0.2),
          child: Icon(
            isPending ? Icons.person_outline_rounded : Icons.person_rounded, 
            color: isPending ? Colors.grey : AppColors.ctaAqua,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                connection.name,
                style: TextStyle(
                  fontWeight: FontWeight.w900, 
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(isPending ? 0.5 : 1.0),
                ),
              ),
            ),
            if (isPending)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: connection.isIncoming 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  connection.isIncoming ? 'BUTUH ACC' : 'PENDING',
                  style: TextStyle(
                    fontSize: 8, 
                    fontWeight: FontWeight.w900, 
                    color: connection.isIncoming ? Theme.of(context).colorScheme.primary : Colors.grey,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          isPending
            ? (connection.isIncoming ? 'Ingin berbagi data dengan Anda' : 'Menunggu persetujuan...')
            : (data != null 
                ? 'Terakhir update: ${_formatTimestamp(data['updatedAt'])}'
                : 'Data belum dipublikasikan'),
          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
        ),
        trailing: isPending && connection.isIncoming
          ? FilledButton(
              onPressed: () => ref.read(socialProvider.notifier).acceptConnection(connection.id!),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('ACC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            )
          : (!isPending 
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('SALDO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                    Text(
                      NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(totalBalance),
                      style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.secondary),
                    ),
                  ],
                )
              : null),
      ),
    );
  }
}
