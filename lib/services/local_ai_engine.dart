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
    double needs = 0;
    double wants = 0;
    double savings = 0;

    for (var tx in transactions) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
        final cat = tx.category.toLowerCase();
        // Categorization for 50/30/20
        if (['makanan', 'transportasi', 'kesehatan', 'cicilan', 'tagihan', 'listrik', 'air'].contains(cat)) {
          needs += tx.amount;
        } else if (['hiburan', 'belanja', 'hobi', 'jajan', 'nonton'].contains(cat)) {
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
        return _getAnalysisResponse(income, expense, needs, wants, savings);
      case AIIntent.savings:
        return _getSavingsResponse(income, expense, savings);
      case AIIntent.bills:
        return _getBillsResponse(bills, savings);
      case AIIntent.help:
        return "### 🤖 Apa yang bisa saya bantu?\n\n"
            "Saya adalah asisten finansial Anda. Anda bisa menanyakan hal berikut:\n\n"
            "* **Analisis Kesehatan**: 'Gimana kondisi keuangan saya?'\n"
            "* **Status Saldo**: 'Berapa sisa uang saya sekarang?'\n"
            "* **Dana Darurat**: 'Tabungan saya sudah aman belum?'\n"
            "* **Info Tagihan**: 'Apa ada tagihan yang harus dibayar?'\n\n"
            "Silakan ketik pertanyaan Anda di bawah!";
      default:
        return "Hmm, saya belum terlalu mengerti maksud tersebut. 🤔\n\n"
            "Coba tanya tentang **'analisis'**, **'status'**, atau **'tagihan'**. Saya juga mengerti istilah seperti **'boncos'** atau **'cuan'**!";
    }
  }

  AIIntent _detectIntent(String query) {
    if (_containsAny(query, ['halo', 'hi', 'hallo', 'hai', 'pagi', 'siang', 'malam'])) return AIIntent.greeting;
    if (_containsAny(query, ['status', 'saldo', 'duit', 'sisa', 'cuan', 'bokek', 'uang'])) return AIIntent.status;
    if (_containsAny(query, ['analisis', 'kondisi', 'kabar', 'review', 'gimana', 'boncos', 'boros', 'saran', 'kesehatan'])) return AIIntent.analysis;
    if (_containsAny(query, ['tabungan', 'simpanan', 'darurat', 'aman', 'hemat', 'savings', 'cadangan'])) return AIIntent.savings;
    if (_containsAny(query, ['tagihan', 'bayar', 'bills', 'cicilan', 'hutang', 'bayaran'])) return AIIntent.bills;
    if (_containsAny(query, ['help', 'tolong', 'bantuan', 'bisa apa'])) return AIIntent.help;
    return AIIntent.unknown;
  }

  bool _containsAny(String query, List<String> keywords) {
    return keywords.any((k) => query.contains(k));
  }

  String _getGreetingResponse(String query) {
    if (query.contains('pagi')) return "Selamat pagi! ☀️ Siap mengelola keuangan dengan bijak hari ini?";
    if (query.contains('siang')) return "Selamat siang! 👋 Jangan lupa catat pengeluaran makan siang Anda ya.";
    if (query.contains('malam')) return "Selamat malam! 🌙 Mari kita review aktivitas finansial Anda hari ini.";
    return "Halo! Saya asisten **fina**. Ada yang bisa saya bantu analisis hari ini? 😊";
  }

  String _getStatusResponse(double income, double expense, double savings) {
    String statusEmoji = savings >= 0 ? "✅" : "⚠️";
    String statusTxt = savings >= 0 ? "Surplus (Sehat)" : "Defisit (Boncos)";
    
    return "### 💰 Ringkasan Saldo Anda\n\n"
        "* Total Pemasukan: **${currencyFormat.format(income)}**\n"
        "* Total Pengeluaran: **${currencyFormat.format(expense)}**\n"
        "* Sisa Saldo: **${currencyFormat.format(savings)}**\n\n"
        "Kondisi saat ini: $statusEmoji **$statusTxt**\n\n"
        "${savings < 0 ? "Waspada! Pengeluaran Anda melebihi pemasukan bulan ini." : "Pertahankan saldo positif Anda untuk tabungan masa depan!"}";
  }

  String _getAnalysisResponse(double income, double expense, double needs, double wants, double savings) {
    if (income <= 0) return "⚠️ Saya belum bisa menganalisis karena data **pemasukan** Anda masih kosong. Yuk, catat pemasukan dulu agar saya bisa menghitung rasio kesehatan keuangan Anda!";

    double needsPerc = (needs / income) * 100;
    double wantsPerc = (wants / income) * 100;
    double savingsRate = (savings / income) * 100;

    String analysis = "### 🏥 Diagnosa Kesehatan Keuangan\n\n";

    // 50/30/20 Rule Analysis
    analysis += "#### 📊 Alokasi Pengeluaran (Rasio 50/30/20):\n";
    
    if (needsPerc > 50) {
      analysis += "* **Kebutuhan Pokok**: `${needsPerc.toStringAsFixed(1)}%` (⚠️ Melebihi batas ideal 50%)\n";
    } else {
      analysis += "* **Kebutuhan Pokok**: `${needsPerc.toStringAsFixed(1)}%` (✅ Terkontrol)\n";
    }

    if (wantsPerc > 30) {
      analysis += "* **Gaya Hidup (Wants)**: `${wantsPerc.toStringAsFixed(1)}%` (⚠️ Terlalu tinggi! Pertimbangkan untuk memangkas jajan/hiburan)\n";
    } else {
      analysis += "* **Gaya Hidup (Wants)**: `${wantsPerc.toStringAsFixed(1)}%` (✅ Bagus! Anda sangat disiplin)\n";
    }

    // Savings Rate Analysis
    analysis += "\n#### 📈 Rasio Tabungan:\n";
    if (savingsRate < 10) {
      analysis += "Peringkat: **KRITIS**. Anda baru menyisihkan `${savingsRate.toStringAsFixed(1)}%`. Cobalah untuk menekan biaya admin atau gaya hidup agar bisa nabung minimal 10%.\n";
    } else if (savingsRate < 20) {
      analysis += "Peringkat: **CUKUP**. Saldo tersisa `${savingsRate.toStringAsFixed(1)}%`. Sedikit lagi mencapai target ideal 20%!\n";
    } else {
      analysis += "Peringkat: **EXCELLENT!** 🚀 Anda berhasil menyisihkan `${savingsRate.toStringAsFixed(1)}%`. Ini adalah fondasi kekayaan yang sangat kuat.\n";
    }

    return analysis;
  }

  String _getSavingsResponse(double income, double expense, double savings) {
    double monthlyAvg = expense > 0 ? expense : 1000000;
    double safetyTarget = monthlyAvg * 3;
    double runawayMonth = savings / (monthlyAvg > 0 ? monthlyAvg : 1);
    
    String response = "### 🛡️ Analisis Dana Darurat\n\n";
    
    if (savings < safetyTarget) {
      double missing = safetyTarget - savings;
      response += "Status: **BELUM AMAN**\n\n"
          "Anda butuh sekitar **${currencyFormat.format(missing)}** lagi untuk mencapai target dana darurat ideal (**${currencyFormat.format(safetyTarget)}**).\n\n"
          "💡 *Tips: Sisihkan setidaknya 10% pemasukan khusus untuk pos ini sampai target tercapai.*";
    } else {
      response += "Status: **SANGAT AMAN!** 🌟\n\n"
          "Tabungan Anda saat ini bisa menutupi pengeluaran Anda selama **${runawayMonth.toStringAsFixed(1)} bulan** tanpa pemasukan sama sekali. Anda siap menghadapi situasi tak terduga!";
    }
    
    return response;
  }

  String _getBillsResponse(List<Bill> bills, double savings) {
    if (bills.isEmpty) return "### 🎫 Info Tagihan\n\nSejauh ini tidak ada tagihan terdaftar. Hidup bebas hutang adalah kebahagiaan yang hakiki! 🕊️";
    
    double totalBills = bills.fold(0, (sum, b) => sum + b.amount);
    
    String response = "### 🎫 Info Tagihan\n\n"
        "Anda memiliki **${bills.length} item** tagihan bulan ini dengan total pengeluaran **${currencyFormat.format(totalBills)}**.\n\n";
    
    if (savings < totalBills) {
      double gap = totalBills - savings;
      response += "⚠️ **WASPADA!** Saldo Anda saat ini kurang **${currencyFormat.format(gap)}** untuk melunasi semua tagihan. Cari tambahan pemasukan segera!";
    } else {
      response += "✅ **AMAN.** Sisa saldo Anda cukup untuk melunasi seluruh tagihan. Jangan lupa bayar sebelum jatuh tempo ya!";
    }
    
    return response;
  }

  /// Extracts amount and suggests category from raw OCR text
  Map<String, dynamic> extractReceiptData(String rawText) {
    final cleanText = rawText.toLowerCase();
    
    // 1. Extract Amounts using Regex
    // Look for patterns like "10.000", "50,000", "Rp 15000"
    final amountRegex = RegExp(r'(?:\d{1,3}(?:\.\d{3})+|\d{4,})');
    final matches = amountRegex.allMatches(rawText.replaceAll(',', ''));
    
    List<double> amounts = [];
    for (var match in matches) {
      final val = double.tryParse(match.group(0) ?? '0');
      if (val != null && val > 100) { // Filter out tiny numbers (likely dates or quantities)
        amounts.add(val);
      }
    }

    // Heuristic: The largest amount is usually the Total
    double totalAmount = amounts.isNotEmpty ? amounts.reduce((a, b) => a > b ? a : b) : 0;

    // 2. Suggest Category based on keywords
    String category = 'Lainnya';
    if (_containsAny(cleanText, ['makan', 'resto', 'cafe', 'kopi', 'bakery', 'warung', 'food', 'drink', 'mart', 'starbucks', 'kfc', 'mcd'])) {
      category = 'Makanan';
    } else if (_containsAny(cleanText, ['beli', 'shop', 'store', 'indomaret', 'alfamart', 'supermarket', 'mall', 'transmart', 'tokopedia', 'shopee'])) {
      category = 'Belanja';
    } else if (_containsAny(cleanText, ['grab', 'gojek', 'uber', 'taxi', 'bensin', 'shell', 'pertamina', 'parking', 'parkir', 'tol', 'travel'])) {
      category = 'Transportasi';
    } else if (_containsAny(cleanText, ['nonton', 'cinema', 'xxi', 'cgv', 'game', 'spotify', 'netflix', 'hobby', 'hobi', 'wisata'])) {
      category = 'Hiburan';
    } else if (_containsAny(cleanText, ['apotek', 'obat', 'rs ', 'rumah sakit', 'klinik', 'doctor', 'dokter', 'sehat', 'health'])) {
      category = 'Kesehatan';
    }

    // 3. Extract Title (First non-numeric line or a known merchant)
    String title = 'Transaksi Scan';
    final lines = rawText.split('\n');
    for (var line in lines) {
      if (line.trim().length > 3 && !RegExp(r'\d').hasMatch(line)) {
        title = line.trim();
        break;
      }
    }

    return {
      'amount': totalAmount,
      'category': category,
      'title': title,
    };
  }
}
