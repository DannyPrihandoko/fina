enum TransactionType { income, expense, transfer, initial }

class Transaction {
  final int? id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String? note;
  final int walletId;
  final int? toWalletId;
  final double adminFee;

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note,
    required this.walletId,
    this.toWalletId,
    this.adminFee = 0,
  });

  Transaction copyWith({
    int? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    DateTime? date,
    String? note,
    int? walletId,
    int? toWalletId,
    double? adminFee,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      walletId: walletId ?? this.walletId,
      toWalletId: toWalletId ?? this.toWalletId,
      adminFee: adminFee ?? this.adminFee,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
      'walletId': walletId,
      'toWalletId': toWalletId,
      'adminFee': adminFee,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      type: TransactionType.values.byName(map['type']),
      category: map['category'],
      date: DateTime.parse(map['date']),
      note: map['note'],
      walletId: map['walletId'] ?? 1, // Default to 1 for migration safety
      toWalletId: map['toWalletId'],
      adminFee: (map['adminFee'] ?? 0).toDouble(),
    );
  }
}
