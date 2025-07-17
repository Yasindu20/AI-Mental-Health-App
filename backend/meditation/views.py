from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import models
from django.utils import timezone
from datetime import datetime, timedelta
from .models import (
    Meditation, MeditationRecommendation, UserMeditationProfile,
    MeditationSession, UserMentalStateAnalysis
)
from .serializers import (
    MeditationSerializer, RecommendationSerializer,
    MeditationSessionSerializer, UserProfileSerializer
)
from ai_engine.mental_state_analyzer import MentalStateAnalyzer
from .recommendation_engine import recommendation_engine

class MeditationViewSet(viewsets.ReadOnlyModelViewSet):
    """Browse and search meditations"""
    serializer_class = MeditationSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = Meditation.objects.all()
        
        # Filter by type
        meditation_type = self.request.query_params.get('type')
        if meditation_type:
            queryset = queryset.filter(type=meditation_type)
        
        # Filter by level
        level = self.request.query_params.get('level')
        if level:
            queryset = queryset.filter(level=level)
        
        # Filter by duration
        max_duration = self.request.query_params.get('max_duration')
        if max_duration:
            queryset = queryset.filter(duration_minutes__lte=int(max_duration))
        
        # Filter by mental state
        target_state = self.request.query_params.get('target_state')
        if target_state:
            queryset = queryset.filter(target_states__contains=target_state)
        
        return queryset
    
    @action(detail=True, methods=['post'])
    def start_session(self, request, pk=None):
        """Start a meditation session"""
        meditation = self.get_object()
        profile, _ = UserMeditationProfile.objects.get_or_create(
            user=request.user
        )
        
        # Get pre-mood score
        pre_mood = request.data.get('mood_score', 5)
        
        session = MeditationSession.objects.create(
            user_profile=profile,
            meditation=meditation,
            started_at=timezone.now(),
            pre_mood_score=pre_mood
        )
        
        # Mark recommendation as started
        MeditationRecommendation.objects.filter(
            user=request.user,
            meditation=meditation,
            started=False
        ).update(started=True, viewed=True)
        
        return Response({
            'session_id': session.id,
            'meditation': MeditationSerializer(meditation).data,
            'personalized_script': meditation.script or "Begin by finding a comfortable position..."
        })

