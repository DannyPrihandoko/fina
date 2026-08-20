import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/bill.dart';
import '../models/budget.dart';
import '../models/wallet.dart';

enum AIIntent {
  greeting,
  status,
  analysis,
  savings,
  bills,
  budget,
  comparison,
  invest,
  rekap,
  help,
  inflation,
  unknown
}

class LocalAIEngine {
  // Singleton pattern
  LocalAIEngine._internal();
  static final LocalAIEngine _instance = LocalAIEngine._internal();
  factory LocalAIEngine() => _instance;

  final currencyFormat = NumberFormat.currency(symbol: 'Rp', decimalDigits: 0);

  /// Analyzes the user's query and returns a structured response.
  String processQuery({
    required String query,
    required List<Transaction> transactions,
    required List<Bill> bills,
    List<Budget> budgets = const [],
    List<Wallet> wallets = const [],
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
    final now = DateTime.now();
    double thisMonthExpense = 0;

    for (var tx in transactions) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        expense += tx.amount;
        if (tx.date.year == now.year && tx.date.month == now.month) {
          thisMonthExpense += tx.amount;
        }
        final cat = tx.category.toLowerCase();
        if (['makanan', 'transportasi', 'kesehatan', 'cicilan', 'tagihan', 'listrik', 'air', 'internet', 'sewa', 'asuransi'].contains(cat)) {
          needs += tx.amount;
        } else {
          // 'hiburan', 'belanja', 'hobi', 'jajan', 'nonton', dan kategori tak dikenal (mis. 'Lainnya')
          // dianggap discretionary (wants) — lebih aman daripada di-drop diam-diam dari perhitungan,
          // dan tidak menutupi overspending sebagai "kebutuhan" pada skor kesehatan finansial.
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
        response += _getSavingsResponse(income, thisMonthExpense, savings);
        break;
      case AIIntent.bills:
        response += _getBillsResponse(bills, savings);
        break;
      case AIIntent.budget:
        response += _getBudgetResponse(transactions, budgets);
        break;
      case AIIntent.comparison:
        response += _getComparisonResponse(transactions);
        break;
      case AIIntent.invest:
        response += _getInvestResponse(savings);
        break;
      case AIIntent.rekap:
        response += _getRekapResponse(transactions);
        break;
      case AIIntent.help:
        response += _getHelpResponse();
        break;
      case AIIntent.inflation:
        response += _getInflationResponse(transactions, savings, normalizedQuery);
        break;
      default:
        response += _getUnknownResponse();
    }

    return response;
  }

  String _normalize(String text) {
    return text.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '');
  }

