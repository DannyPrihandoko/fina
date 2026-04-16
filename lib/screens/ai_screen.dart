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
      'content': 'Halo! Saya asisten fina. Saya sudah siap menganalisis keuangan Anda. Ada yang ingin ditanyakan?'
    }
  ];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;

  final List<String> _quickActions = [
    'Saran Saldo',
    'Analisis Keuangan',
    'Status Saldo',
    'Dana Darurat',
  ];

  void _sendMessage([String? text]) {
    final query = text ?? _controller.text;
    if (query.isEmpty) return;
    
    setState(() {
      _messages.add({'role': 'user', 'content': query});
      _isTyping = true;
    });
    
    if (text == null) _controller.clear();
    _scrollToBottom();

    // Natural delay for "AI thinking" effect
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;

      final transactions = ref.read(transactionsProvider);
      final bills = ref.read(billsProvider);
      
      final response = _aiEngine.processQuery(
        query: query,
        transactions: transactions,
        bills: bills,
      );

      setState(() {
        _isTyping = false;
        _messages.add({'role': 'ai', 'content': response});
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Asisten AI', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[index];
                final isAI = msg['role'] == 'ai';
                return _buildMessageBubble(msg['content']!, isAI);
              },
            ),
          ),
          if (!_isTyping) _buildQuickActions(),
          _buildInputSection(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String content, bool isAI) {
    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: isAI ? Colors.white : AppColors.textDarkBlue,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isAI ? 0 : 20),
            bottomRight: Radius.circular(isAI ? 20 : 0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: isAI ? Border.all(color: AppColors.borderColor) : null,
        ),
        child: Text(
          content,
          style: TextStyle(
            color: isAI ? AppColors.textDarkBlue : Colors.white,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: const SizedBox(
          width: 40,
          child: LinearProgressIndicator(
            backgroundColor: AppColors.cardPaleBlue,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.ctaAqua),
            minHeight: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickActions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(_quickActions[index]),
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDarkBlue),
              backgroundColor: AppColors.ctaAqua.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
              onPressed: () => _sendMessage(_quickActions[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
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
                hintText: 'Tanya asisten fina...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.cardPaleBlue.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: AppColors.textDarkBlue,
            child: IconButton(
              onPressed: () => _sendMessage(),
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
