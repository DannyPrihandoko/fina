import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/database_provider.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../utils/currency_formatter.dart';
import '../utils/constants.dart';
import '../widgets/success_modal.dart';
import 'manage_categories_screen.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final double? initialAmount;
  final String? initialTitle;
  final String? initialCategory;

  const AddTransactionScreen({
    super.key,
    this.initialAmount,
    this.initialTitle,
    this.initialCategory,
  });

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  final _adminFeeController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  late String _category;
  int? _selectedWalletId;
  int? _targetWalletId;
  bool _isAutoFilled = false;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory ?? AppConstants.defaultCategory;
    _titleController = TextEditingController(text: widget.initialTitle);
    
    // Formatting initial amount if present
    String initialAmountText = '';
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      initialAmountText = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0)
          .format(widget.initialAmount).trim();
      _isAutoFilled = true;
    }
    _amountController = TextEditingController(text: initialAmountText);

    // Pre-select first wallet if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wallets = ref.read(walletsProvider);
      if (wallets.isNotEmpty) {
        setState(() => _selectedWalletId = wallets.first.id);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _adminFeeController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      if (_selectedWalletId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih dompet terlebih dahulu')));
        return;
      }

      if (_type == TransactionType.transfer && _targetWalletId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih dompet tujuan')));
        return;
      }

      final tx = Transaction(
        title: _titleController.text,
        amount: CurrencyUtils.parse(_amountController.text).abs(),
        type: _type,
        category: _type == TransactionType.transfer ? 'Transfer' : _category,
        date: DateTime.now(),
        walletId: _selectedWalletId!,
        toWalletId: _type == TransactionType.transfer ? _targetWalletId : null,
        adminFee: CurrencyUtils.parse(_adminFeeController.text).abs(),
      );

      ref.read(transactionsProvider.notifier).addTransaction(tx);
      
      SuccessModal.show(
        context: context,
        title: 'Transaksi Berhasil!',
        subtitle: 'Data transaksi Anda telah aman tercatat di sistem.',
        onConfirm: () => Navigator.pop(context),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Transaksi', style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurface, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isAutoFilled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: Theme.of(context).colorScheme.secondary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Data berhasil diisi otomatis melalui AI Scan.',
                          style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

              // Type Selector (Expense, Income, Transfer)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildTypeButton('PENGELUARAN', TransactionType.expense)),
                    const SizedBox(width: 4),
                    Expanded(child: _buildTypeButton('PENDAPATAN', TransactionType.income)),
                    const SizedBox(width: 4),
                    Expanded(child: _buildTypeButton('TRANSFER', TransactionType.transfer)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Wallet Selection Logic
              if (_type == TransactionType.transfer) ...[
                _buildLabel('DARI DOMPET'),
                _buildWalletDropdown(wallets, _selectedWalletId, (val) => setState(() => _selectedWalletId = val)),
                const SizedBox(height: 20),
                _buildLabel('KE DOMPET'),
                _buildWalletDropdown(wallets, _targetWalletId, (val) => setState(() => _targetWalletId = val)),
              ] else ...[
                _buildLabel('PILIH DOMPET'),
                _buildWalletDropdown(wallets, _selectedWalletId, (val) => setState(() => _selectedWalletId = val)),
              ],
              const SizedBox(height: 32),

              // Amount Input
              _buildLabel('JUMLAH'),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandSeparatorFormatter()],
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                  hintText: '0',
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                  border: InputBorder.none,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Masukkan jumlah';
                  if (CurrencyUtils.parse(value) <= 0) return 'Jumlah tidak valid';
                  return null;
                },
              ),

              if (_type == TransactionType.transfer) ...[
                _buildLabel('BIAYA ADMIN (OPSIONAL)'),
                TextFormField(
                  controller: _adminFeeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandSeparatorFormatter()],
                  decoration: const InputDecoration(prefixText: 'Rp ', hintText: '0'),
                ),
                const SizedBox(height: 32),
              ],

              const SizedBox(height: 32),

              // Title Input
              _buildLabel('KETERANGAN'),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: _type == TransactionType.transfer ? 'Misal: Tarik Tunai' : 'Misal: Makan Siang',
                  filled: true,
                  fillColor: Theme.of(context).cardTheme.color,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Masukkan keterangan';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Category Selector (only for income/expense)
              if (_type != TransactionType.transfer) ...[
                _buildLabel('KATEGORI'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Kategori sekarang dinamis dari categoriesProvider (bisa ditambah
                    // user via ManageCategoriesScreen), bukan daftar statis lagi.
                    ...ref.watch(categoriesProvider).map((c) => c.name).map((cat) {
                      final isSelected = _category == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) => selected ? setState(() => _category = cat) : null,
                        selectedColor: Theme.of(context).colorScheme.secondary,
                        backgroundColor: Theme.of(context).cardTheme.color,
                        labelStyle: TextStyle(color: isSelected ? Theme.of(context).colorScheme.onSecondary : Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold, fontSize: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? Theme.of(context).colorScheme.secondary : Theme.of(context).dividerColor)),
                        showCheckmark: false,
                      );
                    }),
                    ActionChip(
                      avatar: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Kelola'),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageCategoriesScreen())),
                      backgroundColor: Theme.of(context).cardTheme.color,
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold, fontSize: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Theme.of(context).dividerColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
              ],

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  child: Text(_type == TransactionType.transfer ? 'LAKUKAN TRANSFER' : 'SIMPAN TRANSAKSI', style: const TextStyle(letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildWalletDropdown(List<Wallet> wallets, int? selectedId, Function(int?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedId,
          hint: const Text('Pilih Dompet'),
          isExpanded: true,
          items: wallets.map((w) => DropdownMenuItem(
            value: w.id,
            child: Row(
              children: [
                Icon(Wallet.getIcon(w.type), size: 18, color: w.color),
                const SizedBox(width: 12),
                Text(w.name, style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, TransactionType type) {
    final isSelected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w800, fontSize: 9),
          ),
        ),
      ),
    );
  }
}
