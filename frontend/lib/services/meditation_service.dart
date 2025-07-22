import '../models/meditation_models.dart';
import 'api_service.dart';

class MeditationService {
  // Get meditation recommendations
  static Future<List<MeditationRecommendation>> getRecommendations({
    required int conversationId,
  }) async {
    try {
      final data = await ApiService.post('/recommendations/generate/',
          body: {'conversation_id': conversationId});

      final recommendations = data['recommendations'] as List? ?? [];
      return recommendations
          .map((r) => MeditationRecommendation.fromJson(r))
          .toList();
    } catch (e) {
      print('Error getting recommendations: $e');
      throw Exception('Failed to get recommendations: $e');
    }
  }

  // Browse meditations
  static Future<List<Meditation>> browseMeditations({
    String? type,
    String? level,
    int? maxDuration,
    String? targetState,
  }) async {
    try {
      String endpoint = '/meditations/';
      final queryParams = <String, String>{};

      if (type != null && type != 'All') {
        queryParams['type'] = type.toLowerCase();
      }
      if (level != null && level != 'All') {
        queryParams['level'] = level.toLowerCase();
      }
      if (maxDuration != null) {
        queryParams['max_duration'] = maxDuration.toString();
      }
      if (targetState != null) queryParams['target_state'] = targetState;

      if (queryParams.isNotEmpty) {
        final query = queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
        endpoint += '?$query';
      }

      final data = await ApiService.get(endpoint);

      if (data is List) {
        return data.map((m) => Meditation.fromJson(m)).toList();
      } else if (data is Map && data.containsKey('results')) {
        final results = data['results'] as List? ?? [];
        return results.map((m) => Meditation.fromJson(m)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error browsing meditations: $e');
      throw Exception('Failed to load meditations: $e');
    }
  }

  // Start meditation session - FIXED: Handle string IDs
  static Future<Map<String, dynamic>> startSession({
    required String meditationId, // Changed from int to String
    required int moodScore,
  }) async {
    try {
      return await ApiService.post('/meditations/$meditationId/start_session/',
          body: {'mood_score': moodScore});
    } catch (e) {
      print('Error starting session: $e');
      throw Exception('Failed to start session: $e');
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
    try {
      return await ApiService.post('/sessions/$sessionId/complete/', body: {
        'mood_score': moodScore,
        'completion_percentage': completionPercentage,
        'helpful': helpful,
        'notes': notes,
      });
    } catch (e) {
      print('Error completing session: $e');
      throw Exception('Failed to complete session: $e');
    }
  }

  // Get user stats
  static Future<UserMeditationStats> getUserStats() async {
    try {
      final data = await ApiService.get('/profile/stats/');
      return UserMeditationStats.fromJson(data);
    } catch (e) {
      print('Error getting user stats: $e');
      // Return default stats instead of throwing an error
      return UserMeditationStats.defaultStats();
    }
  }

  // Update preferences
  static Future<void> updatePreferences({
    List<String>? preferredTypes,
    int? preferredDuration,
    String? preferredTimeOfDay,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (preferredTypes != null) body['preferred_types'] = preferredTypes;
      if (preferredDuration != null) {
        body['preferred_duration'] = preferredDuration;
      }
      if (preferredTimeOfDay != null) {
        body['preferred_time_of_day'] = preferredTimeOfDay;
      }

      await ApiService.post('/profile/update_preferences/', body: body);
    } catch (e) {
      print('Error updating preferences: $e');
      throw Exception('Failed to update preferences: $e');
    }
  }

  // Provide recommendation feedback
  static Future<void> provideFeedback({
    required int recommendationId,
    int? rating,
    String? feedback,
    bool? helpful,
  }) async {
    try {
      await ApiService.post('/recommendations/$recommendationId/feedback/',
          body: {
            'rating': rating,
            'feedback': feedback,
            'helpful': helpful,
          });
    } catch (e) {
      print('Error providing feedback: $e');
      throw Exception('Failed to submit feedback: $e');
    }
  }
}
