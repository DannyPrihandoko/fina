import 'package:flutter/material.dart';

enum WalletType { cash, bank, ewallet }

class Wallet {
  final int? id;
  final String name;
  final WalletType type;
  final Color color;

  Wallet({
    this.id,
    required this.name,
    required this.type,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'color': color.value,
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'],
      name: map['name'],
      type: WalletType.values.byName(map['type']),
      color: Color(map['color']),
    );
  }

  static IconData getIcon(WalletType type) {
    switch (type) {
      case WalletType.cash:
        return Icons.payments_outlined;
      case WalletType.bank:
        return Icons.account_balance_outlined;
      case WalletType.ewallet:
        return Icons.account_balance_wallet_outlined;
    }
  }
}
