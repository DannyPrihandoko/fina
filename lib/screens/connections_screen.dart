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

  Future<bool> _confirmRemove(BuildContext context, String title, String message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('BATAL', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('HAPUS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Widget _buildConnectionCard(BuildContext context, Connection connection, bool isDark) {
    final data = connection.lastData;
    final totalBalance = data?['recap']?['totalBalance'] ?? 0.0;
    final isPending = connection.status == 'pending';
    final isIncomingRequest = isPending && connection.isIncoming;

    if (isIncomingRequest) {
      return _buildCardContent(context, connection, isDark, data, totalBalance, isPending);
    }

    // Koneksi accepted atau permintaan keluar (outgoing pending) bisa dihapus/dibatalkan via swipe.
    return Dismissible(
      key: ValueKey(connection.uid),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmRemove(
        context,
        isPending ? 'Batalkan Permintaan?' : 'Hapus Hubungan?',
        isPending
            ? 'Permintaan koneksi ke ${connection.name} akan dibatalkan.'
            : 'Hubungan dengan ${connection.name} akan dihapus dan tidak bisa melihat data satu sama lain lagi.',
      ),
      onDismissed: (_) => ref.read(socialProvider.notifier).removeConnection(connection.uid),
      child: _buildCardContent(context, connection, isDark, data, totalBalance, isPending),
    );
  }

  Widget _buildCardContent(BuildContext context, Connection connection, bool isDark, Map<String, dynamic>? data, dynamic totalBalance, bool isPending) {
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
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.error),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Tolak',
                  onPressed: () async {
                    final confirmed = await _confirmRemove(
                      context,
                      'Tolak Permintaan?',
                      'Permintaan koneksi dari ${connection.name} akan ditolak.',
                    );
                    if (confirmed) {
                      ref.read(socialProvider.notifier).removeConnection(connection.uid);
                    }
                  },
                ),
                FilledButton(
                  onPressed: () => ref.read(socialProvider.notifier).acceptConnection(connection.id!),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ACC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
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
