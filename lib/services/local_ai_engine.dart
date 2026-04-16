import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/bill.dart';

enum AIIntent {
  greeting,
  status,
  analysis,
  savings,
  bills,
  help,
  unknown
}

class LocalAIEngine {
  final currencyFormat = NumberFormat.currency(symbol: 'Rp', decimalDigits: 0);

  /// Analyzes the user's query and returns a structured response.
  String processQuery({
    required String query,
    required List<Transaction> transactions,
    required List<Bill> bills,
  }) {
    final normalizedQuery = query.toLowerCase();
    final intent = _detectIntent(normalizedQuery);

    double income = 0;
    double expense = 0;
    double wants = 0;
    double savings = 0;

    for (var tx in transactions) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
        if (['hiburan', 'belanja', 'makanan', 'jajan'].contains(tx.category.toLowerCase())) {
          wants += tx.amount;
        }
      }
    }
    savings = income - expense;

    switch (intent) {
      case AIIntent.greeting:
        return _getGreetingResponse(normalizedQuery);
      case AIIntent.status:
        return _getStatusResponse(income, expense, savings);
      case AIIntent.analysis:
        return _getAnalysisResponse(income, expense, wants, savings);
      case AIIntent.savings:
        return _getSavingsResponse(income, expense, savings);
      case AIIntent.bills:
        return _getBillsResponse(bills, savings);
      case AIIntent.help:
        return "Saya bisa membantu Anda dengan:\n"
            "• **Analisis Keuangan**: Tanya 'gimana kondisi keuangan?'\n"
            "• **Status Saldo**: Tanya 'berapa sisa duit?'\n"
            "• **Dana Darurat**: Tanya 'tabungan aman gak?'\n"
            "• **Info Tagihan**: Tanya 'ada tagihan apa?'\n"
            "Coba tanya saya sekarang!";
      default:
        return "Hmm, saya belum paham maksud Anda. Coba tanya tentang 'analisis', 'status', atau 'tagihan'. Saya juga mengerti istilah seperti 'boncos' atau 'cuan'!";
    }
  }

  AIIntent _detectIntent(String query) {
    if (_containsAny(query, ['halo', 'hi', 'hallo', 'hai', 'pagi', 'siang', 'malam'])) return AIIntent.greeting;
    if (_containsAny(query, ['status', 'saldo', 'duit', 'sisa', 'cuan', 'bokek', 'uang'])) return AIIntent.status;
    if (_containsAny(query, ['analisis', 'kondisi', 'kabar', 'review', 'gimana', 'boncos', 'boros', 'saran'])) return AIIntent.analysis;
    if (_containsAny(query, ['tabungan', 'simpanan', 'darurat', 'aman', 'hemat', 'savings'])) return AIIntent.savings;
    if (_containsAny(query, ['tagihan', 'bayar', 'bills', 'cicilan', 'hutang'])) return AIIntent.bills;
    if (_containsAny(query, ['help', 'tolong', 'bantuan', 'bisa apa'])) return AIIntent.help;
    return AIIntent.unknown;
  }

  bool _containsAny(String query, List<String> keywords) {
    return keywords.any((k) => query.contains(k));
  }

  String _getGreetingResponse(String query) {
    if (query.contains('pagi')) return "Selamat pagi! Siap mengelola keuangan hari ini?";
    if (query.contains('siang')) return "Selamat siang! Jangan lupa catat jajan Anda ya.";
    if (query.contains('malam')) return "Selamat malam! Mari kita review pengeluaran hari ini.";
    return "Halo! Saya asisten fina. Ada yang bisa saya bantu analisis hari ini?";
  }

  String _getStatusResponse(double income, double expense, double savings) {
    String status = savings >= 0 ? "aman" : "kritis (boncos)";
    return "Status Keuangan saat ini:\n"
        "• Total Pemasukan: **${currencyFormat.format(income)}**\n"
        "• Total Pengeluaran: **${currencyFormat.format(expense)}**\n"
        "• Sisa Saldo: **${currencyFormat.format(savings)}**\n\n"
        "Kondisi Anda saat ini termasuk **$status**. " +
        (savings < 0 ? "Waspada, pengeluaran lebih besar dari pemasukan!" : "Pertahankan saldo positif Anda!");
  }

  String _getAnalysisResponse(double income, double expense, double wants, double savings) {
    if (income <= 0) return "Saya belum bisa menganalisis karena data pemasukan Anda masih kosong. Yuk, catat pemasukan dulu!";

    double wantsPercentage = (wants / income) * 100;
    double savingsRate = (savings / income) * 100;

    String advice = "";
    if (wantsPercentage > 30) {
      advice += "⚠️ Pengeluaran 'Wants' (jajan/hiburan) Anda sudah **${wantsPercentage.toStringAsFixed(1)}%**. Ini di atas batas ideal 30%. Hati-hati jangan sampai kalap!\n\n";
    } else {
      advice += "✅ Pengeluaran 'Wants' terkontrol dengan baik di angka **${wantsPercentage.toStringAsFixed(1)}%**. Bagus!\n\n";
    }

    if (savingsRate < 20) {
      advice += "📉 Tabungan Anda baru **${savingsRate.toStringAsFixed(1)}%** dari pemasukan. Coba targetkan minimal 20% untuk masa depan yang lebih tenang.";
    } else {
      advice += "🚀 Luar biasa! Anda berhasil menyisihkan **${savingsRate.toStringAsFixed(1)}%** untuk ditabung. Ini adalah kebiasaan finansial yang sangat sehat.";
    }

    return "Hasil Analisis Fina:\n\n$advice";
  }

  String _getSavingsResponse(double income, double expense, double savings) {
    double avgExpense = expense > 0 ? expense : 1000000; // Mock average if empty
    double target = avgExpense * 3;
    
    if (savings < target) {
      double gap = target - savings;
      return "Tentang Dana Darurat Anda:\n"
          "Saat ini tabungan Anda belum mencapai zona aman (3x pengeluaran bulanan). Anda butuh sekitar **${currencyFormat.format(gap)}** lagi untuk mencapai target dana darurat **${currencyFormat.format(target)}**. Semangat menabung!";
    }
    
    return "Dana darurat Anda sudah aman! Anda memiliki cadangan yang cukup untuk menanggung pengeluaran selama setidaknya 3 bulan ke depan. Fokus selanjutnya bisa ke investasi.";
  }

  String _getBillsResponse(List<Bill> bills, double savings) {
    if (bills.isEmpty) return "Sejauh ini tidak ada tagihan terdaftar. Hidup bebas hutang itu melegakan!";
    
    double totalBills = bills.fold(0, (sum, b) => sum + b.amount);
    
    String response = "Anda memiliki **${bills.length} tagihan** dengan total **${currencyFormat.format(totalBills)}**.\n\n";
    
    if (savings < totalBills) {
      response += "⚠️ Perhatian: Saldo Anda saat ini tidak cukup untuk menutup semua tagihan mendatang. Segera siapkan dana agar tidak menunggak!";
    } else {
      response += "✅ Saldo Anda saat ini mencukupi untuk membayar semua tagihan. Jangan lupa bayar tepat waktu ya!";
    }
    
    return response;
  }
}
