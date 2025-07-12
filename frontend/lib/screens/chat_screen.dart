import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/suggestion_chips.dart';
import '../models/crisis_models.dart';
import '../services/crisis_service.dart';
import '../widgets/crisis_alert_dialog.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  EmergencyContact? _primaryEmergencyContact;
  bool _shouldCheckForCrisis = false;

  @override
  void initState() {
    super.initState();
    _loadEmergencyContact();
  }

  Future<void> _loadEmergencyContact() async {
    try {
      // Delay the loading slightly to ensure authentication is ready
      await Future.delayed(Duration(seconds: 1));
      final contacts = await CrisisService.getEmergencyContacts();

      if (contacts.isNotEmpty) {
        setState(() {
          _primaryEmergencyContact = contacts.firstWhere(
            (c) => c.isPrimary,
            orElse: () => contacts.first,
          );
        });
        print(
            'Loaded primary emergency contact: ${_primaryEmergencyContact?.name}');
      } else {
        print('No emergency contacts found');
      }
    } catch (e) {
      // Handle error silently but log it
      print('Error loading emergency contacts: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Helper method to get message content
  String _getMessageContent(Message message) {
    // Since content is non-nullable, we can directly return it
    return message.content;

    // If your Message class changes and you need to handle both properties,
    // uncomment the code below
    /*
    if (message.message != null) {
      return message.message!;
    } else {
      return message.content;
    }
    */
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    _shouldCheckForCrisis = true;

    try {
      // Get provider and send message
      final provider = Provider.of<ChatProvider>(context, listen: false);
      await provider.sendMessage(message);

      // Check for crisis indicators in the last message
      if (_shouldCheckForCrisis && provider.messages.isNotEmpty) {
        _shouldCheckForCrisis = false;

        // Check if the last message contains crisis indicators
        final lastMessage = provider.messages.last;
        final messageContent = _getMessageContent(lastMessage);

        if (_containsCrisisIndicators(messageContent)) {
          _handleCrisisDetection({
            'crisis_level': _determineCrisisLevel(messageContent),
            'crisis_resources': _getCrisisResources(),
            'immediate_risk': _determineImmediateRisk(messageContent),
          });
        }
      }

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

  // Helper method to check for crisis indicators in message text
  bool _containsCrisisIndicators(String text) {
    final lowerText = text.toLowerCase();
    // List of keywords that might indicate a crisis
    final crisisKeywords = [
      'suicide',
      'kill myself',
      'end my life',
      'die',
      'death',
      'hurt myself',
      'self-harm',
      'hopeless',
      'can\'t go on',
      'worthless',
      'better off without me',
      'no reason to live',
      'emergency',
      'crisis',
      'urgent help',
      'dangerous',
      'immediate danger'
    ];

    return crisisKeywords.any((keyword) => lowerText.contains(keyword));
  }

  // Helper method to determine crisis level based on message content
  String _determineCrisisLevel(String text) {
    final lowerText = text.toLowerCase();

    // Check for high severity keywords
    if (lowerText.contains('suicide') ||
        lowerText.contains('kill myself') ||
        lowerText.contains('end my life')) {
      return 'severe';
    }

    // Check for medium severity keywords
    if (lowerText.contains('hurt myself') ||
        lowerText.contains('self-harm') ||
        lowerText.contains('hopeless')) {
      return 'moderate';
    }

    // Default level
    return 'mild';
  }

  // Helper method to determine immediate risk
  bool _determineImmediateRisk(String text) {
    final lowerText = text.toLowerCase();

    // Check for immediate risk indicators
    final immediateRiskKeywords = [
      'now',
      'right now',
      'going to',
      'about to',
      'plan to',
      'tonight',
      'today',
      'pills',
      'gun',
      'weapon',
      'jump'
    ];

    return immediateRiskKeywords.any((keyword) => lowerText.contains(keyword));
  }

  // Helper method to provide crisis resources
  List<Map<String, dynamic>> _getCrisisResources() {
    // Return a default list of crisis resources
    return [
      {
        'name': 'National Suicide Prevention Lifeline',
        'phone': '1-800-273-8255',
        'website': 'https://suicidepreventionlifeline.org',
        'type': 'hotline'
      },
      {
        'name': 'Crisis Text Line',
        'phone': 'Text HOME to 741741',
        'website': 'https://www.crisistextline.org',
        'type': 'text'
      },
      {
        'name': 'Emergency Services',
        'phone': '911',
        'website': null,
        'type': 'emergency'
      }
    ];
  }

  void _handleCrisisDetection(Map<String, dynamic> response) async {
    final crisisLevel = response['crisis_level'];
    final resources = (response['crisis_resources'] as List?)
            ?.map((r) => CrisisResource.fromJson(r))
            .toList() ??
        [];
    final immediateRisk = response['immediate_risk'] ?? false;

    // Show crisis alert dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CrisisAlertDialog(
        crisisLevel: crisisLevel,
        resources: resources,
        emergencyContact: _primaryEmergencyContact,
        immediateRisk: immediateRisk,
      ),
    );

    // Log analytics (if implemented)
    // Analytics.logEvent('crisis_detected', {'level': crisisLevel});
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
