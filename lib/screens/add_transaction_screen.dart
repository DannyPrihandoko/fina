import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../models/transaction.dart';
import '../theme/colors.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  String _category = 'Makanan';

  final List<String> _categories = [
    'Makanan',
    'Belanja',
    'Transportasi',
    'Hiburan',
    'Kesehatan',
    'Lainnya',
    'Pendapatan',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final tx = Transaction(
        title: _titleController.text,
        amount: double.parse(_amountController.text),
        type: _type,
        category: _category,
        date: DateTime.now(),
      );

      ref.read(transactionsProvider.notifier).addTransaction(tx);
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil disimpan!'),
          backgroundColor: AppColors.ctaAqua,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Selector
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.cardPaleBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton(
                        'PENGELUARAN',
                        TransactionType.expense,
                        _type == TransactionType.expense,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTypeButton(
                        'PENDAPATAN',
                        TransactionType.income,
                        _type == TransactionType.income,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Amount Input
              Text(
                'JUMLAH',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 1.5),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.textDarkBlue),
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDarkBlue),
                  hintText: '0',
                  border: InputBorder.none,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Masukkan jumlah';
                  if (double.tryParse(value) == null) return 'Jumlah tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Title Input
              Text(
                'KETERANGAN',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 1.5),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Misal: Makan Siang',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderColor),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Masukkan keterangan';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Category Selector
              Text(
                'KATEGORI',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 1.5),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _category == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _category = cat);
                    },
                    selectedColor: AppColors.ctaAqua,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.textDarkBlue : AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: isSelected ? AppColors.ctaAqua : AppColors.borderColor),
                    ),
                    showCheckmark: false,
                  );
                }).toList(),
              ),
              const SizedBox(height: 48),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  child: const Text('SIMPAN TRANSAKSI', style: TextStyle(letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, TransactionType type, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textDarkBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textMuted,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}
