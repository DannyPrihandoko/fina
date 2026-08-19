class FinancialGoal {
  final int? id;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final DateTime deadline;
  final String icon; // emoji or icon name
  final String color; // hex color string

  FinancialGoal({
    this.id,
    required this.title,
    required this.targetAmount,
    this.savedAmount = 0,
    required this.deadline,
    this.icon = '🎯',
    this.color = '0xFF00BFA5',
  });

  double get progress => targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  double get remainingAmount => (targetAmount - savedAmount).clamp(0, double.infinity);
  bool get isCompleted => savedAmount >= targetAmount;

  int get daysRemaining {
    final now = DateTime.now();
    return deadline.difference(now).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'deadline': deadline.toIso8601String(),
      'icon': icon,
      'color': color,
    };
  }

  factory FinancialGoal.fromMap(Map<String, dynamic> map) {
    return FinancialGoal(
      id: map['id'],
      title: map['title'],
      targetAmount: (map['targetAmount'] as num).toDouble(),
      savedAmount: ((map['savedAmount'] ?? 0) as num).toDouble(),
      deadline: DateTime.parse(map['deadline']),
      icon: map['icon'] ?? '🎯',
      color: map['color'] ?? '0xFF00BFA5',
    );
  }

  FinancialGoal copyWith({
    int? id,
    String? title,
    double? targetAmount,
    double? savedAmount,
    DateTime? deadline,
    String? icon,
    String? color,
  }) {
    return FinancialGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      deadline: deadline ?? this.deadline,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }
}
