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
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEditing ? 'Edit Tagihan' : 'Tambah Tagihan', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          // BACKGROUND GRADIENT
          Container(
            height: 300,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.mainGradient,
              ),
            ),
          ),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 80),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Amount Selection Area
                        _buildSectionLabel('NOMINAL TAGIHAN'),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [ThousandSeparatorFormatter()],
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.textDarkBlue),
                          decoration: InputDecoration(
                            prefixText: 'Rp ',
                            prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textDarkBlue),
                            hintText: '0',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.borderColor)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.ctaAqua, width: 2)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Masukkan jumlah';
                            if (CurrencyUtils.parse(value) <= 0) return 'Jumlah tidak valid';
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 32),

                        // Title Input
                        _buildSectionLabel('NAMA TAGIHAN'),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _titleController,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          decoration: _buildInputDecoration(
                            hint: 'Misal: Listrik PLN',
                            icon: Icons.receipt_rounded,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Masukkan nama tagihan';
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // Date Picker
                        _buildSectionLabel('JATUH TEMPO'),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _selectDate(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.borderColor),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, color: AppColors.ctaAqua, size: 20),
                                const SizedBox(width: 16),
                                Text(
                                  DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDarkBlue, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Category Toggle
                        _buildSectionLabel('KATEGORI'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _categories.map((cat) {
                            final isSelected = _category == cat;
                            return GestureDetector(
                              onTap: () => setState(() => _category = cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.textDarkBlue : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isSelected ? AppColors.textDarkBlue : AppColors.borderColor),
                                  boxShadow: isSelected ? [BoxShadow(color: AppColors.textDarkBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : null,
                                ),
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.textMuted,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 32),

                        // Reminder Toggle Area
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.cardPaleBlue.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                                child: const Icon(Icons.notifications_active_rounded, color: AppColors.ctaAqua, size: 24),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Notifikasi Aktif', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textDarkBlue)),
                                    Text('Ingatkan H-1 & Jatuh Tempo', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _reminderEnabled,
                                activeColor: AppColors.ctaAqua,
                                activeTrackColor: AppColors.ctaAqua.withOpacity(0.2),
                                onChanged: (v) => setState(() => _reminderEnabled = v),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            onPressed: _saveBill,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.textDarkBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              elevation: 10,
                              shadowColor: AppColors.primary.withOpacity(0.3),
                            ),
                            child: Text(
                              isEditing ? 'SIMPAN PERUBAHAN' : 'JADWALKAN TAGIHAN', 
                              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 14)
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: AppColors.ctaAqua, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.ctaAqua, width: 2)),
    );
  }
}
}