  _IntentResult _detectIntentWithSuggestion(String query) {
    // Definitive keywords for each intent (Formal)
    final Map<AIIntent, List<String>> keywordMap = {
      AIIntent.greeting: ['halo', 'hallo', 'hai', 'pagi', 'siang', 'malam', 'assalamualaikum', 'ping', 'pun'],
      AIIntent.status: ['saldo', 'sisa uang', 'tabungan', 'kas', 'dompet', 'uang', 'balance', 'duit', 'cek sisa', 'berapa sisa'],
      AIIntent.analysis: ['analisis', 'kesehatan keuangan', 'kondisi', 'review', 'evaluasi', 'pengeluaran', 'boros', 'keuangan gue', 'atur uang', 'biar kaya', 'sehat ga'],
      AIIntent.savings: ['dana darurat', 'simpanan', 'cadangan', 'safety net', 'hemat', 'darurat'],
      AIIntent.bills: ['tagihan', 'pembayaran', 'cicilan', 'bayaran', 'hutang', 'bill', 'bayar apa'],
      AIIntent.budget: ['anggaran', 'budget', 'limit', 'batas', 'sisa kuota', 'kuota'],
      AIIntent.comparison: ['bandingkan', 'bulan lalu', 'vs', 'perbandingan', 'progres', 'kemajuan', 'dibanding'],
      AIIntent.invest: ['investasi', 'invest', 'saham', 'reksadana', 'emas', 'kembangkan uang', 'saran uang', 'kripto', 'crypto'],
      AIIntent.rekap: ['rekap', 'detail', 'kategori', 'paling banyak', 'habis buat apa', 'rincian', 'habis berapa'],
      AIIntent.help: ['bantuan', 'fitur', 'bisa apa', 'tolong', 'panduan', 'help', 'tanya'],
      AIIntent.inflation: ['inflasi', 'uang aman', 'bertahan', 'biaya hidup', 'kedepan', 'masa depan', 'pensiun', 'runway', 'tahun'],
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
    String greeting = "Halo! Aku asisten **fina**.";
    if (query.contains('pagi')) greeting = "Selamat pagi! ☀️";
    if (query.contains('siang')) greeting = "Selamat siang! 👋";
    if (query.contains('malam')) greeting = "Selamat malam! 🌙";
    
    return "$greeting Aku siap bantuin kamu kelola dan analisis keuangan biar makin sehat hari ini. Apa yang mau kita bahas? 😊";
  }

  String _getStatusResponse(double income, double expense, double savings) {
    String statusTxt = savings >= 0 ? "Surplus (Positif) ✅" : "Defisit (Negatif) ⚠️";
    int score = _calculateHealthScore(income, expense, 0, 0, savings);
    
    return "### 💰 Ringkasan Saldo & Arus Kas\n\n"
        "* Uang Masuk: **${currencyFormat.format(income)}**\n"
        "* Uang Keluar: **${currencyFormat.format(expense)}**\n"
        "* Sisa Saldo: **${currencyFormat.format(savings)}**\n\n"
        "Kondisi kamu saat ini: **$statusTxt**\n"
        "Skor Kesehatan Keuangan: `$score/100`\n\n"
        "${savings < 0 
            ? "Waduh, saldo kamu lagi minus nih. Yuk, cek lagi pengeluaran yang nggak penting biar arus kas kamu balik aman! 🙏" 
            : "Saldo aman! Sisa surplus ini bagus banget kalau kamu tabung atau buat nambah dana darurat. Mantap! 🚀"}";
  }

  String _getAnalysisResponse(double income, double expense, double needs, double wants, double savings) {
    if (income <= 0) return "⚠️ Data pemasukan kamu masih kosong nih. Yuk, catat dulu biar aku bisa kasih analisis kesehatan keuangan yang akurat buat kamu!";

    double needsPerc = (needs / income) * 100;
    double wantsPerc = (wants / income) * 100;
    double savingsRate = (savings / income) * 100;
    int score = _calculateHealthScore(income, expense, needs, wants, savings);

    String response = "### 🏥 Analisis Strategi Keuangan (50/30/20)\n\n"
        "Berdasarkan hitung-hitunganku, skor kesehatan keuangan kamu itu **$score/100**.\n\n"
        "#### 📊 Alokasi Kamu saat ini:\n";
    
    response += "* **Kebutuhan (Needs)**: `${needsPerc.toStringAsFixed(1)}%` ${needsPerc > 50 ? "(⚠️ Kebesaran nih)" : "(✅ Mantap!)"}\n";
    response += "* **Gaya Hidup (Wants)**: `${wantsPerc.toStringAsFixed(1)}%` ${wantsPerc > 30 ? "(⚠️ Kurangi dikit yuk)" : "(✅ Terkontrol)"}\n";
    response += "* **Tabungan (Savings)**: `${savingsRate.toStringAsFixed(1)}%` ${savingsRate < 20 ? "(⚠️ Yuk, tabung lebih banyak)" : "(🚀 Luar Biasa!)"}\n\n";

    if (score < 50) {
      response += "#### 💡 Saran dari Aku:\n"
          "Keuangan kamu lagi butuh perhatian ekstra nih. Fokus bayar tagihan dulu dan tahan diri buat jajan-jajan yang nggak perlu ya. Semangat! 💪";
    } else {
      response += "#### 💡 Saran dari Aku:\n"
          "Struktur keuangan kamu udah oke banget! Sekarang fokus buat menumpuk dana darurat dan mulai lirik-lirik investasi yang aman ya. Kamu hebat! ✨";
    }

    return response;
  }

