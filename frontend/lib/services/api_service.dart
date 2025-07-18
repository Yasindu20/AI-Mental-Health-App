import 'dart:convert';
import 'package:frontend/models/meditation_models.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api';
  static String? _token;
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('authToken');
    _isInitialized = true;
    print(
        'ApiService initialized with token: ${_token != null ? 'Present' : 'None'}');
  }

  static Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
    print('Token saved: $token');
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    print('Token cleared');
  }

  static bool get hasToken => _token != null && _token!.isNotEmpty;

  static Map<String, String> get headers {
    final baseHeaders = {'Content-Type': 'application/json'};
    if (_token != null && _token!.isNotEmpty) {
      baseHeaders['Authorization'] = 'Token $_token';
    }
    return baseHeaders;
  }

  // Helper method to handle API responses
  static Future<Map<String, dynamic>> _handleResponse(
      http.Response response) async {
    print('API Response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 401) {
      await clearToken();
      throw Exception('Authentication failed. Please login again.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body);
    } else {
      String errorMessage = 'Request failed';
      try {
        final errorData = jsonDecode(response.body);
        errorMessage =
            errorData['error'] ?? errorData['detail'] ?? errorMessage;
      } catch (e) {
        errorMessage = 'Server error: ${response.statusCode}';
      }
      throw Exception(errorMessage);
    }
  }

  // Register
  static Future<Map<String, dynamic>> register(
    String username,
    String password,
    String email,
  ) async {
    await init();

    final response = await http.post(
      Uri.parse('$baseUrl/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'email': email,
      }),
    );

    final data = await _handleResponse(response);
    if (data.containsKey('token')) {
      await _saveToken(data['token']);
    }
    return data;
  }

  // Login
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    await init();

    final response = await http.post(
      Uri.parse('$baseUrl/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    final data = await _handleResponse(response);
    if (data.containsKey('token')) {
      await _saveToken(data['token']);
    }
    return data;
  }

  // Logout
  static Future<void> logout() async {
    try {
      if (hasToken) {
        await http.post(
          Uri.parse('$baseUrl/logout/'),
          headers: headers,
        );
      }
    } catch (e) {
      print('Error during logout: $e');
    } finally {
      await clearToken();
    }
  }

  // Generic GET request
  static Future<dynamic> get(String endpoint) async {
    await init();

    if (!hasToken) {
      throw Exception('Authentication required. Please login.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    return await _handleResponse(response);
  }

  // Generic POST request
  static Future<dynamic> post(String endpoint,
      {Map<String, dynamic>? body}) async {
    await init();

    if (!hasToken) {
      throw Exception('Authentication required. Please login.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );

    return await _handleResponse(response);
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

    return await post('/meditation/chat/', body: requestBody);
  }

  // Check Ollama status
  static Future<Map<String, dynamic>> checkOllamaStatus() async {
    try {
      return await get('/meditation/status/');
    } catch (e) {
      return {
        'connected': false,
        'models': [],
        'current_model': '',
        'model_available': false,
      };
    }
  }

  // Get external content meditations
  static Future<List<Meditation>> getExternalMeditations({
    String source = 'all',
    int page = 1,
  }) async {
    try {
      final queryParams = {
        'source': source,
        'page': page.toString(),
      };

      final query = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final data = await get('/meditations/external_content/?$query');

      if (data is Map && data.containsKey('results')) {
        final results = data['results'] as List? ?? [];
        return results.map((m) => Meditation.fromJson(m)).toList();
      } else if (data is List) {
        return data.map((m) => Meditation.fromJson(m)).toList();
      }

      return [];
    } catch (e) {
      print('Error getting external meditations: $e');
      return [];
    }
  }

  // Refresh content (admin only)
  static Future<Map<String, dynamic>> refreshContent() async {
    try {
      return await post('/meditations/refresh_content/');
    } catch (e) {
      print('Error refreshing content: $e');
      throw Exception('Failed to refresh content');
    }
  }
}
