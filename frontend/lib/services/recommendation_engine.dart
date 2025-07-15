import '../models/mental_state.dart';
import '../models/user_preferences.dart';
import '../models/meditation_recommendation.dart';

class RecommendationEngine {
  // Weight constants for scoring
  static const double _relevanceWeight = 0.35;
  static const double _personalizationWeight = 0.25;
  static const double _effectivenessWeight = 0.20;
  static const double _varietyWeight = 0.20;

  static List<MeditationRecommendation> generateRecommendations({
    required MentalState mentalState,
    required UserPreferences userPreferences,
    required List<Map<String, dynamic>> allMeditations,
    int maxRecommendations = 5,
  }) {
    // Step 1: Filter candidate meditations
    List<Map<String, dynamic>> candidates = _filterCandidates(
      allMeditations,
      mentalState,
      userPreferences,
    );

    // Step 2: Score each candidate
    List<MeditationRecommendation> scoredRecommendations = [];

    for (Map<String, dynamic> meditation in candidates) {
      double relevanceScore = _calculateRelevanceScore(meditation, mentalState);
      double personalizationScore =
          _calculatePersonalizationScore(meditation, userPreferences);
      double effectivenessScore =
          _calculateEffectivenessScore(meditation, userPreferences);
      double varietyScore = _calculateVarietyScore(meditation, userPreferences);

      // Calculate weighted total
      double totalScore = (_relevanceWeight * relevanceScore) +
          (_personalizationWeight * personalizationScore) +
          (_effectivenessWeight * effectivenessScore) +
          (_varietyWeight * varietyScore);

      // Generate explanation
      String explanation =
          _generateExplanation(meditation, mentalState, totalScore);
      List<String> benefits = _generateBenefits(meditation, mentalState);

      scoredRecommendations.add(MeditationRecommendation(
        meditation: meditation,
        totalScore: totalScore,
        relevanceScore: relevanceScore,
        personalizationScore: personalizationScore,
        effectivenessScore: effectivenessScore,
        varietyScore: varietyScore,
        explanation: explanation,
        benefits: benefits,
      ));
    }

    // Step 3: Sort by total score and return top recommendations
    scoredRecommendations.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return scoredRecommendations.take(maxRecommendations).toList();
  }

  static List<Map<String, dynamic>> _filterCandidates(
    List<Map<String, dynamic>> allMeditations,
    MentalState mentalState,
    UserPreferences userPreferences,
  ) {
    return allMeditations.where((meditation) {
      // Filter by targeting the mental state concerns
      List<String> targetConcerns =
          List<String>.from(meditation['targets'] ?? []);
      bool targetsMainConcern =
          targetConcerns.contains(mentalState.primaryConcern);
      bool targetsSecondaryConcern = mentalState.secondaryConcerns
          .any((concern) => targetConcerns.contains(concern));

      // Filter by experience level
      String meditationLevel = meditation['difficulty'] ?? 'Beginner';
      bool appropriateLevel =
          _isAppropriateLevel(meditationLevel, userPreferences.experienceLevel);

      return (targetsMainConcern || targetsSecondaryConcern) &&
          appropriateLevel;
    }).toList();
  }

  static bool _isAppropriateLevel(String meditationLevel, String userLevel) {
    Map<String, int> levelOrder = {
      'Beginner': 1,
      'Intermediate': 2,
      'Advanced': 3
    };
    int userLevelNum = levelOrder[userLevel] ?? 1;
    int meditationLevelNum = levelOrder[meditationLevel] ?? 1;

    // Allow same level or up to one level higher
    return meditationLevelNum <= userLevelNum + 1;
  }

  static double _calculateRelevanceScore(
    Map<String, dynamic> meditation,
    MentalState mentalState,
  ) {
    double score = 0.0;
    List<String> targets = List<String>.from(meditation['targets'] ?? []);

    // Match with primary concern: +0.5
    if (targets.contains(mentalState.primaryConcern)) {
      score += 0.5;
    }

    // Match with secondary concerns: +0.2 each
    for (String concern in mentalState.secondaryConcerns) {
      if (targets.contains(concern)) {
        score += 0.2;
      }
    }

    // Appropriate duration for severity: +0.2
    String duration = meditation['duration'] ?? '10 min';
    int durationMinutes = int.tryParse(duration.replaceAll(' min', '')) ?? 10;

    if (mentalState.urgencyLevel == 'high' && durationMinutes >= 15) {
      score += 0.2;
    } else if (mentalState.urgencyLevel == 'medium' && durationMinutes >= 10) {
      score += 0.2;
    } else if (mentalState.urgencyLevel == 'low' && durationMinutes >= 5) {
      score += 0.2;
    }

    return score.clamp(0.0, 1.0);
  }

