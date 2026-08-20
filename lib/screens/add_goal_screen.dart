import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../models/financial_goal.dart';
import '../theme/colors.dart';
import '../widgets/success_modal.dart';

class AddGoalScreen extends ConsumerStatefulWidget {
  final FinancialGoal? editGoal;
  const AddGoalScreen({super.key, this.editGoal});

  @override
  ConsumerState<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends ConsumerState<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _savedController;
  late DateTime _deadline;
  String _selectedIcon = '🎯';
  String _selectedColor = '0xFF4CAF50'; // Hijau logo FiNa

  bool get isEditing => widget.editGoal != null;

  final List<String> _icons = ['🎯', '🏠', '🚗', '✈️', '📱', '💻', '🎓', '💍', '🏥', '🎮', '👶', '💼', '🏖️', '📚', '🎸'];
  final List<Map<String, dynamic>> _colors = [
    {'label': 'Hijau', 'value': '0xFF4CAF50'},
    {'label': 'Biru', 'value': '0xFF2196F3'},
    {'label': 'Ungu', 'value': '0xFF7C4DFF'},
    {'label': 'Oranye', 'value': '0xFFFF9800'},
    {'label': 'Merah', 'value': '0xFFE53935'},
    {'label': 'Pink', 'value': '0xFFE91E63'},
    {'label': 'Teal', 'value': '0xFF009688'},
    {'label': 'Amber', 'value': '0xFFFFC107'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.editGoal?.title ?? '');
    _amountController = TextEditingController(
      text: widget.editGoal?.targetAmount.toStringAsFixed(0) ?? '',
    );
    _savedController = TextEditingController(
      text: widget.editGoal?.savedAmount.toStringAsFixed(0) ?? '0',
    );
    _deadline = widget.editGoal?.deadline ?? DateTime.now().add(const Duration(days: 90));
    _selectedIcon = widget.editGoal?.icon ?? '🎯';
    _selectedColor = widget.editGoal?.color ?? '0xFF00BFA5';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _savedController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    final goal = FinancialGoal(
      id: widget.editGoal?.id,
      title: _titleController.text.trim(),
      targetAmount: double.parse(_amountController.text.replaceAll('.', '').replaceAll(',', '')),
      savedAmount: double.tryParse(_savedController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0,
      deadline: _deadline,
      icon: _selectedIcon,
      color: _selectedColor,
    );

    if (isEditing) {
      await ref.read(goalsProvider.notifier).updateGoal(goal);
      if (mounted) {
        SuccessModal.show(
          context: context,
          title: 'Target Diperbarui!',
          subtitle: 'Perubahan pada target Anda telah berhasil disimpan.',
          onConfirm: () => Navigator.pop(context, 'updated'),
        );
      }
    } else {
      await ref.read(goalsProvider.notifier).addGoal(goal);
      if (mounted) {
        SuccessModal.show(
          context: context,
          title: 'Target Berhasil Dibuat!',
          subtitle: 'Semangat! Target baru Anda telah terdaftar di sistem.',
          onConfirm: () => Navigator.pop(context, 'added'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Color(int.tryParse(_selectedColor) ?? 0xFF00BFA5);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Target' : 'Tambah Target',
          style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface),
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          children: [
            // Icon Picker
            _buildSectionLabel(context, 'IKON'),
            const SizedBox(height: 12),
            SizedBox(
              height: 56,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _icons.length,
                itemBuilder: (context, index) {
                  final icon = _icons[index];
                  final isSelected = icon == _selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? accentColor.withOpacity(0.15) : Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? accentColor : (isDark ? AppColors.darkBorder : AppColors.borderColor),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Title
            _buildSectionLabel(context, 'NAMA TARGET'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
              decoration: _buildInputDecoration(context, 'Contoh: Dana Darurat, Liburan Bali'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama target wajib diisi' : null,
            ),

            const SizedBox(height: 24),

            // Target Amount
            _buildSectionLabel(context, 'JUMLAH TARGET'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
              decoration: _buildInputDecoration(context, '0', prefixText: 'Rp '),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Jumlah target wajib diisi';
                final parsed = double.tryParse(v.replaceAll('.', '').replaceAll(',', ''));
                if (parsed == null || parsed <= 0) return 'Masukkan angka yang valid';
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Saved Amount (only for edit)
            if (isEditing) ...[
              _buildSectionLabel(context, 'SUDAH TERKUMPUL'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _savedController,
                keyboardType: TextInputType.number,
                style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
                decoration: _buildInputDecoration(context, '0', prefixText: 'Rp '),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null; // kosong = dianggap 0
                  final parsed = double.tryParse(v.replaceAll('.', '').replaceAll(',', ''));
                  if (parsed == null || parsed < 0) return 'Masukkan angka yang valid';
                  return null;
                },
              ),
              const SizedBox(height: 24),
            ],

            // Deadline
            _buildSectionLabel(context, 'TENGGAT WAKTU'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: accentColor, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      '${_deadline.day}/${_deadline.month}/${_deadline.year}',
                      style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const Spacer(),
                    Text(
                      '${_deadline.difference(DateTime.now()).inDays} hari',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Color Picker
            _buildSectionLabel(context, 'WARNA'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colors.map((c) {
                final colorVal = Color(int.parse(c['value']));
                final isSelected = c['value'] == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c['value']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colorVal,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: colorVal.withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 4))]
                          : [],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: Text(
                  isEditing ? 'SIMPAN PERUBAHAN' : 'BUAT TARGET',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  InputDecoration _buildInputDecoration(BuildContext context, String hint, {String? prefixText}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      prefixText: prefixText,
      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
      filled: true,
      fillColor: Theme.of(context).cardTheme.color,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2)),
    );
  }
}