  String _getSavingsResponse(double income, double monthlyExpense, double savings) {
    // monthlyExpense harus sudah discope ke bulan berjalan oleh caller —
    // jangan pernah pakai total pengeluaran seumur pakai (lifetime) di sini,
    // karena akan melipatgandakan target dana darurat untuk user dengan riwayat panjang.
    double monthlyAvg = monthlyExpense > 0 ? monthlyExpense : 1000000;
    double target = monthlyAvg * 3;
    
    String response = "### 🛡️ Evaluasi Dana Darurat\n\n";
    
    if (savings < target) {
      double diff = target - savings;
      response += "Status: **Perlu Perhatian ⚠️**\n"
          "Idealnya, kamu punya dana cadangan minimal **${currencyFormat.format(target)}** (buat 3 bulan hidup aman).\n\n"
          "Kurangnya tinggal: **${currencyFormat.format(diff)}** lagi.\n\n"
          "Saran: Coba sisihkan 10% dari gaji kamu tiap bulan khusus buat pos ini ya, biar hati makin tenang! 😊";
    } else {
      response += "Status: **Sangat Aman 🌟**\n"
          "Dana darurat kamu udah cukup banget buat cover kebutuhan hidup kamu. Ini langkah besar menuju bebas finansial. Bangga banget sama kamu! 👏";
    }
    
    return response;
  }

  String _getBillsResponse(List<Bill> bills, double savings) {
    if (bills.isEmpty) return "Kamu belum punya tagihan terdaftar nih. Kalau ada tagihan rutin, yuk tambahkan biar aku bisa bantu ingatkan! 🔔";

    final now = DateTime.now();
    final unpaid = bills.where((b) => !b.isPaid).toList();
    final overdue = unpaid.where((b) => b.dueDate.isBefore(DateTime(now.year, now.month, now.day))).toList();
    final dueSoon = unpaid.where((b) {
      final diff = b.dueDate.difference(DateTime(now.year, now.month, now.day)).inDays;
      return diff >= 0 && diff <= 7;
    }).toList();

    double totalUnpaid = unpaid.fold(0.0, (sum, b) => sum + b.amount);

    String response = "### 📋 Ringkasan Tagihan Kamu\n\n";
    response += "* Total Belum Dibayar: **${currencyFormat.format(totalUnpaid)}** (${unpaid.length} tagihan)\n";

    if (overdue.isNotEmpty) {
      response += "\n#### ⚠️ Terlambat Bayar:\n";
      for (var b in overdue) {
        response += "* **${b.title}**: ${currencyFormat.format(b.amount)}\n";
      }
    }

    if (dueSoon.isNotEmpty) {
      response += "\n#### ⏰ Segera Jatuh Tempo:\n";
      for (var b in dueSoon) {
        final diff = b.dueDate.difference(DateTime(now.year, now.month, now.day)).inDays;
        response += "* **${b.title}**: ${currencyFormat.format(b.amount)} (${diff == 0 ? 'Hari ini!' : '$diff hari lagi'})\n";
      }
    }

    response += "\n";
    if (overdue.isNotEmpty) {
      response += "Ada tagihan yang **sudah lewat jatuh tempo** nih! Segera lunasi ya biar nggak kena denda. 🙏";
    } else if (totalUnpaid > savings && savings >= 0) {
      response += "Hmm, total tagihan kamu lebih besar dari sisa saldo. Prioritaskan yang paling mendesak ya! 💪";
    } else {
      response += "Bagus, semua tagihan masih terkontrol! Pastikan bayar sebelum jatuh tempo ya. ✅";
    }

    return response;
  }

