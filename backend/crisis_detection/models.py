from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone

class CrisisLevel(models.TextChoices):
    """Crisis severity levels for graduated response"""
    CONCERN = 'concern', 'Concern - Needs support'
    WARNING = 'warning', 'Warning - Needs resources'
    CRITICAL = 'critical', 'Critical - Needs immediate help'
    EMERGENCY = 'emergency', 'Emergency - Life threatening'

class CrisisResource(models.Model):
    """Local and national crisis resources"""
    name = models.CharField(max_length=200)
    phone_number = models.CharField(max_length=50)
    text_number = models.CharField(max_length=50, blank=True)
    website = models.URLField(blank=True)
    description = models.TextField()
    country = models.CharField(max_length=2, default='US')  # ISO country code
    is_24_7 = models.BooleanField(default=True)
    languages = models.JSONField(default=list)  # ['en', 'es', etc.]
    specialties = models.JSONField(default=list)  # ['suicide', 'domestic_violence', etc.]
    
    class Meta:
        ordering = ['country', 'name']
    
    def __str__(self):
        return f"{self.name} ({self.country})"

class UserEmergencyContact(models.Model):
    """User's personal emergency contacts"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='emergency_contacts')
    name = models.CharField(max_length=100)
    relationship = models.CharField(max_length=50)  # friend, family, therapist, etc.
    phone_number = models.CharField(max_length=50)
    email = models.EmailField(blank=True)
    is_primary = models.BooleanField(default=False)
    notes = models.TextField(blank=True)
    
    class Meta:
        ordering = ['-is_primary', 'name']
    
    def __str__(self):
        return f"{self.name} ({self.relationship}) - {self.user.username}"

class CrisisDetection(models.Model):
    """Log of crisis detections for analysis and improvement"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='crisis_detections')
    message = models.TextField()
    detected_level = models.CharField(max_length=20, choices=CrisisLevel.choices)
    confidence_score = models.FloatField()  # 0.0 to 1.0
    context_factors = models.JSONField()  # Factors that influenced detection
    response_provided = models.TextField()
    user_feedback = models.CharField(max_length=20, blank=True)  # helpful/not_helpful/inappropriate
    created_at = models.DateTimeField(auto_now_add=True)
    false_positive = models.BooleanField(default=False)
    
    class Meta:
        ordering = ['-created_at']

class UserCrisisProfile(models.Model):
    """User's crisis-related preferences and history"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='crisis_profile')
    preferred_contact_method = models.CharField(max_length=20, default='text')  # text/call/chat
    has_safety_plan = models.BooleanField(default=False)
    safety_plan = models.TextField(blank=True)
    triggers = models.JSONField(default=list)
    coping_strategies = models.JSONField(default=list)
    support_network = models.JSONField(default=dict)
    last_crisis_check = models.DateTimeField(null=True, blank=True)
    opt_out_auto_intervention = models.BooleanField(default=False)