import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove any dots or non-numeric characters except for digit characters
    String cleanString = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanString.isEmpty) {
      return newValue.copyWith(text: '');
    }

    double value = double.parse(cleanString);
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );

    String newText = formatter.format(value).trim();

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class CurrencyUtils {
  static double parse(String formattedString) {
    if (formattedString.isEmpty) return 0;
    return double.tryParse(formattedString.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }
}