  String _getBudgetResponse(List<Transaction> transactions, List<Budget> budgets) {
    if (budgets.isEmpty) return "Sepertinya kamu belum membuat **Anggaran** nih. Coba deh buat di halaman laporan agar aku bisa pantau pengeluaranmu supaya gak bablas! 💸";
    
    final now = DateTime.now();
    final thisMonthTx = transactions.where((tx) => 
      tx.type == TransactionType.expense && 
      tx.date.year == now.year && 
      tx.date.month == now.month
    ).toList();

    String response = "### 📊 Pantauan Anggaran Kamu\n\n";
    bool anyExceeded = false;

    for (var b in budgets) {
      final spent = thisMonthTx.where((tx) => tx.category == b.category).fold(0.0, (sum, tx) => sum + tx.amount);
      final percent = b.limitAmount > 0 ? (spent / b.limitAmount) * 100 : 0.0;

      response += "* **${b.category}**: `${percent.toStringAsFixed(0)}%` terpakai (${currencyFormat.format(spent)})\n";
      if (b.limitAmount > 0 && spent > b.limitAmount) anyExceeded = true;
    }

    response += "\n";
    if (anyExceeded) {
      response += "Waduh, ada anggaran yang **melewati batas** nih. Yuk, lebih ngerem lagi pengeluarannya di kategori tersebut ya! 🙏";
    } else {
      response += "Keren! Semua pengeluaran kamu masih **di bawah limit**. Pertahankan disiplinnya ya, kamu hebat! 🚀";
    }

    return response;
  }

  String _getComparisonResponse(List<Transaction> transactions) {
    final now = DateTime.now();
    final thisMonth = transactions.where((tx) => tx.type == TransactionType.expense && tx.date.year == now.year && tx.date.month == now.month).fold(0.0, (sum, tx) => sum + tx.amount);
    
    final lastMonthDate = DateTime(now.year, now.month - 1, 1);
    final lastMonth = transactions.where((tx) => tx.type == TransactionType.expense && tx.date.year == lastMonthDate.year && tx.date.month == lastMonthDate.month).fold(0.0, (sum, tx) => sum + tx.amount);

    if (lastMonth == 0) return "Aku belum punya cukup data bulan lalu untuk dibandingkan nih. Yuk, rutin catat terus transaksimu! ✨";

    double diff = thisMonth - lastMonth;
    double percent = (diff.abs() / lastMonth) * 100;
    bool isBetter = diff < 0;

    return "### 🔄 Perbandingan dengan Bulan Lalu\n\n"
        "* Bulan Lalu: **${currencyFormat.format(lastMonth)}**\n"
        "* Bulan Ini: **${currencyFormat.format(thisMonth)}**\n\n"
        "Pengeluaranmu **${isBetter ? 'turun' : 'naik'} ${percent.toStringAsFixed(1)}%**. "
        "${isBetter ? 'Wah, kamu makin jago hemat ya! Terus tingkatkan performanya. 👏' : 'Jangan berkecil hati, mungkin ada keperluan mendesak ya? Yuk, pelan-pelan kita atur lagi biar lebih stabil. 💪'}";
  }

  String _getInvestResponse(double savings) {
    if (savings <= 0) return "Untuk saat ini, fokus kita adalah **menstabilkan arus kas** dulu ya agar saldo kembali positif. Setelah itu, baru kita bicara investasi! Semangat! ✨";
    
    String response = "### 📈 Saran Alokasi Surplus\n\n"
        "Wah, ada saldo sisa **${currencyFormat.format(savings)}** nih! Ini saranku:\n\n";

    if (savings < 1000000) {
      response += "* **Tabungan Berjangka**: Amankan dulu di tabungan yang bunganya kompetitif.\n"
          "* **Emas Digital**: Bisa mulai cicil emas dari nominal kecil lewat aplikasi terpercaya.";
    } else {
      response += "* **Reksadana Pasar Uang**: Sangat cocok untuk pemula, risiko rendah dan likuid.\n"
          "* **SBN (Surat Berharga Negara)**: Jika ingin investasi yang dijamin negara dan hasil stabil.";
    }

    response += "\n\n*Catatan: Ini hanya saran ya, pastikan kamu selalu riset dulu sebelum berinvestasi! 😊*";
    return response;
  }

