class Budget {
  final int? id;
  final String category;
  final double limitAmount;

  Budget({
    this.id,
    required this.category,
    required this.limitAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'limitAmount': limitAmount,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      category: map['category'],
      limitAmount: (map['limitAmount'] ?? 0).toDouble(),
    );
  }

  Budget copyWith({
    int? id,
    String? category,
    double? limitAmount,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
    );
  }
}
