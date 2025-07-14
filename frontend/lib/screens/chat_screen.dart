import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/meditation_suggestion_card.dart';
import '../models/crisis_models.dart';
import '../services/crisis_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  // ignore: unused_field
  EmergencyContact? _primaryEmergencyContact;

  @override
  void initState() {
    super.initState();
    _loadEmergencyContact();
    // Check Ollama status when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).checkOllamaStatus();
    });
  }

  Future<void> _loadEmergencyContact() async {
    try {
      await Future.delayed(Duration(seconds: 1));
      final contacts = await CrisisService.getEmergencyContacts();

      if (contacts.isNotEmpty) {
        setState(() {
          _primaryEmergencyContact = contacts.firstWhere(
            (c) => c.isPrimary,
            orElse: () => contacts.first,
          );
        });
      }
    } catch (e) {
      // Handle error silently
      debugPrint('Error loading emergency contacts: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    try {
      final provider = Provider.of<ChatProvider>(context, listen: false);
      await provider.sendMessage(message);

      if (!mounted) return;
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Meditation Companion'),
        backgroundColor: const Color(0xFF6B4EFF),
        elevation: 0,
        actions: [
          // Ollama connection status indicator
          Consumer<ChatProvider>(
            builder: (context, chatProvider, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  chatProvider.ollamaConnected
                      ? Icons.circle
                      : Icons.circle_outlined,
                  color: chatProvider.ollamaConnected
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  size: 12,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status banner (if disconnected)
          Consumer<ChatProvider>(
            builder: (context, chatProvider, _) {
              if (!chatProvider.ollamaConnected) {
                return Container(
                  color: Colors.orange.withOpacity(0.1),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'AI service is offline - Please start Ollama',
                        style: TextStyle(color: Colors.orange[800]),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Messages
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: chatProvider.messages.length +
                      (chatProvider.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == chatProvider.messages.length) {
                      return const TypingIndicator();
                    }
                    return MessageBubble(
                      message: chatProvider.messages[index],
                    );
                  },
                );
              },
            ),
          ),

          // Meditation suggestion card (if applicable)
          Consumer<ChatProvider>(
            builder: (context, chatProvider, _) {
              if (chatProvider.showMeditationSuggestion &&
                  chatProvider.suggestedTechniques.isNotEmpty) {
                return MeditationSuggestionCard(
                  techniques: chatProvider.suggestedTechniques,
                  onAccept: () {
                    // Start meditation session
                    _startMeditationSession(chatProvider.suggestedTechniques);
                    chatProvider.hideMeditationSuggestion();
                  },
                  onDismiss: () {
                    chatProvider.hideMeditationSuggestion();
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Input field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Share what\'s on your mind...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF0F0F0),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6B4EFF), Color(0xFF8B6BFF)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                      ),
                      onPressed: _sendMessage,
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

  void _startMeditationSession(List<String> techniques) {
    // TODO: Implement meditation session
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting ${techniques.first} meditation...'),
        backgroundColor: const Color(0xFF6B4EFF),
      ),
    );
  }
}
