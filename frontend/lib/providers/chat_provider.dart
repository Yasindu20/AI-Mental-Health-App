import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  List<Message> _messages = [];
  int? _currentConversationId;
  bool _isLoading = false;
  bool _showMeditationSuggestion = false;
  List<String> _suggestedTechniques = [];
  String? _detectedMood;
  bool _ollamaConnected = false;

  List<Message> get messages => _messages;
  int? get currentConversationId => _currentConversationId;
  bool get isLoading => _isLoading;
  bool get showMeditationSuggestion => _showMeditationSuggestion;
  List<String> get suggestedTechniques => _suggestedTechniques;
  String? get detectedMood => _detectedMood;
  bool get ollamaConnected => _ollamaConnected;

  ChatProvider() {
    checkOllamaStatus();
  }

  // Check if Ollama is running
  Future<void> checkOllamaStatus() async {
    try {
      final status = await ApiService.checkOllamaStatus();
      _ollamaConnected = status['connected'] && status['model_available'];
      notifyListeners();
    } catch (e) {
      _ollamaConnected = false;
      notifyListeners();
    }
  }

  // Send message
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Add user message immediately
    final userMessage = Message(
      content: content,
      isUser: true,
      createdAt: DateTime.now(),
    );
    _messages.add(userMessage);
    notifyListeners();

    try {
      _isLoading = true;
      notifyListeners();

      final response = await ApiService.sendMeditationMessage(
        message: content,
        conversationId: _currentConversationId,
      );

      // Update conversation ID if new
      if (response.containsKey('conversation_id')) {
        _currentConversationId = response['conversation_id'];
      }

      // Add AI message
      if (response.containsKey('ai_message')) {
        final aiMessage = Message.fromJson(response['ai_message']);
        _messages.add(aiMessage);
      }

      // Handle meditation suggestions
      if (response['meditation_suggested'] == true) {
        _showMeditationSuggestion = true;
        _suggestedTechniques = List<String>.from(response['techniques'] ?? []);
      }

      // Update detected mood
      _detectedMood = response['mood_detected'];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error sending message: $e');
      _isLoading = false;

      // Add error message
      final errorMessage = Message(
        content:
            "I'm having trouble connecting. Please make sure the meditation service is running.",
        isUser: false,
        createdAt: DateTime.now(),
      );
      _messages.add(errorMessage);

      notifyListeners();
    }
  }

  void hideMeditationSuggestion() {
    _showMeditationSuggestion = false;
    notifyListeners();
  }

  // Clear conversation
  void clearConversation() {
    _messages = [];
    _currentConversationId = null;
    _showMeditationSuggestion = false;
    _suggestedTechniques = [];
    _detectedMood = null;
    notifyListeners();
  }
}
