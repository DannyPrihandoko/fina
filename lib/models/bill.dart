class Bill {
  final int? id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final String category;
  final bool isRecurring;
  final bool reminderEnabled;

  Bill({
    this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.category,
    this.isRecurring = false,
    this.reminderEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'category': category,
      'isRecurring': isRecurring ? 1 : 0,
      'reminderEnabled': reminderEnabled ? 1 : 0,
    };
  }

  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      dueDate: DateTime.parse(map['dueDate']),
      category: map['category'],
      isRecurring: map['isRecurring'] == 1,
      reminderEnabled: map['reminderEnabled'] == 1,
    );
  }
}
