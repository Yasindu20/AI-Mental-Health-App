import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/meditation_suggestion_card.dart';
import '../widgets/recommendation_bottom_sheet.dart';
import '../services/recommendation_service.dart';
import '../models/meditation_recommendation.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Check Ollama status when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).checkOllamaStatus();
    });
  }

  Future<void> _getRecommendations() async {
    try {
      // Get conversation text from all messages
      final provider = Provider.of<ChatProvider>(context, listen: false);
      String conversationText =
          provider.messages.map((message) => message.content).join(' ');

      if (conversationText.trim().isEmpty) {
        conversationText = _messageController.text;
      }

      List<MeditationRecommendation> recommendations =
          await RecommendationService.getRecommendations(
        conversationText: conversationText,
      );

      if (mounted) {
        _showRecommendations(recommendations);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get recommendations: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRecommendations(List<MeditationRecommendation> recommendations) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecommendationBottomSheet(
        recommendations: recommendations,
      ),
    );
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

      // Automatically get recommendations after sending a message
      _getRecommendations();
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
          // Recommendations button
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: _getRecommendations,
            tooltip: 'Get Recommendations',
          ),
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
                  color: Colors.orange.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning, size: 16, color: Colors.orange),
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
                  color: Colors.black.withValues(alpha: 0.1),
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
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
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
    // Navigate to meditation player or start session
    Navigator.pushNamed(
      context,
      '/meditation_player',
      arguments: {
        'title': '${techniques.first} Meditation',
        'audioUrl': 'https://example.com/guided_meditation.mp3',
        'imageUrl':
            'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=500',
        'duration': '10 min',
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting ${techniques.first} meditation...'),
        backgroundColor: const Color(0xFF6B4EFF),
      ),
    );
  }
}
