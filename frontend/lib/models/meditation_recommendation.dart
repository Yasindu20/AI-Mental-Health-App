class MeditationRecommendation {
  final Map<String, dynamic> meditation;
  final double totalScore;
  final double relevanceScore;
  final double personalizationScore;
  final double effectivenessScore;
  final double varietyScore;
  final String explanation;
  final List<String> benefits;

  const MeditationRecommendation({
    required this.meditation,
    required this.totalScore,
    required this.relevanceScore,
    required this.personalizationScore,
    required this.effectivenessScore,
    required this.varietyScore,
    required this.explanation,
    required this.benefits,
  });

  Map<String, dynamic> toJson() {
    return {
      'meditation': meditation,
      'totalScore': totalScore,
      'relevanceScore': relevanceScore,
      'personalizationScore': personalizationScore,
      'effectivenessScore': effectivenessScore,
      'varietyScore': varietyScore,
      'explanation': explanation,
      'benefits': benefits,
    };
  }
}
