// frontend/lib/services/meditation_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meditation_models.dart';
import 'api_service.dart';

class MeditationService {
  static const String baseUrl = ApiService.baseUrl;

  static Map<String, String> get headers => ApiService.headers;

  // Get meditation recommendations
  static Future<List<MeditationRecommendation>> getRecommendations({
    required int conversationId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recommendations/generate/'),
      headers: headers,
      body: jsonEncode({'conversation_id': conversationId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final recommendations = data['recommendations'] as List;
      return recommendations
          .map((r) => MeditationRecommendation.fromJson(r))
          .toList();
    } else {
      throw Exception('Failed to get recommendations');
    }
  }

  // Browse meditations
  static Future<List<Meditation>> browseMeditations({
    String? type,
    String? level,
    int? maxDuration,
    String? targetState,
  }) async {
    final queryParams = <String, String>{};
    if (type != null) queryParams['type'] = type;
    if (level != null) queryParams['level'] = level;
    if (maxDuration != null)
      queryParams['max_duration'] = maxDuration.toString();
    if (targetState != null) queryParams['target_state'] = targetState;

    final uri = Uri.parse('$baseUrl/meditations/').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((m) => Meditation.fromJson(m)).toList();
    } else {
      throw Exception('Failed to load meditations');
    }
  }

  // Start meditation session
  static Future<Map<String, dynamic>> startSession({
    required int meditationId,
    required int moodScore,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/meditations/$meditationId/start_session/'),
      headers: headers,
      body: jsonEncode({'mood_score': moodScore}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to start session');
    }
  }

  // Complete meditation session
  static Future<Map<String, dynamic>> completeSession({
    required int sessionId,
    required int moodScore,
    required double completionPercentage,
    bool? helpful,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/$sessionId/complete/'),
      headers: headers,
      body: jsonEncode({
        'mood_score': moodScore,
        'completion_percentage': completionPercentage,
        'helpful': helpful,
        'notes': notes,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to complete session');
    }
  }

  // Get user stats
  static Future<UserMeditationStats> getUserStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile/stats/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return UserMeditationStats.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load stats');
    }
  }

  // Update preferences
  static Future<void> updatePreferences({
    List<String>? preferredTypes,
    int? preferredDuration,
    String? preferredTimeOfDay,
  }) async {
    final body = <String, dynamic>{};
    if (preferredTypes != null) body['preferred_types'] = preferredTypes;
    if (preferredDuration != null)
      body['preferred_duration'] = preferredDuration;
    if (preferredTimeOfDay != null)
      body['preferred_time_of_day'] = preferredTimeOfDay;

    final response = await http.post(
      Uri.parse('$baseUrl/profile/update_preferences/'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update preferences');
    }
  }

  // Provide recommendation feedback
  static Future<void> provideFeedback({
    required int recommendationId,
    int? rating,
    String? feedback,
    bool? helpful,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recommendations/$recommendationId/feedback/'),
      headers: headers,
      body: jsonEncode({
        'rating': rating,
        'feedback': feedback,
        'helpful': helpful,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit feedback');
    }
  }
}
