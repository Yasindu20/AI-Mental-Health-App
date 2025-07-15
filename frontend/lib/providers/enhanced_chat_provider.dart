// frontend/lib/providers/enhanced_chat_provider.dart
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/meditation_models.dart';
import '../services/api_service.dart';
import '../services/meditation_service.dart';

class EnhancedChatProvider extends ChangeNotifier {
  List<Message> _messages = [];
  int? _currentConversationId;
  bool _isLoading = false;
  List<MeditationRecommendation> _recommendations = [];
  MentalStateAnalysis? _currentAnalysis;
  bool _showRecommendations = false;

  List<Message> get messages => _messages;
  int? get currentConversationId => _currentConversationId;
  bool get isLoading => _isLoading;
  List<MeditationRecommendation> get recommendations => _recommendations;
  MentalStateAnalysis? get currentAnalysis => _currentAnalysis;
  bool get showRecommendations => _showRecommendations;

  // Send message and analyze
  Future<void> sendMessageAndAnalyze(String content) async {
    if (content.trim().isEmpty) return;

    // Add user message
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

      // Send message
      final response = await ApiService.sendMeditationMessage(
        message: content,
        conversationId: _currentConversationId,
      );

      // Update conversation ID
      if (response.containsKey('conversation_id')) {
        _currentConversationId = response['conversation_id'];
      }

      // Add AI response
      if (response.containsKey('ai_message')) {
        final aiMessage = Message.fromJson(response['ai_message']);
        _messages.add(aiMessage);
      }

      // Check if we should generate recommendations
      if (_messages.length >= 6 && _messages.length % 6 == 0) {
        // Every 6 messages, generate recommendations
        await _generateRecommendations();
      }
    } catch (e) {
      debugPrint('Error: $e');
      _messages.add(Message(
        content: "I'm having trouble connecting. Please try again.",
        isUser: false,
        createdAt: DateTime.now(),
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Generate meditation recommendations
  Future<void> _generateRecommendations() async {
    if (_currentConversationId == null) return;

    try {
      final recs = await MeditationService.getRecommendations(
        conversationId: _currentConversationId!,
      );

      _recommendations = recs;
      _showRecommendations = true;

      // Extract analysis
      if (recs.isNotEmpty && recs.first.analysis != null) {
        _currentAnalysis = recs.first.analysis;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error generating recommendations: $e');
    }
  }

  void hideRecommendations() {
    _showRecommendations = false;
    notifyListeners();
  }

  void clearConversation() {
    _messages = [];
    _currentConversationId = null;
    _recommendations = [];
    _currentAnalysis = null;
    _showRecommendations = false;
    notifyListeners();
  }
}
