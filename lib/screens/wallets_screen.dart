import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../models/wallet.dart';
import 'package:intl/intl.dart';
import '../widgets/success_modal.dart';

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletsProvider);
    final totalBalance = ref.watch(totalNetWorthProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Kelola Dompet', style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
        centerTitle: false,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 70, left: 20, right: 20),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  // Total Balance Summary (Glassmorphic)
                  _buildTotalSummary(context, totalBalance, currencyFormat),
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
                    'Dompet Anda',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
                if (wallets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: wallets.map((wallet) {
                        final balance = ref.watch(walletBalanceProvider(wallet.id!));
                        return Dismissible(
                          key: ValueKey('wallet_${wallet.id}'),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            if (wallets.length <= 1) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Minimal harus ada 1 dompet tersisa.'),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                                ),
                              );
                              return false;
                            }
                            // Cegah wallet dihapus kalau masih ada transaksi yang mengacu ke sana —
                            // deleteWallet() di database_service.dart tidak cascade-delete transaksi,
                            // jadi transaksi itu akan jadi orphan (tetap muncul di riwayat, ikut
                            // hilang dari perhitungan net worth) kalau dibiarkan lolos.
                            final walletTx = ref.read(walletTransactionsProvider(wallet.id!));
                            if (walletTx.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Tidak bisa hapus "${wallet.name}" — masih ada ${walletTx.length} transaksi. Hapus atau pindahkan transaksinya dulu.'),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                                ),
                              );
                              return false;
                            }
                            return true;
                          },
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 32),
                          ),
                          onDismissed: (direction) {
                            ref.read(walletsProvider.notifier).removeWallet(wallet.id!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Dompet "${wallet.name}" telah dihapus.'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                margin: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                              ),
                            );
                          },
                          child: _buildWalletItem(context, ref, wallet, balance, currencyFormat),
                        );
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
        onPressed: () => _showWalletDialog(context, ref),
        label: const Text('TAMBAH DOMPET', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        icon: const Icon(Icons.add_rounded, size: 24),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        elevation: 8,
      ),
    );
  }

  Widget _buildTotalSummary(BuildContext context, double total, NumberFormat format) {
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
          Row(
            children: [
              Icon(Icons.account_balance_rounded, color: Theme.of(context).colorScheme.secondary, size: 16),
              const SizedBox(width: 8),
              Text(
                'TOTAL SALDO TERKUMPUL',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
            ],
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

  Widget _buildWalletItem(BuildContext context, WidgetRef ref, Wallet wallet, double balance, NumberFormat format) {
    IconData bgIcon;
    switch (wallet.type) {
      case WalletType.cash:
        bgIcon = Icons.payments_rounded;
        break;
      case WalletType.bank:
        bgIcon = Icons.account_balance_rounded;
        break;
      case WalletType.ewallet:
        bgIcon = Icons.smartphone_rounded;
        break;
    }

    return GestureDetector(
      onLongPress: () => _showWalletDialog(context, ref, wallet: wallet),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 180,
        child: Stack(
          children: [
            // Base Card
            Container(
              decoration: BoxDecoration(
                color: wallet.color,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: wallet.color.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    wallet.color,
                    wallet.color.withBlue(wallet.color.blue + 40).withRed(wallet.color.red + 10).withGreen(wallet.color.green + 5),
                  ],
                ),
              ),
            ),
            
            // Large Background Icon
            Positioned(
              right: -20,
              bottom: -20,
              child: Opacity(
                opacity: 0.15,
                child: Icon(
                  bgIcon,
                  size: 160,
                  color: Colors.white,
                ),
              ),
            ),

            // Card Content
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Wallet.getIcon(wallet.type), color: Colors.white, size: 24),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Text(
                          wallet.type.name.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    wallet.name.toUpperCase(), 
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9), 
                      fontSize: 12, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: 1
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(
                    format.format(balance),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWalletDialog(BuildContext context, WidgetRef ref, {Wallet? wallet}) {
    final isEditing = wallet != null;
    final nameController = TextEditingController(text: wallet?.name);
    final balanceController = TextEditingController();
    WalletType selectedType = wallet?.type ?? WalletType.cash;
    Color selectedColor = wallet?.color ?? Colors.blue;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 40,
            left: 28,
            right: 28,
            top: 32,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Dompet' : 'Dompet Baru',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              TextField(
                controller: nameController,
                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Nama Dompet',
                  hintText: 'Misal: BCA, Dompet Tunai',
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  prefixIcon: Icon(Icons.wallet_rounded, color: Theme.of(context).colorScheme.secondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2)),
                ),
              ),
              if (!isEditing) ...[
                const SizedBox(height: 20),
                TextField(
                  controller: balanceController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Saldo Awal',
                    prefixText: 'Rp ',
                    labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    prefixIcon: Icon(Icons.onetwothree_rounded, color: Theme.of(context).colorScheme.secondary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2)),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text('TIPE DOMPET', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), letterSpacing: 1.5)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: WalletType.values.map((type) {
                    final isSelected = selectedType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: GestureDetector(
                        onTap: () => setState(() => selectedType = type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            type.name.toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              Text('WARNA KARTU', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), letterSpacing: 1.5)),
              const SizedBox(height: 12),
              Row(
                children: [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal]
                    .map((color) => GestureDetector(
                          onTap: () => setState(() => selectedColor = color),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 16),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                               border: selectedColor == color ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3) : null,
                              boxShadow: selectedColor == color ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10)] : null,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      String feedbackMessage = '';
                      if (isEditing) {
                        final updatedWallet = Wallet(
                          id: wallet.id,
                          name: nameController.text,
                          type: selectedType,
                          color: selectedColor,
                        );
                        ref.read(walletsProvider.notifier).updateWallet(updatedWallet);
                        feedbackMessage = 'Update Berhasil!';
                      } else {
                        final balanceText = balanceController.text.trim();
                        final initialBalance = double.tryParse(balanceText);
                        if (balanceText.isNotEmpty && initialBalance == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Saldo awal tidak valid, masukkan angka yang benar')),
                          );
                          return;
                        }
                        final newWallet = Wallet(
                          name: nameController.text,
                          type: selectedType,
                          color: selectedColor,
                        );
                        ref.read(walletsProvider.notifier).addWallet(newWallet, initialBalance ?? 0);
                        feedbackMessage = 'Dompet Berhasil Dibuat!';
                      }
                      Navigator.pop(context); // Close bottom sheet
                      SuccessModal.show(
                        context: context,
                        title: feedbackMessage,
                        subtitle: isEditing 
                            ? 'Data dompet Anda telah diperbarui ke sistem.'
                            : 'Dompet baru Anda telah berhasil didaftarkan.',
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 10,
                    shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                  child: Text(
                    isEditing ? 'SIMPAN PERUBAHAN' : 'BUAT DOMPET SEKARANG',
                    style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}
