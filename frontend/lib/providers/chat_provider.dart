// frontend/lib/providers/chat_provider.dart
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  List<Message> _messages = [];
  List<Conversation> _conversations = [];
  int? _currentConversationId;
  bool _isLoading = false;
  String _currentMode = 'unstructured';
  List<String> _suggestions = [];

  List<Message> get messages => _messages;
  List<Conversation> get conversations => _conversations;
  int? get currentConversationId => _currentConversationId;
  bool get isLoading => _isLoading;
  String get currentMode => _currentMode;
  List<String> get suggestions => _suggestions;

  // Set conversation mode
  void setMode(String mode) {
    _currentMode = mode;
    _currentConversationId = null;
    _messages = [];
    notifyListeners();
  }

  // Load conversations
  Future<void> loadConversations() async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = await ApiService.getConversations();
      _conversations = data.map((c) => Conversation.fromJson(c)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Load conversation history
  Future<void> loadConversationHistory(int conversationId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = await ApiService.getConversationHistory(conversationId);
      _messages = data.map((m) => Message.fromJson(m)).toList();
      _currentConversationId = conversationId;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
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

      print('Sending message: $content');
      print('Conversation ID: $_currentConversationId');
      print('Mode: $_currentMode');

      final response = await ApiService.sendMessage(
        message: content,
        conversationId: _currentConversationId,
        mode: _currentMode,
      );

      // Update conversation ID if new
      if (response.containsKey('conversation_id')) {
        _currentConversationId = response['conversation_id'];
      }

      // Add AI message if response contains it
      if (response.containsKey('ai_message')) {
        final aiMessage = Message.fromJson(response['ai_message']);
        _messages.add(aiMessage);
      }

      // Update suggestions if available
      if (response.containsKey('suggestions')) {
        _suggestions = List<String>.from(response['suggestions'] ?? []);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error sending message: $e');
      _isLoading = false;
      // Remove the user message if sending failed
      _messages.removeLast();
      notifyListeners();
      rethrow;
    }
  }

  // Clear current conversation
  void clearConversation() {
    _messages = [];
    _currentConversationId = null;
    _suggestions = [];
    notifyListeners();
  }
}