  String _getRekapResponse(List<Transaction> transactions) {
    final now = DateTime.now();
    final expenseTx = transactions.where((tx) => tx.type == TransactionType.expense && tx.date.year == now.year && tx.date.month == now.month).toList();

    if (expenseTx.isEmpty) return "Belum ada data pengeluaran bulan ini yang bisa aku rekap nih. Ayo mulai catat! 📝";

    Map<String, double> categories = {};
    for (var tx in expenseTx) {
      categories[tx.category] = (categories[tx.category] ?? 0) + tx.amount;
    }

    var sorted = categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    String response = "### 🔍 Kategori Terboros Bulan Ini\n\n";
    for (var i = 0; i < (sorted.length > 3 ? 3 : sorted.length); i++) {
      response += "${i+1}. **${sorted[i].key}**: ${currencyFormat.format(sorted[i].value)}\n";
    }

    response += "\nKategori **${sorted[0].key}** paling banyak menyedot dana kamu. Mungkinkah ada yang bisa dikurangi dari sana? 🤔";
    return response;
  }

  String _getUnknownResponse() {
    return "Maaf ya, aku belum paham maksud kamu. 🤖\n\n"
        "Sebagai asisten fina, aku bisa bantu kamu cek **Saldo**, **Analisis 50/30/20**, **Dana Darurat**, **Tagihan**, **Anggaran**, atau **Perbandingan Bulanan**. Ketik salah satu aja ya!";
  }

  String _getHelpResponse() {
    return "### 🤖 Apa Saja yang Bisa Aku Bantu?\n\n"
        "Hai! Aku asisten keuangan pribadimu. Kamu bisa tanya hal-hal ini ke aku:\n\n"
        "* **\"Gimana kondisi uangku?\"** (Analisis Skor Kesehatan)\n"
        "* **\"Cek saldo\"** (Ringkasan Kas)\n"
        "* **\"Dana darurat cukup gak?\"** (Evaluasi Simpanan)\n"
        "* **\"Anggaranku gimana?\"** (Pantau Limit Budget)\n"
        "* **\"Bandingkan dengan bulan lalu\"** (Progres Keuangan)\n"
        "* **\"Top pengeluaranku\"** (Rekap Kategori)\n\n"
        "Yuk, langsung tanya aja! Aku siap dengerin curhatan keuanganmu. 😊";
  }

  String _getInflationResponse(List<Transaction> transactions, double currentSavings, String query) {
    final now = DateTime.now();
    final thisMonthTx = transactions.where((tx) => 
      tx.type == TransactionType.expense && 
      tx.date.year == now.year && 
      tx.date.month == now.month
    ).toList();
    
    double baseMonthlyExpense = thisMonthTx.fold(0.0, (sum, tx) => sum + tx.amount);
    
    if (baseMonthlyExpense <= 0) {
      baseMonthlyExpense = 3000000; // Asumsi default jika belum ada pengeluaran
    }

    final annualInflationRate = 0.05; // Asumsi inflasi 5% per tahun
    
    // Cek apakah user menyebutkan durasi spesifik di prompt (contoh "5 tahun" atau "6 bulan")
    final regex = RegExp(r'(\d+)\s*(bulan|tahun)');
    final match = regex.firstMatch(query);
    
    String response = "### 📈 Proyeksi Inflasi & Uang Aman\n\n";
    response += "Berdasarkan pengeluaran bulan ini (**${currencyFormat.format(baseMonthlyExpense)}/bulan**) dan asumsi inflasi **5% per tahun**:\n\n";

    if (match != null) {
      int amount = int.tryParse(match.group(1)!) ?? 0;
      String unit = match.group(2)!;
      int months = unit == 'tahun' ? amount * 12 : amount;
      
      if (months > 0 && months <= 600) { 
        double requiredMoney = _calculateFutureNeed(baseMonthlyExpense, months, annualInflationRate);
        response += "* Untuk **$amount $unit** ke depan, kamu butuh dana aman sekitar **${currencyFormat.format(requiredMoney)}**.\n\n";
        
        if (currentSavings >= requiredMoney) {
          response += "✅ Wah, sisa saldo kamu (**${currencyFormat.format(currentSavings)}**) saat ini sudah **CUKUP** untuk bertahan selama $amount $unit! Pertahankan!";
        } else {
          response += "⚠️ Saldo kamu saat ini (**${currencyFormat.format(currentSavings)}**) **BELUM CUKUP** untuk bertahan $amount $unit. Kamu masih butuh sekitar **${currencyFormat.format(requiredMoney - currentSavings)}** lagi.";
        }
        return response;
      }
    }

    // Opsi waktu default
    final options = [6, 12, 60, 120]; 
    final labels = ['6 Bulan', '1 Tahun', '5 Tahun', '10 Tahun'];

    response += "Berikut perkiraan total dana aman (runway) yang dibutuhkan untuk beberapa opsi waktu ke depan:\n\n";
    
    for (int i = 0; i < options.length; i++) {
      int months = options[i];
      double requiredMoney = _calculateFutureNeed(baseMonthlyExpense, months, annualInflationRate);
      response += "* **${labels[i]}**: ${currencyFormat.format(requiredMoney)}\n";
    }

    response += "\n*Total di atas sudah memperhitungkan harga barang yang naik tiap tahunnya karena efek inflasi.*";
    
    if (currentSavings > 0) {
      int monthsCanSurvive = 0;
      double tempSavings = currentSavings;
      double currentCost = baseMonthlyExpense;
      
      while (tempSavings >= currentCost && monthsCanSurvive < 1200) { 
        tempSavings -= currentCost;
        monthsCanSurvive++;
        if (monthsCanSurvive % 12 == 0) {
          currentCost *= (1 + annualInflationRate);
        }
      }
      
      int yearsSurvive = monthsCanSurvive ~/ 12;
      int remMonths = monthsCanSurvive % 12;
      String surviveText = yearsSurvive > 0 
          ? "$yearsSurvive tahun${remMonths > 0 ? ' $remMonths bulan' : ''}" 
          : "$monthsCanSurvive bulan";
          
      response += "\n\n💡 **Status Saldomu:**\nDengan sisa saldomu saat ini (**${currencyFormat.format(currentSavings)}**), kamu diperkirakan bisa bertahan selama **$surviveText** ke depan tanpa pemasukan baru.";
    }

    return response;
  }

