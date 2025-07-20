from rest_framework import serializers
from .models import (
    Meditation, MeditationRecommendation, UserMeditationProfile,
    MeditationSession, UserMentalStateAnalysis, ExternalContentUsage
)

class MeditationSerializer(serializers.ModelSerializer):
    is_external = serializers.ReadOnlyField()
    playable_url = serializers.ReadOnlyField()
    source_display = serializers.CharField(source='get_source_display', read_only=True)
    type_display = serializers.CharField(source='get_type_display', read_only=True)
    level_display = serializers.CharField(source='get_level_display', read_only=True)
    
    class Meta:
        model = Meditation
        fields = '__all__'

class MentalStateAnalysisSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserMentalStateAnalysis
        fields = '__all__'

class RecommendationSerializer(serializers.ModelSerializer):
    meditation = MeditationSerializer(read_only=True)
    mental_state_analysis = MentalStateAnalysisSerializer(read_only=True)
    
    class Meta:
        model = MeditationRecommendation
        fields = '__all__'

class MeditationSessionSerializer(serializers.ModelSerializer):
    meditation = MeditationSerializer(read_only=True)
    mood_improvement = serializers.ReadOnlyField()
    
    class Meta:
        model = MeditationSession
        fields = '__all__'

class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserMeditationProfile
        fields = '__all__'
        read_only_fields = ('user', 'total_sessions', 'total_minutes', 'consecutive_days')

class ExternalContentUsageSerializer(serializers.ModelSerializer):
    meditation = MeditationSerializer(read_only=True)
    
    class Meta:
        model = ExternalContentUsage
        fields = '__all__'