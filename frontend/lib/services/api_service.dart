import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api';
  static String? _sessionId;

  // Initialize session
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString('sessionId');
  }

  // Save session
  static Future<void> _saveSession(String sessionId) async {
    _sessionId = sessionId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sessionId', sessionId);
  }

  // Clear session
  static Future<void> clearSession() async {
    _sessionId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sessionId');
  }

  // Get headers
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_sessionId != null) 'Cookie': 'sessionid=$_sessionId',
  };

  // Extract session from response
  static void _extractSession(http.Response response) {
    final cookies = response.headers['set-cookie'];
    if (cookies != null) {
      final sessionRegex = RegExp(r'sessionid=([^;]+)');
      final match = sessionRegex.firstMatch(cookies);
      if (match != null) {
        _saveSession(match.group(1)!);
      }
    }
  }

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

    _extractSession(response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
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

    _extractSession(response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Login failed');
    }
  }

  // Logout
  static Future<void> logout() async {
    await http.post(Uri.parse('$baseUrl/logout/'), headers: _headers);
    await clearSession();
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
      throw Exception('Failed to send message');
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