  double _calculateFutureNeed(double monthlyExpense, int months, double annualInflationRate) {
    double total = 0;
    double currentCost = monthlyExpense;
    
    for (int i = 0; i < months; i++) {
      total += currentCost;
      if ((i + 1) % 12 == 0) { 
        currentCost *= (1 + annualInflationRate);
      }
    }
    return total;
  }

  int _calculateHealthScore(double income, double expense, double needs, double wants, double savings) {
    if (income <= 0) return 0;
    double score = 0;
    
    // 1. Savings Rate (40 points) - Ideal is 20%+
    double sRate = (savings / income) * 100;
    if (sRate >= 20) {
      score += 40;
    } else if (sRate >= 10) {
      score += 20;
    } else if (sRate > 0) {
      score += 5;
    }

    // 2. Budget Discipline (30 points) - Needs <= 50%
    double nRate = (needs / income) * 100;
    if (nRate <= 50) {
      score += 30;
    } else if (nRate <= 60) {
      score += 15;
    }

    // 3. Wants Control (30 points) - Wants <= 30%
    double wRate = (wants / income) * 100;
    if (wRate <= 30) {
      score += 30;
    } else if (wRate <= 40) {
      score += 10;
    }
    
    return score.toInt().clamp(0, 100);
  }

  /// Extracts amount and suggests category from raw OCR text
  Map<String, dynamic> extractReceiptData(String rawText) {
    // 1. Text Normalization
    final cleanText = rawText.toLowerCase();
    final sanitizedText = rawText.replaceAll(',', ''); // Standardize thousands
    
    final amountRegex = RegExp(r'(?:\d{1,3}(?:\.\d{3})+|\d{4,})');
    
    double totalAmount = 0;
    
    // 2. Strategy A: Look for "TOTAL" keywords (Most accurate)
    final totalKeywords = ['total', 'grand total', 'jumlah', 'netto', 'amount', 'bayar', 'tagihan'];
    bool foundViaKeyword = false;

    // Split into lines to search contextually
    final lines = cleanText.split('\n');
    final sanitizedLines = sanitizedText.split('\n');

    for (int i = 0; i < lines.length; i++) {
      if (_containsAny(lines[i], totalKeywords)) {
        // Keyword found on this line, look for amount on this line first
        final match = amountRegex.firstMatch(sanitizedLines[i]);
        if (match != null) {
          totalAmount = double.tryParse(match.group(0)!) ?? 0;
          if (totalAmount > 100) {
            foundViaKeyword = true;
            break;
          }
        }
        
        // If not on this line, check the next line (common in multi-line totals)
        if (i + 1 < sanitizedLines.length) {
          final nextMatch = amountRegex.firstMatch(sanitizedLines[i+1]);
          if (nextMatch != null) {
            totalAmount = double.tryParse(nextMatch.group(0)!) ?? 0;
            if (totalAmount > 100) {
              foundViaKeyword = true;
              break;
            }
          }
        }
      }
    }

    // 3. Strategy B: Fallback to highest number (Best effort)
    if (!foundViaKeyword) {
      final matches = amountRegex.allMatches(sanitizedText);
      List<double> amounts = [];
      for (var match in matches) {
        final val = double.tryParse(match.group(0) ?? '0');
        if (val != null && val > 100 && val < 100000000) { // Safety cap at 100M
          amounts.add(val);
        }
      }
      totalAmount = amounts.isNotEmpty ? amounts.reduce((a, b) => a > b ? a : b) : 0;
    }

    // 4. Category Detection — kata kunci diperluas dengan merchant/vendor umum Indonesia
    // supaya struk (makanan, retail, transportasi, hiburan, kesehatan, tagihan/cicilan)
    // lebih akurat ter-klasifikasi otomatis. Semua kategori output HARUS termasuk dalam
    // AppConstants.defaultCategories, karena form transaksi hanya punya chip untuk daftar itu.
    String category = 'Lainnya';
    if (_containsAny(cleanText, [
      // 'mart' sengaja TIDAK dimasukkan di sini — substring generic itu akan menutupi
      // 'indomaret'/'alfamart'/'supermarket'/'transmart'/'hypermart' di kategori Belanja
      // di bawah karena Makanan dicek lebih dulu (if/else-if berurutan).
      'makan', 'resto', 'cafe', 'kopi', 'bakery', 'warung', 'food', 'drink',
      'starbucks', 'kfc', 'mcd', 'mcdonald', 'padang', 'sate', 'bakso', 'ayam geprek',
      'richeese', 'pizza', 'dimsum', 'boba', 'chatime', 'kopi kenangan', 'janji jiwa',
      'burger king', 'a&w', 'hokben', 'solaria', 'es teh', 'gofood', 'grabfood', 'shopeefood',
    ])) {
      category = 'Makanan';
    } else if (_containsAny(cleanText, [
      'beli', 'shop', 'store', 'indomaret', 'alfamart', 'supermarket', 'mall', 'transmart',
      'tokopedia', 'shopee', 'giant', 'hypermart', 'carrefour', 'lazada', 'blibli', 'bukalapak',
      'zalora', 'uniqlo', 'matahari', 'ace hardware', 'informa', 'ikea',
    ])) {
      category = 'Belanja';
    } else if (_containsAny(cleanText, [
      'grab', 'gojek', 'uber', 'taxi', 'bensin', 'shell', 'pertamina', 'parking', 'parkir',
      'tol', 'travel', 'maxim', 'bluebird', 'transjakarta', 'krl', 'commuterline', 'mrt', 'lrt',
      'tiket.com', 'traveloka', 'pesawat', 'kereta', 'damri',
    ])) {
      category = 'Transportasi';
    } else if (_containsAny(cleanText, [
      'nonton', 'cinema', 'xxi', 'cgv', 'game', 'spotify', 'netflix', 'hobby', 'hobi', 'wisata',
      'timezone', 'disney', 'viu', 'vidio', 'joox', 'youtube premium', 'concert', 'konser', 'tiket event',
    ])) {
      category = 'Hiburan';
    } else if (_containsAny(cleanText, [
      'apotek', 'obat', 'rs ', 'rumah sakit', 'klinik', 'doctor', 'dokter', 'sehat', 'health',
      'kimia farma', 'guardian', 'watsons', 'k24', 'century', 'puskesmas', 'vaksin',
      'dokter gigi', 'fisioterapi', 'bpjs kesehatan',
    ])) {
      category = 'Kesehatan';
    } else if (_containsAny(cleanText, [
      // Tagihan/cicilan/utilitas — dipetakan ke 'Cicilan' (bukan string baru seperti 'Listrik')
      // supaya konsisten dengan chip kategori yang tersedia di form transaksi.
      'listrik', 'pln', 'pdam', 'wifi', 'indihome', 'internet', 'first media', 'biznet',
      'telkom', 'cicilan', 'kredit', 'angsuran', 'pinjaman', 'tagihan', 'pajak', 'pbb',
      'asuransi', 'premi', 'bpjs ketenagakerjaan', 'sewa', 'kontrakan',
    ])) {
      category = 'Cicilan';
    }

    // 5. Title Detection (Look for store name usually at the top)
    String title = 'Transaksi Scan';
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.length > 3 && 
          !RegExp(r'\d').hasMatch(trimmed) && 
          !_containsAny(trimmed, totalKeywords)) {
        title = trimmed.toUpperCase();
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

  /// Detects unusual spending by comparing current month to previous month.
  /// Returns a list of alert messages if thresholds are exceeded.
  List<String> detectUnusualSpending({
    required List<Transaction> transactions,
    required Transaction newTransaction,
  }) {
    final List<String> alerts = [];
    final now = DateTime.now();
    
    // 1. Calculate Previous Month Total
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59); // Akhir hari terakhir bulan lalu
    
    final lastMonthTxs = transactions.where((tx) => 
      tx.type == TransactionType.expense && 
      tx.date.isAfter(lastMonthStart.subtract(const Duration(seconds: 1))) && 
      tx.date.isBefore(lastMonthEnd.add(const Duration(seconds: 1)))
    ).toList();
    
    final lastMonthTotal = lastMonthTxs.fold(0.0, (sum, tx) => sum + tx.amount);
    final lastMonthCategoryTotal = lastMonthTxs
        .where((tx) => tx.category == newTransaction.category)
        .fold(0.0, (sum, tx) => sum + tx.amount);

    // 2. Calculate Current Month Total (including the new transaction)
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonthTxs = transactions.where((tx) => 
      tx.type == TransactionType.expense && 
      tx.date.isAfter(thisMonthStart.subtract(const Duration(seconds: 1)))
    ).toList();
    
    final thisMonthTotalBefore = thisMonthTxs.fold(0.0, (sum, tx) => sum + tx.amount);
    final thisMonthTotalAfter = thisMonthTotalBefore + newTransaction.amount;
    
    final thisMonthCategoryTotalBefore = thisMonthTxs
        .where((tx) => tx.category == newTransaction.category)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final thisMonthCategoryTotalAfter = thisMonthCategoryTotalBefore + newTransaction.amount;

    // 3. Comparisons
    // A. Total monthly spending check
    if (thisMonthTotalBefore <= lastMonthTotal && thisMonthTotalAfter > lastMonthTotal && lastMonthTotal > 0) {
      alerts.add("Total pengeluaran bulan ini (${currencyFormat.format(thisMonthTotalAfter)}) sudah melebihi total bulan lalu (${currencyFormat.format(lastMonthTotal)}).");
    }

    // B. Category-specific check
    if (thisMonthCategoryTotalBefore <= lastMonthCategoryTotal && thisMonthCategoryTotalAfter > lastMonthCategoryTotal && lastMonthCategoryTotal > 0) {
      alerts.add("Pengeluaran kategori ${newTransaction.category} bulan ini (${currencyFormat.format(thisMonthCategoryTotalAfter)}) sudah melebihi bulan lalu (${currencyFormat.format(lastMonthCategoryTotal)}).");
    }

    return alerts;
  }
}

class _IntentResult {
  final AIIntent intent;
  final String? suggestion;

  _IntentResult(this.intent, {this.suggestion});
}
