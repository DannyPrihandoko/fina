import 'package:flutter/material.dart';
import '../theme/colors.dart';

class StreakBadge extends StatelessWidget {
  final int streakCount;
  final double? top;
  final double? right;

  const StreakBadge({
    super.key,
    required this.streakCount,
    this.top,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    // Structure: Theme -> Stack -> Positioned -> MyWidget()
    return Theme(
      data: Theme.of(context).copyWith(
        // Custom local theme for the badge component
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.ctaAqua.withOpacity(0.1),
          side: BorderSide(color: AppColors.ctaAqua.withOpacity(0.2)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            color: AppColors.ctaAqua,
          ),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: top,
            right: right,
            child: _MyBadgeWidget(streakCount: streakCount),
          ),
        ],
      ),
    );
  }
}

class _MyBadgeWidget extends StatelessWidget {
  final int streakCount;
  const _MyBadgeWidget({required this.streakCount});

  @override
  Widget build(BuildContext context) {
    // Accessing the theme defined in the parent Theme widget
    final theme = Theme.of(context).chipTheme;
    
    return Container(
      padding: theme.padding,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: theme.side != null ? Border.fromBorderSide(theme.side!) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 18),
          const SizedBox(width: 4),
          Text(
            '$streakCount',
            style: theme.labelStyle,
          ),
        ],
      ),
    );
  }
}
