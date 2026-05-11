import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/bill.dart';
import '../providers/database_provider.dart';
import '../services/notification_service.dart';
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
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              onSurface: Theme.of(context).colorScheme.onSurface,
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

  Future<void> _saveBill() async {
    if (_formKey.currentState!.validate()) {
      final isEditing = widget.existingBill != null;
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
        final id = await ref.read(billsProvider.notifier).addBill(bill);
        if (_reminderEnabled) {
          final savedBill = bill.copyWith(id: id);
          await NotificationService().scheduleBillReminders(savedBill);
        }
      }

      if (mounted) {
        _showSuccessDialog(context, isEditing ? 'Data Berhasil Disimpan!' : 'Tagihan Berhasil Dijadwalkan!');
      }
    }
  }

  void _showSuccessDialog(BuildContext context, String message) {
    final isUpdate = message.toLowerCase().contains('update') || 
                     message.toLowerCase().contains('perubahan') || 
                     message.toLowerCase().contains('simpan');
    
    final subtitle = isUpdate
        ? 'Data tagihan Anda telah diperbarui ke sistem.'
        : 'Data tagihan Anda telah berhasil disimpan.';

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Success Dialog',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => Container(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curvedAnim = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curvedAnim,
          child: FadeTransition(
            opacity: anim1,
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              backgroundColor: Theme.of(context).cardTheme.color,
              elevation: 20,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                            Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 56,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop(); // Close dialog
                          Navigator.of(context).pop(isUpdate ? 'update' : 'add'); // Go back to bills screen
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                        ),
                        child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingBill != null;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurface, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEditing ? 'Edit Tagihan' : 'Tambah Tagihan', style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Selection Area
                    _buildSectionLabel(context, 'NOMINAL TAGIHAN'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandSeparatorFormatter()],
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        prefixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface),
                        hintText: '0',
                        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Masukkan jumlah';
                        if (CurrencyUtils.parse(value) <= 0) return 'Jumlah tidak valid';
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 32),

                    // Title Input
                    _buildSectionLabel(context, 'NAMA TAGIHAN'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
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
                    _buildSectionLabel(context, 'JATUH TEMPO'),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, color: Theme.of(context).colorScheme.secondary, size: 20),
                            const SizedBox(width: 16),
                            Text(
                              DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                              style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Category Toggle
                    _buildSectionLabel(context, 'KATEGORI'),
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
                              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor),
                              boxShadow: isSelected ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : null,
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(14)),
                            child: Icon(Icons.notifications_active_rounded, color: Theme.of(context).colorScheme.secondary, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Notifikasi Aktif', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                                Text('Ingatkan H-1 & Jatuh Tempo', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _reminderEnabled,
                            activeColor: Theme.of(context).colorScheme.secondary,
                            activeTrackColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
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
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 10,
                          shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
      filled: true,
      fillColor: Theme.of(context).cardTheme.color,
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2)),
    );
  }
}
