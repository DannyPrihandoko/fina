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
    final normalizedQuery = _normalize(query);
    
    // 1. Detect Intent with fuzzy matching
    var intentMatch = _detectIntentWithSuggestion(normalizedQuery);
    final intent = intentMatch.intent;
    final suggestion = intentMatch.suggestion;

    // 2. Data Calculation
    double income = 0;
    double expense = 0;
    double needs = 0;
    double wants = 0;
    
    for (var tx in transactions) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
        final cat = tx.category.toLowerCase();
        if (['makanan', 'transportasi', 'kesehatan', 'cicilan', 'tagihan', 'listrik', 'air'].contains(cat)) {
          needs += tx.amount;
        } else if (['hiburan', 'belanja', 'hobi', 'jajan', 'nonton'].contains(cat)) {
          wants += tx.amount;
        }
      }
    }
    double savings = income - expense;

    // 3. Generate Response
    String response = "";
    
    // Add suggestion if found
    if (suggestion != null) {
      response += "Apakah yang Anda maksud adalah **$suggestion**?\n\n---\n\n";
    }

    switch (intent) {
      case AIIntent.greeting:
        response += _getGreetingResponse(normalizedQuery);
        break;
      case AIIntent.status:
        response += _getStatusResponse(income, expense, savings);
        break;
      case AIIntent.analysis:
        response += _getAnalysisResponse(income, expense, needs, wants, savings);
        break;
      case AIIntent.savings:
        response += _getSavingsResponse(income, expense, savings);
        break;
      case AIIntent.bills:
        response += _getBillsResponse(bills, savings);
        break;
      case AIIntent.help:
        response += _getHelpResponse();
        break;
      default:
        response += "Maaf, saya belum memahami instruksi tersebut. 🤖\n\n"
            "Sebagai asisten keuangan, saya bisa membantu Anda menganalisis **Saldo**, **Kesehatan Keuangan**, **Dana Darurat**, atau **Tagihan**. Silakan ketik salah satu topik tersebut.";
    }

    return response;
  }

  String _normalize(String text) {
    return text.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '');
  }

  _IntentResult _detectIntentWithSuggestion(String query) {
    // Definitive keywords for each intent (Formal)
    final Map<AIIntent, List<String>> keywordMap = {
      AIIntent.greeting: ['halo', 'hallo', 'hai', 'pagi', 'siang', 'malam', 'assalamualaikum'],
      AIIntent.status: ['saldo', 'sisa uang', 'tabungan', 'kas', 'dompet', 'uang'],
      AIIntent.analysis: ['analisis', 'kesehatan keuangan', 'kondisi', 'review', 'evaluasi', 'pengeluaran'],
      AIIntent.savings: ['dana darurat', 'simpanan', 'cadangan', 'safety net', 'hemat'],
      AIIntent.bills: ['tagihan', 'pembayaran', 'cicilan', 'bayaran', 'hutang'],
      AIIntent.help: ['bantuan', 'fitur', 'bisa apa', 'tolong', 'panduan'],
    };

    // 1. Direct match check
    for (var entry in keywordMap.entries) {
      if (entry.value.any((k) => query.contains(k))) {
        return _IntentResult(entry.key);
      }
    }

    // 2. Fuzzy match check (Only if query is short / single word mostly)
    final words = query.split(' ');
    for (var word in words) {
      if (word.length < 3) continue;
      
      String? closestKeyword;
      int minDistance = 99;

      for (var entry in keywordMap.entries) {
        for (var k in entry.value) {
          // Only compare words of similar length
          if ((k.length - word.length).abs() <= 2) {
            int dist = _levenshtein(word, k);
            if (dist < minDistance && dist <= 2) { // Allow 1-2 character difference
              minDistance = dist;
              closestKeyword = k;
              if (dist == 0) return _IntentResult(entry.key); // Should not happen due to step 1
            }
          }
        }
      }

      if (closestKeyword != null && minDistance <= 2) {
        // Find which intent this keyword belongs to
        AIIntent targetIntent = AIIntent.unknown;
        for (var entry in keywordMap.entries) {
          if (entry.value.contains(closestKeyword)) {
            targetIntent = entry.key;
            break;
          }
        }
        return _IntentResult(targetIntent, suggestion: closestKeyword);
      }
    }

    return _IntentResult(AIIntent.unknown);
  }

  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    int n = s.length;
    int m = t.length;
    List<int> v0 = List<int>.generate(m + 1, (i) => i);
    List<int> v1 = List<int>.filled(m + 1, 0);

    for (int i = 0; i < n; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < m; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j <= m; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[m];
  }

  String _getGreetingResponse(String query) {
    String greeting = "Halo! Saya asisten **fina**.";
    if (query.contains('pagi')) greeting = "Selamat pagi! ☀️";
    if (query.contains('siang')) greeting = "Selamat siang! 👋";
    if (query.contains('malam')) greeting = "Selamat malam! 🌙";
    
    return "$greeting Saya siap membantu Anda mengelola dan menganalisis keuangan dengan bijak hari ini. Apa yang ingin Anda diskusikan?";
  }

  String _getStatusResponse(double income, double expense, double savings) {
    String statusTxt = savings >= 0 ? "Surplus (Positif)" : "Defisit (Negatif)";
    int score = _calculateHealthScore(income, expense, 0, 0, savings);
    
    return "### 💰 Ringkasan Saldo & Arus Kas\n\n"
        "* Total Pemasukan: **${currencyFormat.format(income)}**\n"
        "* Total Pengeluaran: **${currencyFormat.format(expense)}**\n"
        "* Sisa Saldo: **${currencyFormat.format(savings)}**\n\n"
        "Kondisi saat ini: **$statusTxt**\n"
        "Skor Kesehatan: `${score}/100`\n\n"
        "${savings < 0 
            ? "Saya menyarankan untuk segera meninjau kembali pengeluaran non-prioritas Anda guna menjaga keseimbangan arus kas." 
            : "Pertahankan surplus ini. Sangat baik untuk dialokasikan ke dana darurat atau investasi jangka panjang."}";
  }

  String _getAnalysisResponse(double income, double expense, double needs, double wants, double savings) {
    if (income <= 0) return "⚠️ Data pemasukan Anda saat ini masih kosong. Silakan catat pemasukan terlebih dahulu agar saya dapat memberikan analisis kesehatan keuangan yang akurat.";

    double needsPerc = (needs / income) * 100;
    double wantsPerc = (wants / income) * 100;
    double savingsRate = (savings / income) * 100;
    int score = _calculateHealthScore(income, expense, needs, wants, savings);

    String response = "### 🏥 Analisis Strategi Keuangan (50/30/20)\n\n"
        "Berdasarkan data Anda, skor kesehatan keuangan Anda adalah **$score/100**.\n\n"
        "#### 📊 Alokasi Saat Ini:\n";
    
    response += "* **Kebutuhan (Needs)**: `${needsPerc.toStringAsFixed(1)}%` ${needsPerc > 50 ? "(⚠️ Tinggi)" : "(✅ Ideal)"}\n";
    response += "* **Gaya Hidup (Wants)**: `${wantsPerc.toStringAsFixed(1)}%` ${wantsPerc > 30 ? "(⚠️ Perlu dikurangi)" : "(✅ Terkontrol)"}\n";
    response += "* **Tabungan (Savings)**: `${savingsRate.toStringAsFixed(1)}%` ${savingsRate < 20 ? "(⚠️ Perlu ditingkatkan)" : "(🚀 Luar Biasa)"}\n\n";

    if (score < 50) {
      response += "#### 💡 Saran Pakar:\n"
          "Kondisi keuangan Anda membutuhkan perhatian khusus. Prioritaskan pelunasan tagihan dan kurangi pengeluaran gaya hidup untuk membangun kembali cadangan kas Anda.";
    } else {
      response += "#### 💡 Saran Pakar:\n"
          "Struktur keuangan Anda sudah di jalur yang benar. Fokus selanjutnya adalah memaksimalkan dana darurat dan mulai mempertimbangkan instrumen investasi yang aman.";
    }

    return response;
  }

  String _getSavingsResponse(double income, double expense, double savings) {
    double monthlyAvg = expense > 0 ? expense : 1000000;
    double target = monthlyAvg * 3;
    
    String response = "### 🛡️ Evaluasi Dana Darurat\n\n";
    
    if (savings < target) {
      double diff = target - savings;
      response += "Status: **Perlu Perhatian**\n"
          "Idealnya, Anda memiliki dana cadangan sebesar **${currencyFormat.format(target)}** (3x pengeluaran bulanan).\n\n"
          "Kekurangan saat ini: **${currencyFormat.format(diff)}**.\n\n"
          "Saran: Alokasikan minimal 10% pemasukan secara disiplin setiap bulan khusus untuk pos ini.";
    } else {
      response += "Status: **Sangat Aman 🌟**\n"
          "Dana darurat Anda saat ini mencukupi untuk memenuhi kebutuhan hidup Anda secara mandiri. Ini adalah langkah besar menuju kebebasan finansial.";
    }
    
    return response;
  }

  String _getBillsResponse(List<Bill> bills, double savings) {
    if (bills.isEmpty) return "### 🎫 Status Tagihan\n\nAnda tidak memiliki daftar tagihan rutin saat ini. Ini sangat bagus untuk fleksibilitas keuangan Anda.";
    
    double total = bills.fold(0, (sum, b) => sum + b.amount);
    
    String response = "### 🎫 Analisis Kewajiban\n\n"
        "Terdapat **${bills.length} tagihan** dengan total **${currencyFormat.format(total)}**.\n\n";
    
    if (savings < total) {
      response += "⚠️ **Peringatan**: Saldo Anda saat ini tidak cukup untuk menutupi seluruh tagihan. Saya sarankan untuk mencari tambahan pendapatan atau menunda pengeluaran tidak mendesak.";
    } else {
      response += "✅ **Aman**: Saldo Anda mencukupi untuk melunasi kewajiban bulan ini. Pastikan pembayaran dilakukan tepat waktu untuk menghindari denda.";
    }
    
    return response;
  }

  String _getHelpResponse() {
    return "### 🤖 Panduan Asisten Keuangan\n\n"
        "Saya dapat membantu Anda dengan berbagai analisis finansial. Gunakan kata kunci berikut:\n\n"
        "* **Saldo**: Untuk melihat ringkasan uang masuk dan keluar.\n"
        "* **Analisis**: Untuk melihat diagnosa kesehatan keuangan (50/30/20).\n"
        "* **Tabungan**: Untuk mengevaluasi kesiapan dana darurat Anda.\n"
        "* **Tagihan**: Untuk mengecek daftar dan kemampuan bayar tagihan.\n\n"
        "Gunakan bahasa yang formal agar saya dapat memahami anda dengan lebih presisi.";
  }

  int _calculateHealthScore(double income, double expense, double needs, double wants, double savings) {
    if (income <= 0) return 0;
    double score = 0;
    
    // 1. Savings Rate (40 points) - Ideal is 20%+
    double sRate = (savings / income) * 100;
    if (sRate >= 20) score += 40;
    else if (sRate >= 10) score += 20;
    else if (sRate > 0) score += 5;

    // 2. Budget Discipline (30 points) - Needs <= 50%
    double nRate = (needs / income) * 100;
    if (nRate <= 50) score += 30;
    else if (nRate <= 60) score += 15;

    // 3. Wants Control (30 points) - Wants <= 30%
    double wRate = (wants / income) * 100;
    if (wRate <= 30) score += 30;
    else if (wRate <= 40) score += 10;
    
    return score.toInt().clamp(0, 100);
  }

  /// Extracts amount and suggests category from raw OCR text
  Map<String, dynamic> extractReceiptData(String rawText) {
    final cleanText = rawText.toLowerCase();
    
    final amountRegex = RegExp(r'(?:\d{1,3}(?:\.\d{3})+|\d{4,})');
    final matches = amountRegex.allMatches(rawText.replaceAll(',', ''));
    
    List<double> amounts = [];
    for (var match in matches) {
      final val = double.tryParse(match.group(0) ?? '0');
      if (val != null && val > 100) {
        amounts.add(val);
      }
    }

    double totalAmount = amounts.isNotEmpty ? amounts.reduce((a, b) => a > b ? a : b) : 0;

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

  bool _containsAny(String query, List<String> keywords) {
    return keywords.any((k) => query.contains(k));
  }
}

class _IntentResult {
  final AIIntent intent;
  final String? suggestion;

  _IntentResult(this.intent, {this.suggestion});
}
