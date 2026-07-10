import 'package:flutter/material.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'assistant',
      'content': "Hello! I am your DNB AI Assistant. 🌟\n\nI can help you navigate local markets, discover prime investment areas, calculate mortgage options, or find properties matching a specific budget. What are you looking for today?",
      'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
    }
  ];

  final List<String> _suggestedPrompts = [
    "Apartments in Muyenga under 3M UGX",
    "Best suburbs for land in Wakiso",
    "Featured properties on sale",
    "Talk to a human agent",
  ];

  bool _isTyping = false;

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'content': text.trim(),
        'timestamp': DateTime.now(),
      });
      _isTyping = true;
    });
    
    _messageController.clear();
    _scrollToBottom();

    // Mock AI reply simulating properties advice matching user interest
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      String reply = "";
      final lowercaseText = text.toLowerCase();

      if (lowercaseText.contains("muyenga") || lowercaseText.contains("apartment")) {
        reply = "I found some premium apartments around Muyenga and central regions! Many feature premium security, spacious parking, and views starting from UGX 1,500,000 to UGX 3,500,000. Would you like me to filter these for you?";
      } else if (lowercaseText.contains("wakiso") || lowercaseText.contains("land")) {
        reply = "Wakiso currently has high-growth residential land plots (Kira, Bulindo, Gayaza) ranging from 20M to 80M UGX for standard 50x100ft dimensions. Let me know if you would like to view listings with verified land titles.";
      } else if (lowercaseText.contains("sale") || lowercaseText.contains("buy")) {
        reply = "We have over 20+ newly listed properties for sale! You can explore options featuring automated video tours directly through the Explore tab to scan interiors instantly. Let me know if you would like me to list them here.";
      } else if (lowercaseText.contains("agent") || lowercaseText.contains("human")) {
        reply = "Certainly! You can connect with Douglas Bagambe or other DNB principal brokers directly on WhatsApp or Call within any property detail card. Would you like me to show broker contact lines?";
      } else {
        reply = "That sounds fascinating! DNB Homes focuses on premium and verified properties in Uganda. I can tailor choices based on preferred rooms, dimensions, budgeting, and locations. Tell me more details about your ideal layout!";
      }

      setState(() {
        _isTyping = false;
        _messages.add({
          'role': 'assistant',
          'content': reply,
          'timestamp': DateTime.now(),
        });
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B111E) : Colors.grey[50]!,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0B111E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.primaryColor.withOpacity(0.15),
              child: Icon(Icons.forum_rounded, color: theme.primaryColor, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DNB Assistant',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI Online',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: isDark ? Colors.white70 : Colors.black54),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add({
                  'role': 'assistant',
                  'content': 'Chat cleared. How can I assist you with DNB Properties now?',
                  'timestamp': DateTime.now(),
                });
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    decoration: BoxDecoration(
                      color: isUser
                          ? theme.primaryColor
                          : (isDark ? const Color(0xFF131B2E) : Colors.white),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: isUser
                          ? null
                          : Border.all(
                              color: isDark ? const Color(0xFF1E293B) : Colors.grey[200]!,
                              width: 1,
                            ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      msg['content'],
                      style: TextStyle(
                        color: isUser ? Colors.white : (isDark ? const Color(0xFFE2E8F0) : Colors.black87),
                        height: 1.4,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 12),
              child: Row(
                children: [
                  Text(
                    'DNB AI is thinking',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white.withOpacity(0.38) : Colors.black.withOpacity(0.38)),
                  ),
                  const SizedBox(width: 6),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFF178F5B))),
                  ),
                ],
              ),
            ),

          if (_messages.length == 1 && !_isTyping)
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _suggestedPrompts.length,
                itemBuilder: (context, index) {
                  final prompt = _suggestedPrompts[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(
                      label: Text(prompt),
                      elevation: 0,
                      backgroundColor: isDark ? const Color(0xFF131B2E) : Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFFCBD5E1) : theme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: isDark ? const Color(0xFF1E293B) : Colors.grey[300]!, width: 0.8),
                      ),
                      onPressed: () => _sendMessage(prompt),
                    ),
                  );
                },
              ),
            ),
          
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131B2E) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF1E293B) : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0B111E) : Colors.grey[100]!,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Ask DNB AI Assistant...',
                          hintStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3)),
                          border: InputBorder.none,
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(_messageController.text),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.primaryColor,
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