class RecommendationViewSet(viewsets.ModelViewSet):
    """Get personalized meditation recommendations"""
    serializer_class = RecommendationSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return MeditationRecommendation.objects.filter(
            user=self.request.user
        ).select_related('meditation')
    
    @action(detail=False, methods=['post'])
    def generate(self, request):
        """Generate new recommendations based on current conversation"""
        conversation_id = request.data.get('conversation_id')
        
        if not conversation_id:
            return Response(
                {'error': 'conversation_id required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get conversation
        from chat.models import Conversation
        try:
            conversation = Conversation.objects.get(
                id=conversation_id,
                user=request.user
            )
        except Conversation.DoesNotExist:
            return Response(
                {'error': 'Conversation not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Analyze mental state
        analyzer = MentalStateAnalyzer()
        messages = [
            {
                'content': msg.content,
                'is_user': msg.is_user
            }
            for msg in conversation.messages.all()
        ]
        
        analysis_data = analyzer.analyze_conversation(messages)
        
        # Create mental state analysis record
        analysis = UserMentalStateAnalysis.objects.create(
            user=request.user,
            conversation=conversation,
            **analysis_data
        )
        
        # Generate recommendations
        recommendations = recommendation_engine.generate_recommendations(
            request.user, analysis, count=5
        )
        
        # Serialize and return
        serializer = RecommendationSerializer(recommendations, many=True)
        return Response({
            'analysis': {
                'primary_concern': analysis.primary_concern,
                'severity_score': analysis.severity_score,
                'emotional_tone': analysis.emotional_tone
            },
            'recommendations': serializer.data
        })
    
    @action(detail=True, methods=['post'])
    def feedback(self, request, pk=None):
        """Provide feedback on a recommendation"""
        recommendation = self.get_object()
        
        rating = request.data.get('rating')
        feedback = request.data.get('feedback', '')
        helpful = request.data.get('helpful')
        
        if rating:
            recommendation.user_rating = rating
        if helpful is not None:
            recommendation.helpful = helpful
        recommendation.feedback = feedback
        recommendation.save()
        
        # Update meditation effectiveness score
        meditation = recommendation.meditation
        avg_rating = MeditationRecommendation.objects.filter(
            meditation=meditation,
            user_rating__isnull=False
        ).aggregate(avg=models.Avg('user_rating'))['avg'] or 3
        
        meditation.effectiveness_score = avg_rating / 5.0
        meditation.save()
        
        return Response({'message': 'Feedback recorded'})

class MeditationSessionViewSet(viewsets.ModelViewSet):
    """Track meditation sessions"""
    serializer_class = MeditationSessionSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        profile, _ = UserMeditationProfile.objects.get_or_create(user=self.request.user)
        return MeditationSession.objects.filter(
            user_profile=profile
        ).select_related('meditation')
    
    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        """Complete a meditation session"""
        session = self.get_object()
        
        # Update session
        session.completed_at = timezone.now()
        session.post_mood_score = request.data.get('mood_score', 5)
        session.completion_percentage = request.data.get('completion_percentage', 100)
        session.helpful = request.data.get('helpful')
        session.notes = request.data.get('notes', '')
        
        # Calculate duration
        duration = (session.completed_at - session.started_at).total_seconds()
        session.duration_seconds = int(duration)
        session.save()
        
        # Update user profile
        profile = session.user_profile
        profile.total_sessions += 1
        profile.total_minutes += session.duration_seconds // 60
        
        # Update streak
        today = timezone.now().date()
        if profile.last_session_date:
            if profile.last_session_date == today - timedelta(days=1):
                profile.consecutive_days += 1
            elif profile.last_session_date != today:
                profile.consecutive_days = 1
        else:
            profile.consecutive_days = 1
        
        profile.last_session_date = today
        profile.update_level()  # Auto-update level
        profile.save()
        
        # Mark recommendation as completed
        MeditationRecommendation.objects.filter(
            user=request.user,
            meditation=session.meditation,
            completed=False
        ).update(completed=True)
        
        # Calculate mood improvement
        mood_improvement = session.mood_improvement
        
        return Response({
            'session_stats': {
                'duration_minutes': session.duration_seconds // 60,
                'mood_improvement': mood_improvement,
                'completion_percentage': session.completion_percentage
            },
            'profile_stats': {
                'total_sessions': profile.total_sessions,
                'total_minutes': profile.total_minutes,
                'current_streak': profile.consecutive_days,
                'current_level': profile.current_level
            }
        })

class UserMeditationProfileViewSet(viewsets.ModelViewSet):
    """Manage user meditation profile and preferences"""
    serializer_class = UserProfileSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return UserMeditationProfile.objects.filter(user=self.request.user)
    
    def get_object(self):
        profile, _ = UserMeditationProfile.objects.get_or_create(
            user=self.request.user
        )
        return profile
    
    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Get detailed user statistics"""
        profile = self.get_object()
        
        # Calculate various stats
        total_sessions = MeditationSession.objects.filter(
            user_profile=profile,
            completed_at__isnull=False
        )
        
        # Mood improvement stats
        mood_improvements = []
        for session in total_sessions:
            if session.mood_improvement is not None:
                mood_improvements.append(session.mood_improvement)
        
        avg_mood_improvement = sum(mood_improvements) / len(mood_improvements) if mood_improvements else 0
        
        # Most effective meditation types
        type_effectiveness = {}
        meditation_types = Meditation.objects.values_list('type', flat=True).distinct()
        for meditation_type in meditation_types:
            type_sessions = total_sessions.filter(meditation__type=meditation_type)
            if type_sessions.exists():
                type_improvements = [
                    s.mood_improvement for s in type_sessions 
                    if s.mood_improvement is not None
                ]
                if type_improvements:
                    type_effectiveness[meditation_type] = sum(type_improvements) / len(type_improvements)
        
        # Favorite time of day
        hour_counts = {}
        for session in total_sessions:
            hour = session.started_at.hour
            hour_counts[hour] = hour_counts.get(hour, 0) + 1
        
        favorite_hour = max(hour_counts, key=hour_counts.get) if hour_counts else None
        
        completion_rate = (
            total_sessions.filter(completion_percentage__gte=80).count() / total_sessions.count()
        ) if total_sessions.count() > 0 else 0
        
        return Response({
            'total_sessions': profile.total_sessions,
            'total_minutes': profile.total_minutes,
            'current_streak': profile.consecutive_days,
            'current_level': profile.current_level,
            'avg_mood_improvement': round(avg_mood_improvement, 2),
            'most_effective_types': type_effectiveness,
            'favorite_time': favorite_hour,
            'completion_rate': round(completion_rate * 100, 2)
        })
    
    @action(detail=False, methods=['post'])
    def update_preferences(self, request):
        """Update user preferences"""
        profile = self.get_object()
        
        serializer = UserProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response({'message': 'Preferences updated'})
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)