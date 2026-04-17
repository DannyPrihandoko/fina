import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../models/wallet.dart';
import '../theme/colors.dart';
import 'package:intl/intl.dart';

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletsProvider);
    final totalBalance = ref.watch(totalNetWorthProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rp', decimalDigits: 0);

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
        title: const Text('Kelola Dompet', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
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
                      // Total Balance Summary (Glassmorphic)
                      _buildTotalSummary(totalBalance, currencyFormat),
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
                          'Dompet Anda',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDarkBlue),
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
                              return _buildWalletItem(context, ref, wallet, balance, currencyFormat);
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
        onPressed: () => _showWalletDialog(context, ref),
        label: const Text('TAMBAH DOMPET', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        icon: const Icon(Icons.add_rounded, size: 24),
        backgroundColor: AppColors.ctaAqua,
        foregroundColor: AppColors.textDarkBlue,
        elevation: 8,
      ),
    );
  }

  Widget _buildTotalSummary(double total, NumberFormat format) {
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
          Row(
            children: [
              Icon(Icons.account_balance_rounded, color: AppColors.ctaAqua.withOpacity(0.8), size: 16),
              const SizedBox(width: 8),
              const Text(
                'TOTAL SALDO TERKUMPUL',
                style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
            ],
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

  Widget _buildWalletItem(BuildContext context, WidgetRef ref, Wallet wallet, double balance, NumberFormat format) {
    return GestureDetector(
      onLongPress: () => _showWalletDialog(context, ref, wallet: wallet),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(28),
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
              wallet.color.withBlue(wallet.color.blue + 30).withRed(wallet.color.red + 10),
            ],
          ),
        ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    wallet.type.name.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(wallet.name, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              format.format(balance),
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
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
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textDarkBlue),
                  ),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.borderColor, borderRadius: BorderRadius.circular(2)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              TextField(
                controller: nameController,
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Nama Dompet',
                  hintText: 'Misal: BCA, Dompet Tunai',
                  labelStyle: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  prefixIcon: const Icon(Icons.wallet_rounded, color: AppColors.ctaAqua),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.ctaAqua, width: 2)),
                ),
              ),
              if (!isEditing) ...[
                const SizedBox(height: 20),
                TextField(
                  controller: balanceController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDarkBlue),
                  decoration: InputDecoration(
                    labelText: 'Saldo Awal',
                    prefixText: 'Rp ',
                    labelStyle: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    prefixIcon: const Icon(Icons.onetwothree_rounded, color: AppColors.ctaAqua),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.ctaAqua, width: 2)),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Text('TIPE DOMPET', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppColors.textMuted, letterSpacing: 1.5)),
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
                            color: isSelected ? AppColors.textDarkBlue : AppColors.cardPaleBlue.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            type.name.toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textDarkBlue,
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
              const Text('WARNA KARTU', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppColors.textMuted, letterSpacing: 1.5)),
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
                              border: selectedColor == color ? Border.all(color: AppColors.textDarkBlue, width: 3) : null,
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
                      if (isEditing) {
                        final updatedWallet = Wallet(
                          id: wallet.id,
                          name: nameController.text,
                          type: selectedType,
                          color: selectedColor,
                        );
                        ref.read(walletsProvider.notifier).updateWallet(updatedWallet);
                      } else {
                        final newWallet = Wallet(
                          name: nameController.text,
                          type: selectedType,
                          color: selectedColor,
                        );
                        final initialBalance = double.tryParse(balanceController.text) ?? 0;
                        ref.read(walletsProvider.notifier).addWallet(newWallet, initialBalance);
                      }
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textDarkBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 10,
                    shadowColor: AppColors.primary.withOpacity(0.3),
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
