// frontend/lib/models/meditation_models.dart
class Meditation {
  final int id;
  final String name;
  final String type;
  final String level;
  final int durationMinutes;
  final String description;
  final List<String> instructions;
  final List<String> benefits;
  final List<String> targetStates;
  final String? audioUrl;
  final String? videoUrl;
  final List<String> tags;
  final double effectivenessScore;

  Meditation({
    required this.id,
    required this.name,
    required this.type,
    required this.level,
    required this.durationMinutes,
    required this.description,
    required this.instructions,
    required this.benefits,
    required this.targetStates,
    this.audioUrl,
    this.videoUrl,
    required this.tags,
    required this.effectivenessScore,
  });

  factory Meditation.fromJson(Map<String, dynamic> json) {
    return Meditation(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      level: json['level'],
      durationMinutes: json['duration_minutes'],
      description: json['description'],
      instructions: List<String>.from(json['instructions']),
      benefits: List<String>.from(json['benefits']),
      targetStates: List<String>.from(json['target_states']),
      audioUrl: json['audio_url'],
      videoUrl: json['video_url'],
      tags: List<String>.from(json['tags']),
      effectivenessScore: json['effectiveness_score'].toDouble(),
    );
  }
}

class MentalStateAnalysis {
  final String primaryConcern;
  final List<String> secondaryConcerns;
  final double severityScore;
  final String emotionalTone;
  final double anxietyLevel;
  final double depressionLevel;
  final double stressLevel;

  MentalStateAnalysis({
    required this.primaryConcern,
    required this.secondaryConcerns,
    required this.severityScore,
    required this.emotionalTone,
    required this.anxietyLevel,
    required this.depressionLevel,
    required this.stressLevel,
  });

  factory MentalStateAnalysis.fromJson(Map<String, dynamic> json) {
    return MentalStateAnalysis(
      primaryConcern: json['primary_concern'],
      secondaryConcerns: List<String>.from(json['secondary_concerns']),
      severityScore: json['severity_score'].toDouble(),
      emotionalTone: json['emotional_tone'],
      anxietyLevel: json['anxiety_level'].toDouble(),
      depressionLevel: json['depression_level'].toDouble(),
      stressLevel: json['stress_level'].toDouble(),
    );
  }
}

class MeditationRecommendation {
  final int id;
  final Meditation meditation;
  final MentalStateAnalysis? analysis;
  final double relevanceScore;
  final double personalizationScore;
  final DateTime recommendedAt;
  final String reason;
  final bool viewed;
  final bool started;
  final bool completed;
  final int? userRating;

  MeditationRecommendation({
    required this.id,
    required this.meditation,
    this.analysis,
    required this.relevanceScore,
    required this.personalizationScore,
    required this.recommendedAt,
    required this.reason,
    required this.viewed,
    required this.started,
    required this.completed,
    this.userRating,
  });

  factory MeditationRecommendation.fromJson(Map<String, dynamic> json) {
    return MeditationRecommendation(
      id: json['id'],
      meditation: Meditation.fromJson(json['meditation']),
      analysis: json['mental_state_analysis'] != null
          ? MentalStateAnalysis.fromJson(json['mental_state_analysis'])
          : null,
      relevanceScore: json['relevance_score'].toDouble(),
      personalizationScore: json['personalization_score'].toDouble(),
      recommendedAt: DateTime.parse(json['recommended_at']),
      reason: json['reason'],
      viewed: json['viewed'],
      started: json['started'],
      completed: json['completed'],
      userRating: json['user_rating'],
    );
  }
}

class MeditationSession {
  final int id;
  final Meditation meditation;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int durationSeconds;
  final int preMoodScore;
  final int? postMoodScore;
  final int? moodImprovement;
  final double completionPercentage;
  final bool? helpful;
  final String notes;

  MeditationSession({
    required this.id,
    required this.meditation,
    required this.startedAt,
    this.completedAt,
    required this.durationSeconds,
    required this.preMoodScore,
    this.postMoodScore,
    this.moodImprovement,
    required this.completionPercentage,
    this.helpful,
    required this.notes,
  });

  factory MeditationSession.fromJson(Map<String, dynamic> json) {
    return MeditationSession(
      id: json['id'],
      meditation: Meditation.fromJson(json['meditation']),
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      durationSeconds: json['duration_seconds'],
      preMoodScore: json['pre_mood_score'],
      postMoodScore: json['post_mood_score'],
      moodImprovement: json['mood_improvement'],
      completionPercentage: json['completion_percentage'].toDouble(),
      helpful: json['helpful'],
      notes: json['notes'] ?? '',
    );
  }
}

class UserMeditationStats {
  final int totalSessions;
  final int totalMinutes;
  final int currentStreak;
  final String currentLevel;
  final double avgMoodImprovement;
  final Map<String, double> mostEffectiveTypes;
  final int favoriteTime;
  final double completionRate;

  UserMeditationStats({
    required this.totalSessions,
    required this.totalMinutes,
    required this.currentStreak,
    required this.currentLevel,
    required this.avgMoodImprovement,
    required this.mostEffectiveTypes,
    required this.favoriteTime,
    required this.completionRate,
  });

  factory UserMeditationStats.fromJson(Map<String, dynamic> json) {
    return UserMeditationStats(
      totalSessions: json['total_sessions'],
      totalMinutes: json['total_minutes'],
      currentStreak: json['current_streak'],
      currentLevel: json['current_level'],
      avgMoodImprovement: json['avg_mood_improvement'].toDouble(),
      mostEffectiveTypes: Map<String, double>.from(
        json['most_effective_types'].map(
          (k, v) => MapEntry(k, v.toDouble()),
        ),
      ),
      favoriteTime: json['favorite_time'],
      completionRate: json['completion_rate'].toDouble(),
    );
  }
}
