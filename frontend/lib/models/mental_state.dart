class MentalState {
  final String primaryConcern;
  final List<String> secondaryConcerns;
  final double severityScore;
  final String urgencyLevel;
  final Map<String, double> emotionalKeywords;
  final DateTime analyzedAt;

  const MentalState({
    required this.primaryConcern,
    required this.secondaryConcerns,
    required this.severityScore,
    required this.urgencyLevel,
    required this.emotionalKeywords,
    required this.analyzedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'primaryConcern': primaryConcern,
      'secondaryConcerns': secondaryConcerns,
      'severityScore': severityScore,
      'urgencyLevel': urgencyLevel,
      'emotionalKeywords': emotionalKeywords,
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }

  factory MentalState.fromJson(Map<String, dynamic> json) {
    return MentalState(
      primaryConcern: json['primaryConcern'],
      secondaryConcerns: List<String>.from(json['secondaryConcerns']),
      severityScore: json['severityScore'],
      urgencyLevel: json['urgencyLevel'],
      emotionalKeywords: Map<String, double>.from(json['emotionalKeywords']),
      analyzedAt: DateTime.parse(json['analyzedAt']),
    );
  }
}
