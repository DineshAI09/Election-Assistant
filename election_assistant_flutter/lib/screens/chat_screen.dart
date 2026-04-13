import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/message.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService(
    baseUrl: 'http://10.0.2.2:5000',
  );

  bool _isLoading = false;
  bool _isListening = false;
  bool _speechAvailable = false;
  late stt.SpeechToText _speech;
  late FlutterTts _tts;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _initSpeech();
    _tts.setLanguage('en-IN');
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (_) => setState(() => _isListening = false),
    );
    setState(() {});
  }

  Future<void> _speakText(String text) async {
    if (text.isEmpty) return;
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final englishParts = <String>[];
    final tamilParts = <String>[];
    final tamilRange = RegExp(r'[\u0B80-\u0BFF]');

    for (final line in lines) {
      if (tamilRange.hasMatch(line)) {
        tamilParts.add(line);
      } else {
        englishParts.add(line);
      }
    }

    if (englishParts.isNotEmpty) {
      await _tts.setLanguage('en-IN');
      await _tts.speak(englishParts.join('. '));
    }
    if (tamilParts.isNotEmpty) {
      await _tts.setLanguage('ta-IN');
      await _tts.speak(tamilParts.join(' '));
    }
    if (englishParts.isEmpty && tamilParts.isEmpty) {
      await _tts.setLanguage('en-IN');
      await _tts.speak(text);
    }
  }

  Future<void> _sendMessage([String? text]) async {
    final messageText = (text ?? _inputController.text).trim();
    if (messageText.isEmpty) return;

    _inputController.clear();

    setState(() {
      _messages.add(ChatMessage(text: messageText, sender: MessageSender.user));
      _isLoading = true;
    });
    _scrollToBottom();

    final response = await _chatService.sendQuery(messageText);

    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(
        text: response.text,
        image: response.image,
        sender: MessageSender.bot,
      ));
      _isLoading = false;
    });
    _scrollToBottom();
    _speakText(response.text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) return;
    if (_isListening) {
      await _speech.stop();
      return;
    }
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          _sendMessage(result.recognizedWords);
          _speech.stop();
        }
      },
      localeId: 'en_IN',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      partialResults: false,
    );
    setState(() => _isListening = true);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF2F5FF),
              Color(0xFFE3ECFF),
              Color(0xFFF5F7FB),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildChatList(),
              ),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              const Text('🗳️', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Election Assistant',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ask about parties, flags, symbols, and leaders.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.96),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: _messages.isEmpty && !_isLoading
              ? _buildPlaceholder()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Try asking: "Show DMK flag" or "Who is CM of Tamil Nadu?"',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.grey.shade300,
            child: const Text('🤖', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDot(0),
              _buildDot(1),
              _buildDot(2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int _) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.sender == MessageSender.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey.shade300,
              child: const Text('🤖', style: TextStyle(fontSize: 16)),
            ),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (msg.text != null && msg.text!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isUser
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            )
                          : null,
                      color: isUser ? null : const Color(0xFFF3F4FF),
                      border: isUser ? null : Border.all(color: const Color(0xFF818CF8).withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                    ),
                    child: Text(
                      msg.text!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                if (msg.image != null && msg.image!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      msg.image!,
                      width: 160,
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox(width: 160, height: 80),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey.shade300,
              child: const Text('👤', style: TextStyle(fontSize: 16)),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.96),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: 'Type your election question...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: () => _sendMessage(),
                      borderRadius: BorderRadius.circular(999),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Text('Send', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: _isListening ? const Color(0xFFFEE2E2) : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: _speechAvailable ? _startListening : null,
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.mic,
                          size: 22,
                          color: _isListening ? const Color(0xFFB91C1C) : const Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Voice input uses your device microphone. Works offline with on-device answers.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
