# backend/meditation/serializers.py
from rest_framework import serializers
from .models import (
    Meditation, MeditationRecommendation, UserMeditationProfile,
    MeditationSession, UserMentalStateAnalysis
)

class MeditationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Meditation
        fields = [
            'id', 'name', 'type', 'level', 'duration_minutes',
            'description', 'instructions', 'benefits', 'target_states',
            'audio_url', 'video_url', 'tags', 'effectiveness_score'
        ]

class MentalStateAnalysisSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserMentalStateAnalysis
        fields = [
            'id', 'analyzed_at', 'primary_concern', 'secondary_concerns',
            'severity_score', 'emotional_tone', 'key_themes',
            'anxiety_level', 'depression_level', 'stress_level'
        ]

class RecommendationSerializer(serializers.ModelSerializer):
    meditation = MeditationSerializer(read_only=True)
    mental_state_analysis = MentalStateAnalysisSerializer(read_only=True)
    
    class Meta:
        model = MeditationRecommendation
        fields = [
            'id', 'meditation', 'mental_state_analysis',
            'relevance_score', 'personalization_score',
            'recommended_at', 'reason', 'viewed', 'started',
            'completed', 'user_rating'
        ]

class MeditationSessionSerializer(serializers.ModelSerializer):
    meditation = MeditationSerializer(read_only=True)
    mood_improvement = serializers.ReadOnlyField()
    
    class Meta:
        model = MeditationSession
        fields = [
            'id', 'meditation', 'started_at', 'completed_at',
            'duration_seconds', 'pre_mood_score', 'post_mood_score',
            'mood_improvement', 'completion_percentage', 'helpful', 'notes'
        ]

class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserMeditationProfile
        fields = [
            'preferred_types', 'preferred_duration', 'preferred_time_of_day',
            'current_level', 'total_sessions', 'total_minutes',
            'consecutive_days', 'last_session_date'
        ]