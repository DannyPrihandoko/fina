import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_ai_engine.dart';
import '../providers/database_provider.dart';
import '../theme/colors.dart';
import '../models/transaction.dart';

class AIScreen extends ConsumerStatefulWidget {
  const AIScreen({super.key});

  @override
  ConsumerState<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends ConsumerState<AIScreen> {
  final _aiEngine = LocalAIEngine();
  final List<Map<String, String>> _messages = [
    {
      'role': 'ai',
      'content': 'Halo! Saya asisten fina. Saya telah menganalisis keuangan Anda. Ada yang bisa saya bantu hari ini?'
    }
  ];
  final _controller = TextEditingController();

  void _sendMessage() {
    if (_controller.text.isEmpty) return;
    
    setState(() {
      _messages.add({'role': 'user', 'content': _controller.text});
    });
    
    final query = _controller.text.toLowerCase();
    _controller.clear();

    // Simple local logic for AI response
    Future.delayed(const Duration(milliseconds: 800), () {
      String response = "Maaf, saya belum mengerti pertanyaan itu. Coba tanya tentang 'analisis' atau 'status' keuangan Anda.";
      
      if (query.contains('analisis') || query.contains('status')) {
        final transactions = ref.read(transactionsProvider);
        double income = 0;
        double expense = 0;
        double wants = 0;
        
        for (var tx in transactions) {
          if (tx.type == TransactionType.income) {
            income += tx.amount;
          } else {
            expense += tx.amount;
            if (tx.category == 'Hiburan' || tx.category == 'Belanja') {
              wants += tx.amount;
            }
          }
        }
        
        final insights = _aiEngine.getQuickInsights(
          income: income,
          expenses: expense,
          savings: income - expense,
          wants: wants,
        );
        
        response = "Berikut analisis saya:\n\n${insights.join('\n\n')}";
      }

      setState(() {
        _messages.add({'role': 'ai', 'content': response});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asisten AI', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isAI = msg['role'] == 'ai';
                return Align(
                  alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isAI ? AppColors.cardPaleBlue : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isAI ? 0 : 16),
                        bottomRight: Radius.circular(isAI ? 16 : 0),
                      ),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: Text(
                      msg['content']!,
                      style: const TextStyle(color: AppColors.textDarkBlue, fontSize: 14, height: 1.4),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Tanya tentang keuangan Anda...',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.ctaAqua,
                    foregroundColor: AppColors.textDarkBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
