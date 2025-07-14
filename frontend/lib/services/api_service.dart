import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api';
  static String? _token;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('authToken');
  }

  static Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
  }

  static Map<String, String> get headers => {
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
        headers: headers,
      );
    } catch (e) {
      print('Error during logout: $e');
    } finally {
      await clearToken();
    }
  }

  // Send meditation chat message
  static Future<Map<String, dynamic>> sendMeditationMessage({
    required String message,
    int? conversationId,
  }) async {
    final Map<String, dynamic> requestBody = {
      'message': message,
    };

    if (conversationId != null) {
      requestBody['conversation_id'] = conversationId;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/meditation/chat/'),
      headers: headers,
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print(
          'Failed to send message: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to send message');
    }
  }

  // Check Ollama status
  static Future<Map<String, dynamic>> checkOllamaStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/meditation/status/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        'connected': false,
        'models': [],
        'current_model': '',
        'model_available': false,
      };
    }
  }

  // Get meditation stats (placeholder for future features)
  static Future<Map<String, dynamic>> getMeditationStats() async {
    // For now, return mock data
    return {
      'total_sessions': 12,
      'total_minutes': 156,
      'current_streak': 5,
      'favorite_techniques': ['breathing', 'mindfulness'],
    };
  }
}
