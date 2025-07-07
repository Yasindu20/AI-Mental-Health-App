import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/suggestion_chips.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  // Fix 1: Change private type in public API
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

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
      await Provider.of<ChatProvider>(context, listen: false)
          .sendMessage(message);
      // Fix 2: Add mounted check after async gap
      if (!mounted) return;
      _scrollToBottom();
    } catch (e) {
      // Fix 2: Add mounted check before using BuildContext
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleSuggestion(String suggestion) {
    // Handle suggestion tap
    String message = '';
    switch (suggestion) {
      case 'mood_check':
        message = "I'd like to do a mood check-in";
        break;
      case 'breathing_exercise':
        message = "Can we do a breathing exercise?";
        break;
      case 'mindfulness':
        message = "I'd like to try a mindfulness exercise";
        break;
      default:
        message = "I'd like to try: $suggestion";
    }
    _messageController.text = message;
    _sendMessage();
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
      appBar: AppBar(
        title: const Text('Mental Health Companion'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (mode) {
              Provider.of<ChatProvider>(context, listen: false).setMode(mode);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Switched to $mode mode')),
              );
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'unstructured',
                child: Text('Free Conversation'),
              ),
              PopupMenuItem(
                value: 'cbt_exercise',
                child: Text('CBT Exercise'),
              ),
              PopupMenuItem(
                value: 'mindfulness',
                child: Text('Mindfulness'),
              ),
              PopupMenuItem(
                value: 'mood_check',
                child: Text('Mood Check-in'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode indicator
          Consumer<ChatProvider>(
            builder: (context, chatProvider, _) {
              return Container(
                // Fix 3: Replace withOpacity with withValues
                color: Theme.of(context).primaryColor.withAlpha(25),
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getModeIcon(chatProvider.currentMode),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mode: ${_getModeName(chatProvider.currentMode)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            },
          ),

          // Messages
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
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

          // Suggestions
          Consumer<ChatProvider>(
            builder: (context, chatProvider, _) {
              return SuggestionChips(
                suggestions: chatProvider.suggestions,
                onSelected: _handleSuggestion,
              );
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
                  // Fix 4: Replace withOpacity with withAlpha
                  color: Colors.black.withAlpha(26),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer<ChatProvider>(
                    builder: (context, chatProvider, _) {
                      return CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white,
                          ),
                          onPressed:
                              chatProvider.isLoading ? null : _sendMessage,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getModeIcon(String mode) {
    switch (mode) {
      case 'cbt_exercise':
        return Icons.psychology;
      case 'mindfulness':
        return Icons.self_improvement;
      case 'mood_check':
        return Icons.mood;
      default:
        return Icons.chat;
    }
  }

  String _getModeName(String mode) {
    switch (mode) {
      case 'cbt_exercise':
        return 'CBT Exercise';
      case 'mindfulness':
        return 'Mindfulness';
      case 'mood_check':
        return 'Mood Check-in';
      default:
        return 'Free Conversation';
    }
  }
}
