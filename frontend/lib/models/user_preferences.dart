class UserPreferences {
  final List<String> preferredTypes;
  final List<String> preferredDurations;
  final String experienceLevel;
  final List<String> recentSessions;
  final Map<String, double> pastRatings;
  final Map<String, int> completionRates;
  final DateTime lastUpdated;

  const UserPreferences({
    required this.preferredTypes,
    required this.preferredDurations,
    required this.experienceLevel,
    required this.recentSessions,
    required this.pastRatings,
    required this.completionRates,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'preferredTypes': preferredTypes,
      'preferredDurations': preferredDurations,
      'experienceLevel': experienceLevel,
      'recentSessions': recentSessions,
      'pastRatings': pastRatings,
      'completionRates': completionRates,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      preferredTypes: List<String>.from(json['preferredTypes']),
      preferredDurations: List<String>.from(json['preferredDurations']),
      experienceLevel: json['experienceLevel'],
      recentSessions: List<String>.from(json['recentSessions']),
      pastRatings: Map<String, double>.from(json['pastRatings']),
      completionRates: Map<String, int>.from(json['completionRates']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}
