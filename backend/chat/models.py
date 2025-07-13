from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
import json

class ConversationMode(models.TextChoices):
    UNSTRUCTURED = 'unstructured', 'Unstructured Conversation'
    CBT_EXERCISE = 'cbt_exercise', 'CBT Exercise'
    MINDFULNESS = 'mindfulness', 'Mindfulness Exercise'
    MOOD_CHECK = 'mood_check', 'Mood Check-in'

class Conversation(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='conversations')
    mode = models.CharField(max_length=20, choices=ConversationMode.choices, default=ConversationMode.UNSTRUCTURED)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)
    
    class Meta:
        ordering = ['-updated_at']
    
    def __str__(self):
        return f"{self.user.username} - {self.mode} - {self.created_at}"

class Message(models.Model):
    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, related_name='messages')
    content = models.TextField()
    is_user = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    emotion_detected = models.CharField(max_length=50, blank=True)
    
    class Meta:
        ordering = ['created_at']
    
    def __str__(self):
        sender = "User" if self.is_user else "AI"
        return f"{sender}: {self.content[:50]}..."

class UserContext(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='context')
    mood_history = models.JSONField(default=list)  # List of mood entries
    preferences = models.JSONField(default=dict)   # User preferences
    triggers = models.JSONField(default=list)      # Known triggers
    coping_strategies = models.JSONField(default=list)  # Effective strategies
    personality_traits = models.JSONField(default=dict)  # AI personality settings
    last_mood_check = models.DateTimeField(null=True, blank=True)
    
    def add_mood_entry(self, mood, score):
        self.mood_history.append({
            'mood': mood,
            'score': score,
            'timestamp': timezone.now().isoformat()
        })
        self.save()
    
    def __str__(self):
        return f"Context for {self.user.username}"