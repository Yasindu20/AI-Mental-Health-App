import '../models/mental_state.dart';

class MentalStateAnalyzer {
  // Keywords mapped to mental states and their weights
  static const Map<String, Map<String, double>> _emotionalKeywords = {
    'stress': {
      'stressed': 0.8,
      'overwhelmed': 0.9,
      'pressure': 0.7,
      'busy': 0.5,
      'tense': 0.6,
      'worried': 0.7,
      'anxious': 0.8,
      'deadline': 0.6,
    },
    'anxiety': {
      'anxious': 0.9,
      'nervous': 0.7,
      'worried': 0.8,
      'panic': 0.9,
      'fear': 0.8,
      'scared': 0.7,
      'uneasy': 0.6,
      'restless': 0.7,
    },
    'depression': {
      'sad': 0.7,
      'depressed': 0.9,
      'lonely': 0.8,
      'hopeless': 0.9,
      'empty': 0.8,
      'worthless': 0.9,
      'tired': 0.5,
      'unmotivated': 0.7,
    },
    'insomnia': {
      'insomnia': 0.9,
      'sleepless': 0.8,
      'tired': 0.6,
      'exhausted': 0.7,
      'restless': 0.7,
      'sleep': 0.8,
      'awake': 0.6,
    },
    'anger': {
      'angry': 0.8,
      'furious': 0.9,
      'irritated': 0.7,
      'frustrated': 0.8,
      'mad': 0.8,
      'annoyed': 0.6,
      'rage': 0.9,
    },
  };

  static MentalState analyzeText(String conversationText) {
    // Convert to lowercase for analysis
    String text = conversationText.toLowerCase();

    // Calculate scores for each mental state
    Map<String, double> stateScores = {};
    Map<String, double> foundKeywords = {};

    for (String state in _emotionalKeywords.keys) {
      double score = 0.0;
      Map<String, double> keywords = _emotionalKeywords[state]!;

      for (String keyword in keywords.keys) {
        if (text.contains(keyword)) {
          double weight = keywords[keyword]!;
          score += weight;
          foundKeywords[keyword] = weight;
        }
      }

      // Normalize score (divide by max possible score for this state)
      if (keywords.isNotEmpty) {
        stateScores[state] = score / keywords.length;
      }
    }

    // Find primary concern (highest score)
    String primaryConcern = 'general_wellness';
    double maxScore = 0.0;

    for (String state in stateScores.keys) {
      if (stateScores[state]! > maxScore) {
        maxScore = stateScores[state]!;
        primaryConcern = state;
      }
    }

    // Find secondary concerns (scores > 0.3 but not primary)
    List<String> secondaryConcerns = [];
    for (String state in stateScores.keys) {
      if (state != primaryConcern && stateScores[state]! > 0.3) {
        secondaryConcerns.add(state);
      }
    }

    // Calculate overall severity
    double severityScore = maxScore;

    // Determine urgency level
    String urgencyLevel = _determineUrgencyLevel(severityScore, foundKeywords);

    return MentalState(
      primaryConcern: primaryConcern,
      secondaryConcerns: secondaryConcerns,
      severityScore: severityScore,
      urgencyLevel: urgencyLevel,
      emotionalKeywords: foundKeywords,
      analyzedAt: DateTime.now(),
    );
  }

  static String _determineUrgencyLevel(
      double severity, Map<String, double> keywords) {
    // Check for crisis keywords
    List<String> crisisKeywords = ['hopeless', 'worthless', 'panic', 'rage'];
    bool hasCrisisKeywords =
        crisisKeywords.any((keyword) => keywords.containsKey(keyword));

    if (hasCrisisKeywords || severity > 0.8) {
      return 'high';
    } else if (severity > 0.5) {
      return 'medium';
    } else {
      return 'low';
    }
  }
}
