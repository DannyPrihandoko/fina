import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/bill.dart';
import '../providers/database_provider.dart';
import '../services/notification_service.dart';
import '../theme/colors.dart';
import '../utils/currency_formatter.dart';

class AddBillScreen extends ConsumerStatefulWidget {
  final Bill? existingBill;

  const AddBillScreen({super.key, this.existingBill});

  @override
  ConsumerState<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends ConsumerState<AddBillScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  late String _category;
  late bool _reminderEnabled;

  final List<String> _categories = [
    'Listrik',
    'Air',
    'Internet',
    'Sewa',
    'Asuransi',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingBill?.title ?? '');
    
    // Format amount with separators for display if editing
    final amountText = widget.existingBill != null 
        ? NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(widget.existingBill!.amount).trim()
        : '';
    _amountController = TextEditingController(text: amountText);
    
    _selectedDate = widget.existingBill?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    _category = widget.existingBill?.category ?? 'Listrik';
    _reminderEnabled = widget.existingBill?.reminderEnabled ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)), // Allow past dates for record
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.textDarkBlue,
              onPrimary: Colors.white,
              onSurface: AppColors.textDarkBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveBill() async {
    if (_formKey.currentState!.validate()) {
      final amount = CurrencyUtils.parse(_amountController.text).abs();
      
      final bill = Bill(
        id: widget.existingBill?.id,
        title: _titleController.text,
        amount: amount,
        dueDate: _selectedDate,
        category: _category,
        reminderEnabled: _reminderEnabled,
      );

      if (widget.existingBill != null) {
        await ref.read(billsProvider.notifier).updateBill(bill);
        // Reschedule reminders if needed
        if (_reminderEnabled) {
          await NotificationService().cancelBillReminders(bill.id!);
          await NotificationService().scheduleBillReminders(bill);
        } else {
          await NotificationService().cancelBillReminders(bill.id!);
        }
      } else {
        await ref.read(billsProvider.notifier).addBill(bill);
        // Find newly added bill to schedule reminders
        final updatedBills = ref.read(billsProvider);
        final savedBill = updatedBills.firstWhere((b) => b.title == bill.title && b.amount == bill.amount);
        if (_reminderEnabled) {
          await NotificationService().scheduleBillReminders(savedBill);
        }
      }

      if (mounted) {
        _showSuccessDialog();
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.ctaAqua.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.ctaAqua, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                widget.existingBill != null ? 'Perubahan Disimpan!' : 'Tagihan Ditambahkan!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDarkBlue),
              ),
              const SizedBox(height: 12),
              Text(
                widget.existingBill != null 
                  ? 'Data tagihan Anda telah berhasil diperbarui.' 
                  : 'Tagihan Anda telah berhasil dijadwalkan.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Back to list
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textDarkBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingBill != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Tagihan' : 'Tambah Tagihan', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Input
              Text(
                'JUMLAH TAGIHAN',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandSeparatorFormatter()],
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textDarkBlue),
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDarkBlue),
                  hintText: '0',
                  border: InputBorder.none,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Masukkan jumlah';
                  if (CurrencyUtils.parse(value) <= 0) return 'Jumlah tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Title Input
              Text(
                'NAMA TAGIHAN',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Misal: Listrik PLN',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderColor),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Masukkan nama tagihan';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Date Picker
              Text(
                'JATUH TEMPO',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: AppColors.textDarkBlue, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDarkBlue),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Category Toggle
              Text(
                'KATEGORI',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.bold),
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
              const SizedBox(height: 32),

              // Reminder Toggle
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardPaleBlue.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined, color: AppColors.textDarkBlue),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pengingat Aktif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Notifikasi H-1 & saat jatuh tempo', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _reminderEnabled,
                      activeColor: AppColors.ctaAqua,
                      onChanged: (v) => setState(() => _reminderEnabled = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveBill,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textDarkBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    isEditing ? 'SIMPAN PERUBAHAN' : 'JADWALKAN TAGIHAN', 
                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)
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
