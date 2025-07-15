# backend/meditation/models.py
from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
import json

class MeditationType(models.TextChoices):
    MINDFULNESS = 'mindfulness', 'Mindfulness'
    BREATHING = 'breathing', 'Breathing'
    BODY_SCAN = 'body_scan', 'Body Scan'
    LOVING_KINDNESS = 'loving_kindness', 'Loving Kindness'
    TRANSCENDENTAL = 'transcendental', 'Transcendental'
    MOVEMENT = 'movement', 'Movement'
    VISUALIZATION = 'visualization', 'Visualization'
    MANTRA = 'mantra', 'Mantra'
    PROGRESSIVE_RELAXATION = 'progressive_relaxation', 'Progressive Relaxation'
    ZEN = 'zen', 'Zen'
    CHAKRA = 'chakra', 'Chakra'
    SOUND_BATH = 'sound_bath', 'Sound Bath'

class MentalStateCategory(models.TextChoices):
    ANXIETY = 'anxiety', 'Anxiety'
    DEPRESSION = 'depression', 'Depression'
    STRESS = 'stress', 'Stress'
    ANGER = 'anger', 'Anger'
    GRIEF = 'grief', 'Grief'
    INSOMNIA = 'insomnia', 'Insomnia'
    FOCUS = 'focus', 'Focus Issues'
    SELF_ESTEEM = 'self_esteem', 'Low Self-Esteem'
    TRAUMA = 'trauma', 'Trauma'
    PANIC = 'panic', 'Panic'
    BURNOUT = 'burnout', 'Burnout'
    LONELINESS = 'loneliness', 'Loneliness'

class Level(models.TextChoices):
    BEGINNER = 'beginner', 'Beginner'
    INTERMEDIATE = 'intermediate', 'Intermediate'
    ADVANCED = 'advanced', 'Advanced'

class Meditation(models.Model):
    """Comprehensive meditation database"""
    name = models.CharField(max_length=200)
    type = models.CharField(max_length=30, choices=MeditationType.choices)
    level = models.CharField(max_length=20, choices=Level.choices)
    duration_minutes = models.IntegerField()
    description = models.TextField()
    instructions = models.JSONField()  # Step-by-step instructions
    benefits = models.JSONField(default=list)
    target_states = models.JSONField(default=list)  # List of mental states this helps with
    audio_url = models.URLField(blank=True)
    video_url = models.URLField(blank=True)
    script = models.TextField(blank=True)  # Full meditation script
    tags = models.JSONField(default=list)
    prerequisites = models.JSONField(default=list)  # Required prior meditations
    created_at = models.DateTimeField(auto_now_add=True)
    popularity_score = models.FloatField(default=0.0)
    effectiveness_score = models.FloatField(default=0.0)
    
    class Meta:
        ordering = ['-effectiveness_score', '-popularity_score']
    
    def __str__(self):
        return f"{self.name} ({self.level} - {self.duration_minutes}min)"

class UserMentalStateAnalysis(models.Model):
    """Analysis of user's mental state from conversation"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='mental_analyses')
    conversation = models.ForeignKey('chat.Conversation', on_delete=models.CASCADE)
    analyzed_at = models.DateTimeField(auto_now_add=True)
    
    # Mental state scores (0-10)
    anxiety_level = models.FloatField(default=0)
    depression_level = models.FloatField(default=0)
    stress_level = models.FloatField(default=0)
    anger_level = models.FloatField(default=0)
    focus_issues = models.FloatField(default=0)
    
    # Detected issues
    primary_concern = models.CharField(max_length=30, choices=MentalStateCategory.choices)
    secondary_concerns = models.JSONField(default=list)
    
    # Analysis details
    emotional_tone = models.CharField(max_length=50)
    key_themes = models.JSONField(default=list)
    severity_score = models.FloatField()  # 0-10 overall severity
    confidence_score = models.FloatField()  # AI confidence in analysis
    
    # Recommendations
    recommended_meditation_types = models.JSONField(default=list)
    recommended_duration = models.IntegerField()  # minutes
    urgency_level = models.CharField(max_length=20)  # low, medium, high, critical
    
    class Meta:
        ordering = ['-analyzed_at']

class MeditationRecommendation(models.Model):
    """Personalized meditation recommendations"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='recommendations')
    meditation = models.ForeignKey(Meditation, on_delete=models.CASCADE)
    mental_state_analysis = models.ForeignKey(UserMentalStateAnalysis, on_delete=models.CASCADE)
    
    relevance_score = models.FloatField()  # How relevant to user's current state
    personalization_score = models.FloatField()  # How well it matches user preferences
    recommended_at = models.DateTimeField(auto_now_add=True)
    reason = models.TextField()  # Why this was recommended
    
    # User interaction
    viewed = models.BooleanField(default=False)
    started = models.BooleanField(default=False)
    completed = models.BooleanField(default=False)
    user_rating = models.IntegerField(null=True, blank=True)  # 1-5
    feedback = models.TextField(blank=True)
    
    class Meta:
        ordering = ['-recommended_at', '-relevance_score']

class UserMeditationProfile(models.Model):
    """User's meditation preferences and history"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='meditation_profile')
    
    # Preferences
    preferred_types = models.JSONField(default=list)
    preferred_duration = models.IntegerField(default=10)  # minutes
    preferred_time_of_day = models.CharField(max_length=20, default='morning')
    
    # Progress
    current_level = models.CharField(max_length=20, choices=Level.choices, default=Level.BEGINNER)
    total_sessions = models.IntegerField(default=0)
    total_minutes = models.IntegerField(default=0)
    consecutive_days = models.IntegerField(default=0)
    last_session_date = models.DateField(null=True, blank=True)
    
    # Achievements
    completed_meditations = models.ManyToManyField(Meditation, through='MeditationSession')
    favorite_meditations = models.ManyToManyField(Meditation, related_name='favorited_by')
    
    # Effectiveness tracking
    avg_mood_improvement = models.FloatField(default=0)
    most_effective_types = models.JSONField(default=dict)
    
    def update_level(self):
        """Auto-update user level based on progress"""
        if self.total_sessions >= 50 and self.total_minutes >= 500:
            self.current_level = Level.ADVANCED
        elif self.total_sessions >= 20 and self.total_minutes >= 200:
            self.current_level = Level.INTERMEDIATE
        self.save()

class MeditationSession(models.Model):
    """Track individual meditation sessions"""
    user_profile = models.ForeignKey(UserMeditationProfile, on_delete=models.CASCADE)
    meditation = models.ForeignKey(Meditation, on_delete=models.CASCADE)
    
    started_at = models.DateTimeField()
    completed_at = models.DateTimeField(null=True, blank=True)
    duration_seconds = models.IntegerField(default=0)
    
    # Pre/post mood
    pre_mood_score = models.IntegerField()  # 1-10
    post_mood_score = models.IntegerField(null=True, blank=True)  # 1-10
    
    # Session quality
    interruptions = models.IntegerField(default=0)
    completion_percentage = models.FloatField(default=0)
    
    # User feedback
    helpful = models.BooleanField(null=True)
    notes = models.TextField(blank=True)
    
    class Meta:
        ordering = ['-started_at']
    
    @property
    def mood_improvement(self):
        if self.post_mood_score and self.pre_mood_score:
            return self.post_mood_score - self.pre_mood_score
        return 0