// frontend/lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api';
  static String? _token;

  // Initialize token
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('authToken');
  }

  // Save token
  static Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
  }

  // Clear token
  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
  }

  // Get headers
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Token $_token',
      };

  // Register
  static Future<Map<String, dynamic>> register(
    String username,
    String password,
    String email,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.containsKey('token')) {
        await _saveToken(data['token']);
      }
      return data;
    } else {
      throw Exception(
        jsonDecode(response.body)['error'] ?? 'Registration failed',
      );
    }
  }

  // Login
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.containsKey('token')) {
        await _saveToken(data['token']);
      }
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Login failed');
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/logout/'),
        headers: _headers,
      );
    } catch (e) {
      print('Error during logout: $e');
    } finally {
      await clearToken();
    }
  }

  // Send chat message
  static Future<Map<String, dynamic>> sendMessage({
    required String message,
    int? conversationId,
    String mode = 'unstructured',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/conversations/chat/'),
      headers: _headers,
      body: jsonEncode({
        'message': message,
        'conversation_id': conversationId,
        'mode': mode,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print(
          'Failed to send message: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to send message: ${response.statusCode}');
    }
  }

  // Get conversations
  static Future<List<dynamic>> getConversations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/conversations/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load conversations');
    }
  }

  // Get conversation history
  static Future<List<dynamic>> getConversationHistory(
    int conversationId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/conversations/$conversationId/history/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load conversation history');
    }
  }

  // Get mood trends
  static Future<Map<String, dynamic>> getMoodTrends() async {
    final response = await http.get(
      Uri.parse('$baseUrl/context/mood_trends/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load mood trends');
    }
  }
}