  static double _calculatePersonalizationScore(
    Map<String, dynamic> meditation,
    UserPreferences userPreferences,
  ) {
    double score = 0.0;

    // Matches preferred types: +0.3
    String category = meditation['category'] ?? '';
    if (userPreferences.preferredTypes.contains(category)) {
      score += 0.3;
    }

    // Matches preferred duration: +0.2
    String duration = meditation['duration'] ?? '';
    if (userPreferences.preferredDurations.contains(duration)) {
      score += 0.2;
    }

    // Past positive experiences: +0.3
    String meditationId = meditation['id'] ?? '';
    if (userPreferences.pastRatings.containsKey(meditationId)) {
      double pastRating = userPreferences.pastRatings[meditationId]!;
      if (pastRating >= 4.0) {
        score += 0.3;
      }
    }

    // User level match: +0.2
    String difficulty = meditation['difficulty'] ?? 'Beginner';
    if (difficulty == userPreferences.experienceLevel) {
      score += 0.2;
    }

    return score.clamp(0.0, 1.0);
  }

  static double _calculateEffectivenessScore(
    Map<String, dynamic> meditation,
    UserPreferences userPreferences,
  ) {
    double score = 0.0;

    // General effectiveness rating
    double rating = meditation['rating']?.toDouble() ?? 4.0;
    score += (rating / 5.0) * 0.5;

    // User's past mood improvements
    String meditationId = meditation['id'] ?? '';
    if (userPreferences.pastRatings.containsKey(meditationId)) {
      double pastRating = userPreferences.pastRatings[meditationId]!;
      score += (pastRating / 5.0) * 0.3;
    }

    // Completion rates
    if (userPreferences.completionRates.containsKey(meditationId)) {
      int completionRate = userPreferences.completionRates[meditationId]!;
      score += (completionRate / 100.0) * 0.2;
    }

    return score.clamp(0.0, 1.0);
  }

  static double _calculateVarietyScore(
    Map<String, dynamic> meditation,
    UserPreferences userPreferences,
  ) {
    double score = 0.0;
    String meditationId = meditation['id'] ?? '';

    // Not recently practiced: +0.5
    if (!userPreferences.recentSessions.contains(meditationId)) {
      score += 0.5;
    }

    // Different type from recent: +0.3
    String category = meditation['category'] ?? '';
    List<String> recentCategories = [];

    // In a real implementation, you would map recent session IDs to their categories
    // For now, we'll assume it's different if we don't have recent data
    bool isDifferentType =
        recentCategories.isEmpty || !recentCategories.contains(category);

    if (isDifferentType) {
      score += 0.3;
    }

    // New to user: +0.2
    if (!userPreferences.pastRatings.containsKey(meditationId)) {
      score += 0.2;
    }

    return score.clamp(0.0, 1.0);
  }

  static String _generateExplanation(
    Map<String, dynamic> meditation,
    MentalState mentalState,
    double score,
  ) {
    String title = meditation['title'] ?? 'This meditation';
    String primaryConcern = mentalState.primaryConcern.replaceAll('_', ' ');

    if (score > 0.8) {
      return '$title is highly recommended for your current $primaryConcern. '
          'It\'s specifically designed to address your needs and matches your preferences perfectly.';
    } else if (score > 0.6) {
      return '$title is a great choice for managing $primaryConcern. '
          'This meditation has helped many users in similar situations.';
    } else {
      return '$title could be beneficial for your $primaryConcern. '
          'While not a perfect match, it offers valuable techniques for your situation.';
    }
  }

  static List<String> _generateBenefits(
    Map<String, dynamic> meditation,
    MentalState mentalState,
  ) {
    List<String> benefits = [];
    String primaryConcern = mentalState.primaryConcern;

    // Add benefits based on the primary concern
    switch (primaryConcern) {
      case 'stress':
        benefits.addAll([
          'Reduces cortisol levels and physical tension',
          'Improves stress management skills',
          'Promotes relaxation response',
        ]);
        break;
      case 'anxiety':
        benefits.addAll([
          'Calms racing thoughts and worries',
          'Teaches breathing techniques for anxiety',
          'Builds confidence and emotional stability',
        ]);
        break;
      case 'depression':
        benefits.addAll([
          'Improves mood and emotional regulation',
          'Increases self-compassion and positivity',
          'Builds resilience and coping skills',
        ]);
        break;
      case 'insomnia':
        benefits.addAll([
          'Prepares mind and body for restful sleep',
          'Reduces nighttime anxiety and racing thoughts',
          'Improves sleep quality and duration',
        ]);
        break;
      case 'anger':
        benefits.addAll([
          'Develops emotional regulation skills',
          'Reduces reactive responses',
          'Promotes patience and understanding',
        ]);
        break;
      default:
        benefits.addAll([
          'Improves overall mental wellbeing',
          'Increases mindfulness and awareness',
          'Builds meditation skills and practice',
        ]);
    }

    return benefits;
  }
}
