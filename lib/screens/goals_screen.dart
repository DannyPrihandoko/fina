import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../providers/database_provider.dart';
import '../models/financial_goal.dart';
import '../theme/colors.dart';
import 'add_goal_screen.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              title: Text(
                'Target Dana',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),

          ),

          // Summary Card
          if (goals.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: _buildSummaryCard(context, goals, currencyFormat, isDark),
              ),
            ),

          // Goals List or Empty State
          goals.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState(context))
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final goal = goals[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildGoalCard(context, ref, goal, currencyFormat, isDark),
                        );
                      },
                      childCount: goals.length,
                    ),
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'goals_fab',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddGoalScreen()),
          );
          if (result == 'added') {
            _showSuccessDialog(context, 'Target Berhasil Dibuat!');
          }
        },
        label: const Text('TAMBAH TARGET', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        icon: const Icon(Icons.add_rounded, size: 24),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        elevation: 8,
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, List<FinancialGoal> goals, NumberFormat fmt, bool isDark) {
    final totalTarget = goals.fold<double>(0, (sum, g) => sum + g.targetAmount);
    final totalSaved = goals.fold<double>(0, (sum, g) => sum + g.savedAmount);
    final overallProgress = totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;
    final completedCount = goals.where((g) => g.isCompleted).length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1B263B), const Color(0xFF0D1B2A)]
              : [const Color(0xFF0D1B2A), const Color(0xFF1B263B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D1B2A).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL TARGET',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fmt.format(totalTarget),
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Terkumpul: ${fmt.format(totalSaved)}',
                      style: TextStyle(color: AppColors.ctaAqua.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              CircularPercentIndicator(
                radius: 40,
                lineWidth: 6,
                percent: overallProgress,
                center: Text(
                  '${(overallProgress * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                ),
                progressColor: AppColors.ctaAqua,
                backgroundColor: Colors.white.withOpacity(0.1),
                circularStrokeCap: CircularStrokeCap.round,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMiniStat(context, '$completedCount', 'Tercapai', Colors.greenAccent),
              const SizedBox(width: 16),
              _buildMiniStat(context, '${goals.length - completedCount}', 'Berlangsung', Colors.amberAccent),
              const SizedBox(width: 16),
              _buildMiniStat(context, '${goals.length}', 'Total', Colors.white70),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(BuildContext context, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, WidgetRef ref, FinancialGoal goal, NumberFormat fmt, bool isDark) {
    final colorValue = int.tryParse(goal.color) ?? 0xFF00BFA5;
    final goalColor = Color(colorValue);

    return Dismissible(
      key: Key('goal_${goal.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus Target?'),
            content: Text('Target "${goal.title}" akan dihapus permanen.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('BATAL')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('HAPUS', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref.read(goalsProvider.notifier).removeGoal(goal.id!);
      },
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddGoalScreen(editGoal: goal)),
          );
          if (result == 'updated') {
            _showSuccessDialog(context, 'Target Berhasil Diperbarui!');
          }
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderColor.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: goalColor.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: goalColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(goal.icon, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          goal.isCompleted
                              ? '✅ Tercapai!'
                              : goal.daysRemaining >= 0
                                  ? '${goal.daysRemaining} hari lagi'
                                  : 'Lewat ${-goal.daysRemaining} hari',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: goal.isCompleted
                                ? Colors.green
                                : goal.daysRemaining >= 0
                                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                                    : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Add savings button
                  if (!goal.isCompleted)
                    IconButton(
                      onPressed: () => _showAddSavingsDialog(context, ref, goal, fmt),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: goalColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.add_rounded, color: goalColor, size: 18),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress Bar
              LinearPercentIndicator(
                padding: EdgeInsets.zero,
                lineHeight: 8,
                percent: goal.progress,
                barRadius: const Radius.circular(8),
                progressColor: goal.isCompleted ? Colors.green : goalColor,
                backgroundColor: goalColor.withOpacity(0.1),
                animation: true,
                animationDuration: 800,
              ),
              const SizedBox(height: 10),

              // Amount Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    fmt.format(goal.savedAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: goalColor,
                    ),
                  ),
                  Text(
                    fmt.format(goal.targetAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
            child: Icon(Icons.flag_circle_rounded, size: 80, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
          ),
          const SizedBox(height: 32),
          Text(
            'Belum Ada Target',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Buat target tabungan Anda, seperti dana darurat, liburan, atau gadget impian! 🚀',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSavingsDialog(BuildContext context, WidgetRef ref, FinancialGoal goal, NumberFormat fmt) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tambah Tabungan', style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Target: ${goal.title}',
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
            Text(
              'Sisa: ${fmt.format(goal.remainingAmount)}',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Jumlah tabungan',
                prefixText: 'Rp ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('BATAL', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text.replaceAll('.', '').replaceAll(',', ''));
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Masukkan jumlah tabungan yang valid (lebih dari Rp 0)')),
                );
                return;
              }
              ref.read(goalsProvider.notifier).addSavings(goal, amount);
              Navigator.pop(ctx);

              // Show celebration if completed
              final newSaved = goal.savedAmount + amount;
              if (newSaved >= goal.targetAmount) {
                _showSuccessDialog(context, 'Selamat! Target "${goal.title}" Tercapai! 🎉');
              }
            },
            child: Text('TAMBAH', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.secondary, size: 56),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
          ),
        );
      },
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }
}
