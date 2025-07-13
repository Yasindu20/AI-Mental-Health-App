from rest_framework import serializers
from .models import CrisisResource, UserEmergencyContact, CrisisDetection, UserCrisisProfile

class CrisisResourceSerializer(serializers.ModelSerializer):
    class Meta:
        model = CrisisResource
        fields = ['id', 'name', 'phone_number', 'text_number', 'website', 
                 'description', 'country', 'is_24_7', 'languages', 'specialties']

class UserEmergencyContactSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserEmergencyContact
        fields = ['id', 'name', 'relationship', 'phone_number', 'email', 
                 'is_primary', 'notes']

class CrisisDetectionSerializer(serializers.ModelSerializer):
    class Meta:
        model = CrisisDetection
        fields = ['id', 'message', 'detected_level', 'confidence_score', 
                 'context_factors', 'response_provided', 'user_feedback', 
                 'created_at', 'false_positive']

class UserCrisisProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserCrisisProfile
        fields = ['preferred_contact_method', 'has_safety_plan', 'safety_plan',
                 'triggers', 'coping_strategies', 'support_network', 
                 'last_crisis_check', 'opt_out_auto_intervention']

class SafetyPlanSerializer(serializers.Serializer):
    warning_signs = serializers.ListField(child=serializers.CharField())
    coping_strategies = serializers.ListField(child=serializers.CharField())
    support_contacts = serializers.ListField(child=serializers.DictField())
    professional_contacts = serializers.ListField(child=serializers.DictField())
    safe_environment = serializers.ListField(child=serializers.CharField())
    reasons_for_living = serializers.ListField(child=serializers.CharField())