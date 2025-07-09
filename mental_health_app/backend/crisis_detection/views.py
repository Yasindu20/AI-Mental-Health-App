from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from django.db.models import Q
from .models import CrisisResource, UserEmergencyContact, CrisisDetection, UserCrisisProfile
from .serializers import (
    CrisisResourceSerializer, UserEmergencyContactSerializer,
    CrisisDetectionSerializer, UserCrisisProfileSerializer,
    SafetyPlanSerializer
)

class CrisisResourceViewSet(viewsets.ReadOnlyModelViewSet):
    """View crisis resources (read-only for users)"""
    serializer_class = CrisisResourceSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        # Get resources for user's country
        country = self.request.query_params.get('country', 'US')
        return CrisisResource.objects.filter(
            Q(country=country) | Q(country='INTL')  # International resources
        )
    
    @action(detail=False, methods=['get'])
    def by_specialty(self, request):
        """Get resources by specialty (suicide, domestic_violence, etc.)"""
        specialty = request.query_params.get('specialty')
        if not specialty:
            return Response({'error': 'Specialty parameter required'}, 
                          status=status.HTTP_400_BAD_REQUEST)
        
        resources = self.get_queryset().filter(specialties__contains=specialty)
        serializer = self.get_serializer(resources, many=True)
        return Response(serializer.data)

class UserEmergencyContactViewSet(viewsets.ModelViewSet):
    """Manage user's emergency contacts"""
    serializer_class = UserEmergencyContactSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return UserEmergencyContact.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        # Ensure only one primary contact
        if serializer.validated_data.get('is_primary', False):
            self.get_queryset().update(is_primary=False)
        serializer.save(user=self.request.user)
    
    def perform_update(self, serializer):
        # Ensure only one primary contact
        if serializer.validated_data.get('is_primary', False):
            self.get_queryset().exclude(pk=serializer.instance.pk).update(is_primary=False)
        serializer.save()

class UserCrisisProfileViewSet(viewsets.ModelViewSet):
    """Manage user's crisis profile and safety plan"""
    serializer_class = UserCrisisProfileSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return UserCrisisProfile.objects.filter(user=self.request.user)
    
    def get_object(self):
        # Get or create profile for user
        profile, created = UserCrisisProfile.objects.get_or_create(
            user=self.request.user
        )
        return profile
    
    @action(detail=False, methods=['post'])
    def create_safety_plan(self, request):
        """Create or update safety plan"""
        serializer = SafetyPlanSerializer(data=request.data)
        if serializer.is_valid():
            profile = self.get_object()
            profile.safety_plan = serializer.validated_data
            profile.has_safety_plan = True
            profile.save()
            return Response({'message': 'Safety plan saved successfully'})
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def check_crisis(self, request):
        """Check if user needs crisis intervention based on recent patterns"""
        profile = self.get_object()
        
        # Get recent crisis detections
        recent_detections = CrisisDetection.objects.filter(
            user=request.user,
            created_at__gte=timezone.now() - timezone.timedelta(days=7)
        ).count()
        
        # Check mood patterns from user context
        context = getattr(request.user, 'context', None)
        low_mood_count = 0
        if context and context.mood_history:
            recent_moods = context.mood_history[-7:]
            low_mood_count = sum(1 for m in recent_moods if m.get('score', 10) < 4)
        
        needs_check = recent_detections > 2 or low_mood_count > 4
        
        return Response({
            'needs_crisis_check': needs_check,
            'recent_detections': recent_detections,
            'low_mood_days': low_mood_count,
            'has_safety_plan': profile.has_safety_plan,
            'last_check': profile.last_crisis_check
        })

class CrisisDetectionViewSet(viewsets.ReadOnlyModelViewSet):
    """View crisis detection history (for analysis)"""
    serializer_class = CrisisDetectionSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        # Users can only see their own detection history
        return CrisisDetection.objects.filter(user=self.request.user)
    
    @action(detail=True, methods=['post'])
    def feedback(self, request, pk=None):
        """Provide feedback on crisis detection accuracy"""
        detection = self.get_object()
        feedback = request.data.get('feedback')  # helpful/not_helpful/inappropriate
        false_positive = request.data.get('false_positive', False)
        
        detection.user_feedback = feedback
        detection.false_positive = false_positive
        detection.save()
        
        return Response({'message': 'Feedback recorded. Thank you for helping us improve.'})