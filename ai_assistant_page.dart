import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatSession _chatSession;
  final List<Content> _displayHistory = [];
  bool _loading = false;

  // ✅ Your API Key
  final String _geminiKey = "AIzaSyAS1uDifKl0HloZ2WPdXHwf8Af3huWqX7I";

  @override
  void initState() {
    super.initState();
    _setupChat();
  }

  void _setupChat() {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _geminiKey,
    );
    _chatSession = model.startChat();
  }

  Future<void> _sendMsg() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final userContent = Content('user', [TextPart(text)]);

    setState(() {
      _displayHistory.add(userContent);
      _loading = true;
    });
    _controller.clear();
    _scrollDown();

    try {
      final response = await _chatSession.sendMessage(userContent);
      setState(() {
        if (response.text != null) {
          _displayHistory.add(Content('model', [TextPart(response.text!)]));
        }
      });
    } catch (e) {
      setState(() {
        _displayHistory.add(Content('model', [
          TextPart("Connection error: Please check your internet or try using a VPN.")
        ]));
      });
    } finally {
      setState(() => _loading = false);
      _scrollDown();
    }
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("UniMate AI Helper", style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF6366F1),
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: _displayHistory.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 60, color: Colors.blue.withAlpha(80)),
                  const SizedBox(height: 10),
                  Text("How can I help you today?",
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
              physics: const BouncingScrollPhysics(),
              itemCount: _displayHistory.length,
              itemBuilder: (context, i) {
                final content = _displayHistory[i];
                final isUser = content.role == 'user';
                final String messageText = content.parts
                    .whereType<TextPart>()
                    .map((e) => e.text)
                    .join('');

                return _buildChatBubble(messageText, isUser, isDark);
              },
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: LinearProgressIndicator(backgroundColor: Colors.transparent, minHeight: 2),
            ),
          _buildInputArea(isDark),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser, bool isDark) {
    bool isError = text.contains("Connection error");

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF6366F1)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
          border: Border.all(
              color: isError ? Colors.redAccent.withAlpha(50) : Colors.transparent
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(isDark ? 40 : 15),
                blurRadius: 10,
                offset: const Offset(0, 4)
            )
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser
                ? Colors.white
                : (isError ? Colors.redAccent : (isDark ? Colors.white : Colors.black87)),
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 25),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10)
                ],
              ),
              child: TextField(
                controller: _controller,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: "Ask anything about studies...",
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onSubmitted: (_) => _sendMsg(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMsg,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF6366F1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0xFF6366F1), blurRadius: 8, spreadRadius: -2)
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}