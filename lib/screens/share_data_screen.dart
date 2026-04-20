import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fina/theme/colors.dart';
import 'package:fina/services/firebase_service.dart';
import 'package:fina/providers/social_provider.dart';
import 'package:fina/providers/database_provider.dart';
import 'package:fina/models/transaction.dart';
import 'package:fina/providers/settings_provider.dart';
import 'dart:convert';

class ShareDataScreen extends ConsumerStatefulWidget {
  const ShareDataScreen({super.key});

  @override
  ConsumerState<ShareDataScreen> createState() => _ShareDataScreenState();
}

class _ShareDataScreenState extends ConsumerState<ShareDataScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _publishData() async {
    setState(() => _isPublishing = true);
    
    try {
      final transactions = ref.read(transactionsProvider);
      final wallets = ref.read(walletsProvider);
      
      // Calculate Recap
      double totalIncome = 0;
      double totalExpense = 0;
      for (var t in transactions) {
        if (t.type == TransactionType.income) totalIncome += t.amount;
        if (t.type == TransactionType.expense) totalExpense += t.amount;
      }

      final snapshot = {
        'recap': {
          'totalBalance': wallets.fold<double>(0, (sum, w) => sum + ref.read(walletBalanceProvider(w.id!))),
          'totalIncomeMonth': totalIncome,
          'totalExpenseMonth': totalExpense,
        },
        'wallets': wallets.map((w) => {
          'name': w.name,
          'type': w.type.name,
          'balance': ref.read(walletBalanceProvider(w.id!)),
        }).toList(),
      };

      final settings = ref.read(settingsProvider);

      await FirebaseService().publishSnapshot(snapshot, userName: settings.userName);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil dipublikasikan!')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseService().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bagi Data Keuangan', style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.secondary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          tabs: const [
            Tab(text: 'ID SAYA'),
            Tab(text: 'SCAN QR'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyIdTab(user),
          _buildScanTab(),
        ],
      ),
    );
  }

  Widget _buildMyIdTab(user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          if (user == null)
            ElevatedButton(
              onPressed: () async {
                await FirebaseService().ensureLoggedIn();
                setState(() {});
              },
              child: const Text('AKTIFKAN IDENTITAS'),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: QrImageView(
                data: user.uid,
                version: QrVersions.auto,
                size: 200.0,
                eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.circle, color: Theme.of(context).colorScheme.onSurface),
                dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'UID: ${user.uid.substring(0, 8)}...',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),
            Text(
              'Publikasikan ringkasan keuangan Anda agar device lain bisa melihatnya.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isPublishing ? null : _publishData,
                icon: _isPublishing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(_isPublishing ? 'MEMPUBLIKASIKAN...' : 'PUBLIKASIKAN DATA'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanTab() {
    return MobileScanner(
      onDetect: (capture) async {
        final List<Barcode> barcodes = capture.barcodes;
        for (final barcode in barcodes) {
          if (barcode.rawValue != null) {
            final uid = barcode.rawValue!;
            _showAddConnectionDialog(uid);
            break;
          }
        }
      },
    );
  }

  void _showAddConnectionDialog(String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Hubungan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Berikan nama untuk device ini:', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              cursorColor: Theme.of(context).colorScheme.primary,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Contoh: Istri, Tablet',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('BATAL', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              if (name.isNotEmpty) {
                await ref.read(socialProvider.notifier).addConnection(uid, name);
                if (mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Back to ConnectionsScreen
                }
              }
            },
            child: Text('TAMBAH', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
