import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
      'content': 'Selamat datang! Saya asisten **fina**. Saya siap memberikan analisis mendalam mengenai kesehatan keuangan Anda hari ini. Apa yang bisa saya bantu analisis? 😊'
    }
  ];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;

  final List<String> _quickActions = [
    'Analisis keuangan saya',
    'Cek saldo kas',
    'Evaluasi dana darurat',
    'Daftar tagihan rutin',
    'Bantuan fitur',
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
    Future.delayed(const Duration(milliseconds: 1500), () {
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Asisten Fina', style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
    final theme = Theme.of(context);
    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: isAI ? Theme.of(context).cardTheme.color : Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isAI ? 0 : 20),
            bottomRight: Radius.circular(isAI ? 20 : 0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: isAI ? Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)) : null,
        ),
        child: MarkdownBody(
          data: content,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              color: isAI ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onPrimary,
              fontSize: 14,
              height: 1.5,
            ),
            h3: TextStyle(
              color: isAI ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 2.0,
            ),
            h4: TextStyle(
              color: isAI ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              height: 1.8,
            ),
            listBullet: TextStyle(
              color: isAI ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onPrimary,
            ),
            code: TextStyle(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) => _buildDot(index)),
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        shape: BoxShape.circle,
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
              labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
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
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 34),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tanya asisten fina...',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
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
          GestureDetector(
            onTap: () => _sendMessage(),
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_upward_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
