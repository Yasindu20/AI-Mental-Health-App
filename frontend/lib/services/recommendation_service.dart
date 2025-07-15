import '../models/mental_state.dart';
import '../models/user_preferences.dart';
import '../models/meditation_recommendation.dart';
import 'mental_state_analyzer.dart';
import 'recommendation_engine.dart';

class RecommendationService {
  static const List<Map<String, dynamic>> _sampleMeditations = [
    {
      'id': '1',
      'title': 'Stress Relief Breathing',
      'category': 'Stress Relief',
      'duration': '10 min',
      'difficulty': 'Beginner',
      'targets': ['stress', 'anxiety'],
      'rating': 4.8,
      'description': 'Simple breathing exercises to reduce stress and tension.',
      'audioUrl': 'https://example.com/stress_relief.mp3',
      'imageUrl':
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=500',
    },
    {
      'id': '2',
      'title': 'Deep Sleep Meditation',
      'category': 'Sleep',
      'duration': '20 min',
      'difficulty': 'Intermediate',
      'targets': ['insomnia', 'stress'],
      'rating': 4.9,
      'description': 'Guided meditation to prepare for restful sleep.',
      'audioUrl': 'https://example.com/deep_sleep.mp3',
      'imageUrl':
          'https://images.unsplash.com/photo-1445116572660-236099ec97a0?w=500',
    },
    {
      'id': '3',
      'title': 'Anxiety Relief',
      'category': 'Anxiety',
      'duration': '15 min',
      'difficulty': 'Beginner',
      'targets': ['anxiety', 'stress'],
      'rating': 4.7,
      'description': 'Calm your mind and reduce anxiety with gentle guidance.',
      'audioUrl': 'https://example.com/anxiety_relief.mp3',
      'imageUrl':
          'https://images.unsplash.com/photo-1499209974431-9dddcece7f88?w=500',
    },
    {
      'id': '4',
      'title': 'Mood Boost Meditation',
      'category': 'Depression',
      'duration': '12 min',
      'difficulty': 'Beginner',
      'targets': ['depression', 'general_wellness'],
      'rating': 4.6,
      'description': 'Uplift your spirits and cultivate positive emotions.',
      'audioUrl': 'https://example.com/mood_boost.mp3',
      'imageUrl':
          'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=500',
    },
  ];

  static Future<List<MeditationRecommendation>> getRecommendations({
    required String conversationText,
    UserPreferences? userPreferences,
  }) async {
    try {
      // Step 1: Analyze mental state from conversation
      MentalState mentalState =
          MentalStateAnalyzer.analyzeText(conversationText);

      // Step 2: Use default preferences if none provided
      UserPreferences preferences = userPreferences ?? _getDefaultPreferences();

      // Step 3: Generate recommendations
      List<MeditationRecommendation> recommendations =
          RecommendationEngine.generateRecommendations(
        mentalState: mentalState,
        userPreferences: preferences,
        allMeditations: _sampleMeditations,
        maxRecommendations: 5,
      );

      return recommendations;
    } catch (error) {
      print('Error generating recommendations: $error');
      return _getFallbackRecommendations();
    }
  }

  static UserPreferences _getDefaultPreferences() {
    return UserPreferences(
      preferredTypes: ['Mindfulness', 'Stress Relief'],
      preferredDurations: ['10 min', '15 min'],
      experienceLevel: 'Beginner',
      recentSessions: [],
      pastRatings: {},
      completionRates: {},
      lastUpdated: DateTime.now(),
    );
  }

  static List<MeditationRecommendation> _getFallbackRecommendations() {
    // Return basic recommendations if algorithm fails
    return _sampleMeditations.take(3).map((meditation) {
      return MeditationRecommendation(
        meditation: meditation,
        totalScore: 0.7,
        relevanceScore: 0.7,
        personalizationScore: 0.5,
        effectivenessScore: 0.8,
        varietyScore: 0.6,
        explanation:
            'This meditation is generally helpful for mental wellness.',
        benefits: [
          'Improves overall wellbeing',
          'Reduces stress',
          'Builds mindfulness'
        ],
      );
    }).toList();
  }

  static Future<void> trackRecommendationAcceptance({
    required String meditationId,
    required bool wasAccepted,
    double? userRating,
  }) async {
    // Track which recommendations users accept/reject
    // This data would be used to improve the algorithm
    print(
        'Tracking: Meditation $meditationId was ${wasAccepted ? 'accepted' : 'rejected'}');
    if (userRating != null) {
      print('User rated it: $userRating/5');
    }

    // In a real app, you'd save this to a database
    // and use it to adjust the algorithm weights
  }
}
