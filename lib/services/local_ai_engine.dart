import 'package:intl/intl.dart';

/// LocalAIEngine
/// 
/// A dedicated service class that uses hardcoded financial rules to analyze 
/// local database data without requiring an internet connection.
class LocalAIEngine {
  
  /// Rule A (50/30/20): Calculates the percentage of expenses categorized as "Wants".
  /// If it exceeds 30% of total income, returns a warning.
  String analyzeWantsSpending({
    required double totalIncome,
    required double wantsExpenses,
  }) {
    if (totalIncome <= 0) return "Data pendapatan tidak tersedia.";
    
    double percentage = (wantsExpenses / totalIncome) * 100;
    
    if (percentage > 30) {
      return "Peringatan: Pengeluaran 'Wants' Anda mencapai ${percentage.toStringAsFixed(1)}%, melebihi batas ideal 30%. Kurangi pengeluaran konsumtif.";
    }
    
    return "Bagus! Pengeluaran 'Wants' Anda terjaga di bawah 30%.";
  }

  /// Rule B (Emergency Fund): Checks if the "Savings" balance is less than 
  /// 3x the average monthly expenses.
  String checkEmergencyFund({
    required double currentSavings,
    required double averageMonthlyExpenses,
  }) {
    double target = averageMonthlyExpenses * 3;
    
    if (currentSavings < target) {
      double gap = target - currentSavings;
      return "Rekomendasi: Dana darurat Anda saat ini kurang dari 3x pengeluaran bulanan. Anda butuh tambahan ${NumberFormat.currency(symbol: 'Rp', decimalDigits: 0).format(gap)} lagi untuk mencapai zona aman.";
    }
    
    return "Luar biasa! Dana darurat Anda sudah mencukupi untuk 3 bulan ke depan.";
  }

  /// Rule C (Anomaly Detection): Compares current week expenses in a specific 
  /// category vs last week. If it spikes >20%, returns a warning.
  String detectAnomaly({
    required String categoryName,
    required double lastWeekSpending,
    required double currentWeekSpending,
  }) {
    if (lastWeekSpending <= 0) return "Data minggu lalu untuk $categoryName tidak tersedia.";
    
    double increase = ((currentWeekSpending - lastWeekSpending) / lastWeekSpending) * 100;
    
    if (increase > 20) {
      return "Anomali Terdeteksi: Pengeluaran $categoryName melonjak ${increase.toStringAsFixed(1)}% dibanding minggu lalu. Apakah ini pengeluaran terencana?";
    }
    
    return "Pengeluaran $categoryName Anda stabil dibanding minggu lalu.";
  }

  /// General Insight Generator
  /// Can be used to populate "Insight Cards" or "Chat UI"
  List<String> getQuickInsights({
    required double income,
    required double expenses,
    required double savings,
    required double wants,
  }) {
    return [
      analyzeWantsSpending(totalIncome: income, wantsExpenses: wants),
      checkEmergencyFund(currentSavings: savings, averageMonthlyExpenses: expenses),
    ];
  }
}
