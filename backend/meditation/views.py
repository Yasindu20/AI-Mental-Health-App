from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import models
from django.utils import timezone
from django.core.cache import cache
from datetime import datetime, timedelta
import logging

from .models import (
    Meditation, MeditationRecommendation, UserMeditationProfile,
    MeditationSession, UserMentalStateAnalysis, ExternalContentUsage,
    UserExternalPreferences, ContentSyncJob
)
from .serializers import (
    MeditationSerializer, RecommendationSerializer,
    MeditationSessionSerializer, UserProfileSerializer
)

# Import external content services - FIXED IMPORTS
try:
    from .external_apis.content_aggregator import content_aggregator
    from .external_apis.youtube_service import youtube_service
    from .external_apis.spotify_service import spotify_service
    from .external_apis.huggingface_service import huggingface_service
    EXTERNAL_APIS_AVAILABLE = True
    print("External APIs loaded successfully")
except ImportError as e:
    EXTERNAL_APIS_AVAILABLE = False
    content_aggregator = None
    print(f"External APIs not available: {e}")

# Import AI services
try:
    from ai_engine.mental_state_analyzer import MentalStateAnalyzer
    from .recommendation_engine import recommendation_engine
    AI_SERVICES_AVAILABLE = True
except ImportError:
    AI_SERVICES_AVAILABLE = False

logger = logging.getLogger(__name__)

class MeditationViewSet(viewsets.ReadOnlyModelViewSet):
    """Browse and search meditations - both internal and external"""
    serializer_class = MeditationSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'description', 'tags', 'keywords']
    ordering_fields = ['created_at', 'effectiveness_score', 'popularity_score', 'duration_minutes']
    
    def get_queryset(self):
        queryset = Meditation.objects.all()
        
        # Filter by source
        source = self.request.query_params.get('source')
        if source:
            if source == 'external':
                queryset = queryset.exclude(source='original')
            elif source == 'internal':
                queryset = queryset.filter(source='original')
            else:
                queryset = queryset.filter(source=source)
        
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
            
        min_duration = self.request.query_params.get('min_duration')
        if min_duration:
            queryset = queryset.filter(duration_minutes__gte=int(min_duration))
        
        # Filter by mental state
        target_state = self.request.query_params.get('target_state')
        if target_state:
            queryset = queryset.filter(target_states__contains=target_state)
        
        # Filter by effectiveness
        min_effectiveness = self.request.query_params.get('min_effectiveness')
        if min_effectiveness:
            queryset = queryset.filter(effectiveness_score__gte=float(min_effectiveness))
        
        # Filter free content only
        free_only = self.request.query_params.get('free_only')
        if free_only and free_only.lower() == 'true':
            queryset = queryset.filter(is_free=True)
        
        return queryset
    
    @action(detail=True, methods=['post'])
    def start_session(self, request, pk=None):
        """Start a meditation session"""
        meditation = self.get_object()
        profile, _ = UserMeditationProfile.objects.get_or_create(user=request.user)
        
        # Get pre-mood score
        pre_mood = request.data.get('mood_score', 5)
        
        session = MeditationSession.objects.create(
            user_profile=profile,
            meditation=meditation,
            started_at=timezone.now(),
            pre_mood_score=pre_mood
        )
        
        # Update meditation play count
        meditation.times_played = models.F('times_played') + 1
        meditation.save(update_fields=['times_played'])
        
        # Mark recommendation as started
        MeditationRecommendation.objects.filter(
            user=request.user,
            meditation=meditation,
            started=False
        ).update(started=True, viewed=True)
        
        return Response({
            'session_id': session.id,
            'meditation': MeditationSerializer(meditation).data,
            'personalized_script': self._get_personalized_script(meditation, request.user)
        })
    
    def _get_personalized_script(self, meditation, user):
        """Get personalized meditation script"""
        if meditation.script:
            return meditation.script
        elif meditation.instructions:
            return "\n\n".join([f"Step {i+1}: {instruction}" 
                              for i, instruction in enumerate(meditation.instructions)])
        else:
            return f"Begin your {meditation.get_type_display().lower()} meditation by finding a comfortable position..."
    
    @action(detail=False, methods=['get'])
    def external_content(self, request):
        """Get external meditation content with advanced filtering - FIXED METHOD"""
        logger.info(f"External APIs available: {EXTERNAL_APIS_AVAILABLE}")
        
        if not EXTERNAL_APIS_AVAILABLE:
            logger.error("External APIs not configured")
            return Response({
                'error': 'External APIs not configured',
                'results': [],
                'count': 0,
                'debug_info': 'Check if external API services are properly imported and configured'
            })
        
        try:
            # Get query parameters
            source = request.query_params.get('source', 'all')
            search_query = request.query_params.get('search', '')
            page = int(request.query_params.get('page', 1))
            per_page = min(int(request.query_params.get('per_page', 20)), 50)
            
            logger.info(f"Getting external content - source: {source}, query: {search_query}")
            
            # Determine sources to search
            valid_sources = ['youtube', 'spotify', 'huggingface']
            if source == 'all':
                sources = valid_sources
            else:
                sources = [source] if source in valid_sources else []
            
            if not sources:
                return Response({
                    'error': 'Invalid source specified',
                    'results': [],
                    'count': 0,
                    'valid_sources': valid_sources
                })
            
            # Get content from aggregator
            logger.info(f"Fetching content from sources: {sources}")
            if search_query:
                content = content_aggregator.search_external_content(
                    query=search_query,
                    sources=sources,
                    max_results=per_page * 2
                )
            else:
                content = content_aggregator.get_all_external_content(
                    sources=sources,
                    max_per_source=per_page
                )
            
            logger.info(f"Retrieved {len(content)} items from content aggregator")
            
            # Apply additional filters
            content = self._apply_external_filters(content, request)
            
            # Ensure consistent structure for frontend
            formatted_content = []
            for item in content:
                # Normalize the structure to match frontend expectations
                formatted_item = {
                    'id': item.get('id', f"{item.get('source', 'unknown')}_{item.get('external_id', 'unknown')}"),
                    'name': item.get('name', 'Untitled'),
                    'type': item.get('type', 'mindfulness'),
                    'level': item.get('level', 'beginner'),
                    'duration_minutes': item.get('duration_minutes', 10),
                    'description': item.get('description', ''),
                    'instructions': item.get('instructions', []),
                    'benefits': item.get('benefits', []),
                    'target_states': item.get('target_states', []),
                    'audio_url': item.get('audio_url', ''),
                    'video_url': item.get('video_url', ''),
                    'spotify_url': item.get('spotify_url', ''),
                    'thumbnail_url': item.get('thumbnail_url', ''),
                    'tags': item.get('tags', []),
                    'effectiveness_score': float(item.get('effectiveness_score', 0.5)),
                    'source': item.get('source', 'unknown'),
                    'external_id': item.get('external_id', ''),
                    'is_free': item.get('is_free', True),
                    'requires_subscription': item.get('requires_subscription', False),
                    'language': item.get('language', 'en'),
                    # External platform specific fields
                    'channel_name': item.get('channel_name', ''),
                    'artist_name': item.get('artist_name', ''),
                    'album_name': item.get('album_name', ''),
                    'view_count': item.get('view_count', 0),
                    'like_count': item.get('like_count', 0),
                    'spotify_popularity': item.get('spotify_popularity', 0),
                    'published_at': item.get('published_at', ''),
                }
                formatted_content.append(formatted_item)
            
            # Pagination
            start_idx = (page - 1) * per_page
            end_idx = start_idx + per_page
            paginated_content = formatted_content[start_idx:end_idx]
            
            result = {
                'results': paginated_content,
                'count': len(formatted_content),
                'page': page,
                'per_page': per_page,
                'has_next': end_idx < len(formatted_content),
                'sources_searched': sources,
                'debug_info': f"Successfully fetched {len(paginated_content)} items from {len(sources)} sources"
            }
            
            logger.info(f"Returning {len(paginated_content)} formatted items to frontend")
            return Response(result)
            
        except Exception as e:
            logger.error(f'Error getting external content: {str(e)}', exc_info=True)
            return Response(
                {
                    'error': 'Failed to fetch external content', 
                    'details': str(e),
                    'debug_info': 'Check logs for detailed error information',
                    'results': [],
                    'count': 0
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def _apply_external_filters(self, content, request):
        """Apply additional filters to external content"""
        # Filter by duration
        min_duration = request.query_params.get('min_duration')
        max_duration = request.query_params.get('max_duration')
        
        if min_duration or max_duration:
            filtered_content = []
            for item in content:
                duration = item.get('duration_minutes', 0)
                if min_duration and duration < int(min_duration):
                    continue
                if max_duration and duration > int(max_duration):
                    continue
                filtered_content.append(item)
            content = filtered_content
        
        # Filter by effectiveness score
        min_effectiveness = request.query_params.get('min_effectiveness')
        if min_effectiveness:
            content = [item for item in content 
                      if item.get('effectiveness_score', 0) >= float(min_effectiveness)]
        
        # Filter by type
        meditation_type = request.query_params.get('type')
        if meditation_type:
            content = [item for item in content 
                      if item.get('type', '').lower() == meditation_type.lower()]
        
        return content
    
    @action(detail=False, methods=['post'])
    def refresh_external_content(self, request):
        """Manually trigger external content refresh (admin only)"""
        if not request.user.is_staff:
            return Response(
                {'error': 'Permission denied'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        if not EXTERNAL_APIS_AVAILABLE:
            return Response({
                'error': 'External APIs not configured'
            }, status=status.HTTP_503_SERVICE_UNAVAILABLE)
        
        try:
            # Create sync job
            sync_job = ContentSyncJob.objects.create(
                source='all',
                status='running'
            )
            
            # Clear relevant caches
            cache_patterns = [
                'youtube_search_*',
                'spotify_playlists_*',
                'huggingface_meditations_*',
                'aggregated_content_*',
                'external_content_*'
            ]
            
            cleared_caches = 0
            for pattern in cache_patterns:
                try:
                    if hasattr(cache, 'delete_pattern'):
                        cache.delete_pattern(pattern)
                        cleared_caches += 1
                except Exception as e:
                    logger.warning(f'Could not clear cache pattern {pattern}: {e}')
            
            # Force refresh of content (this could be moved to a background task)
            fresh_content = content_aggregator.get_all_external_content(
                sources=['youtube', 'spotify', 'huggingface'],
                max_per_source=20
            )
            
            # Update sync job
            sync_job.status = 'completed'
            sync_job.completed_at = timezone.now()
            sync_job.total_items = len(fresh_content)
            sync_job.processed_items = len(fresh_content)
            sync_job.save()
            
            return Response({
                'message': 'Content refreshed successfully',
                'count': len(fresh_content),
                'job_id': sync_job.id,
                'caches_cleared': cleared_caches
            })
            
        except Exception as e:
            logger.error(f'Error refreshing content: {str(e)}')
            
            # Update sync job with error
            if 'sync_job' in locals():
                sync_job.status = 'failed'
                sync_job.error_message = str(e)
                sync_job.completed_at = timezone.now()
                sync_job.save()
            
            return Response(
                {'error': 'Failed to refresh content', 'details': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=False, methods=['get'])
    def personalized_external(self, request):
        """Get personalized external content recommendations"""
        if not EXTERNAL_APIS_AVAILABLE:
            return Response({'recommendations': []})
        
        try:
            # Get user preferences
            user_prefs = self._get_user_external_preferences(request.user)
            
            # Get personalized recommendations
            recommendations = content_aggregator.get_personalized_recommendations(
                user_preferences=user_prefs,
                max_results=20
            )
            
            return Response({
                'recommendations': recommendations,
                'preferences_used': user_prefs
            })
            
        except Exception as e:
            logger.error(f'Error getting personalized content: {str(e)}')
            return Response(
                {'error': 'Failed to get personalized content'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def _get_user_external_preferences(self, user) -> dict:
        """Get user preferences for external content"""
        try:
            prefs = UserExternalPreferences.objects.get(user=user)
            profile = UserMeditationProfile.objects.get(user=user)
            
            return {
                'preferred_sources': prefs.preferred_sources or ['youtube', 'spotify'],
                'preferred_types': prefs.preferred_external_types or profile.preferred_types or ['mindfulness', 'breathing'],
                'preferred_duration': (prefs.min_external_duration + prefs.max_external_duration) // 2,
                'min_effectiveness': prefs.min_effectiveness_score,
                'target_states': ['relaxation', 'stress']  # Could be derived from recent analysis
            }
        except (UserExternalPreferences.DoesNotExist, UserMeditationProfile.DoesNotExist):
            return {
                'preferred_sources': ['youtube', 'spotify'],
                'preferred_types': ['mindfulness', 'breathing'],
                'preferred_duration': 15,
                'min_effectiveness': 0.3,
                'target_states': ['relaxation']
            }
    
    @action(detail=False, methods=['get'])
    def trending(self, request):
        """Get trending meditations"""
        period = request.query_params.get('period', 'week')
        limit = min(int(request.query_params.get('limit', 10)), 50)
        
        # Calculate trending based on recent activity
        if period == 'day':
            since = timezone.now() - timedelta(days=1)
        elif period == 'month':
            since = timezone.now() - timedelta(days=30)
        else:  # week
            since = timezone.now() - timedelta(days=7)
        
        # Get meditations with recent activity
        trending_ids = MeditationSession.objects.filter(
            started_at__gte=since
        ).values('meditation').annotate(
            recent_sessions=models.Count('id'),
            avg_rating=models.Avg('post_mood_score')
        ).order_by('-recent_sessions', '-avg_rating')[:limit]
        
        meditation_ids = [item['meditation'] for item in trending_ids]
        queryset = Meditation.objects.filter(id__in=meditation_ids)
        
        # Preserve ordering
        preserved_order = {id: index for index, id in enumerate(meditation_ids)}
        queryset = sorted(queryset, key=lambda x: preserved_order.get(x.id, 999))
        
        serializer = self.get_serializer(queryset, many=True)
        return Response({
            'results': serializer.data,
            'period': period,
            'count': len(queryset)
        })
    
    @action(detail=False, methods=['get'])
    def analytics(self, request):
        """Get content analytics (admin only)"""
        if not request.user.is_staff:
            return Response({'error': 'Permission denied'}, status=403)
        
        # Basic analytics
        total_meditations = Meditation.objects.count()
        external_meditations = Meditation.objects.exclude(source='original').count()
        
        # Source breakdown
        source_stats = Meditation.objects.values('source').annotate(
            count=models.Count('id'),
            avg_effectiveness=models.Avg('effectiveness_score')
        ).order_by('-count')
        
        # Recent sync jobs
        recent_syncs = ContentSyncJob.objects.all()[:10]
        
        return Response({
            'total_meditations': total_meditations,
            'external_meditations': external_meditations,
            'internal_meditations': total_meditations - external_meditations,
            'source_breakdown': list(source_stats),
            'recent_sync_jobs': [
                {
                    'id': job.id,
                    'source': job.source,
                    'status': job.status,
                    'started_at': job.started_at,
                    'total_items': job.total_items,
                    'new_items': job.new_items
                }
                for job in recent_syncs
            ]
        })

class RecommendationViewSet(viewsets.ModelViewSet):
    """Get personalized meditation recommendations"""
    serializer_class = RecommendationSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return MeditationRecommendation.objects.filter(
            user=self.request.user
        ).select_related('meditation', 'mental_state_analysis')
    
    @action(detail=False, methods=['post'])
    def generate(self, request):
        """Generate new recommendations based on current conversation"""
        if not AI_SERVICES_AVAILABLE:
            return Response({
                'error': 'AI services not available',
                'recommendations': []
            })
        
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
        
        try:
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
                    'emotional_tone': analysis.emotional_tone,
                    'confidence_score': analysis.confidence_score
                },
                'recommendations': serializer.data
            })
            
        except Exception as e:
            logger.error(f'Error generating recommendations: {str(e)}')
            return Response(
                {'error': 'Failed to generate recommendations'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
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
            # Convert string 'true'/'false' to boolean if needed
            if isinstance(helpful, str):
                helpful = helpful.lower() == 'true'
            recommendation.helpful = helpful
        recommendation.feedback = feedback
        recommendation.save()
        
        # Update meditation effectiveness score
        meditation = recommendation.meditation
        ratings = MeditationRecommendation.objects.filter(
            meditation=meditation,
            user_rating__isnull=False
        ).exclude(user_rating=0)
        
        if ratings.exists():
            avg_rating = ratings.aggregate(avg=models.Avg('user_rating'))['avg'] or 3
            meditation.effectiveness_score = min(1.0, avg_rating / 5.0)
            meditation.total_ratings = ratings.count()
            meditation.average_rating = avg_rating
            meditation.save(update_fields=['effectiveness_score', 'total_ratings', 'average_rating'])
        
        return Response({'message': 'Feedback recorded successfully'})

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
        if session.started_at and session.completed_at:
            duration = (session.completed_at - session.started_at).total_seconds()
            session.duration_seconds = int(duration)
        
        session.save()
        
        # Track external content usage if applicable
        if session.meditation.is_external:
            ExternalContentUsage.objects.update_or_create(
                user=request.user,
                meditation=session.meditation,
                defaults={
                    'duration_seconds': session.duration_seconds,
                    'completion_percentage': session.completion_percentage,
                    'rating': request.data.get('rating'),
                    'helpful': session.helpful,
                    'completed_at': session.completed_at
                }
            )
        
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
            },
            'achievements': self._check_achievements(profile)
        })
    
    def _check_achievements(self, profile):
        """Check for new achievements"""
        achievements = []
        
        # First meditation
        if profile.total_sessions == 1:
            achievements.append({
                'title': 'First Steps',
                'description': 'Completed your first meditation',
                'icon': '🌱'
            })
        
        # Streak achievements
        if profile.consecutive_days in [7, 30, 100]:
            achievements.append({
                'title': f'{profile.consecutive_days} Day Streak',
                'description': f'Meditated for {profile.consecutive_days} consecutive days',
                'icon': '🔥'
            })
        
        # Session milestones
        if profile.total_sessions in [10, 50, 100, 500]:
            achievements.append({
                'title': f'{profile.total_sessions} Sessions',
                'description': f'Completed {profile.total_sessions} meditation sessions',
                'icon': '⭐'
            })
        
        return achievements

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
        from .models import MeditationType
        for choice in MeditationType.choices:
            meditation_type = choice[0]
            type_sessions = total_sessions.filter(meditation__type=meditation_type)
            if type_sessions.exists():
                type_improvements = [
                    s.mood_improvement for s in type_sessions 
                    if s.mood_improvement is not None and s.mood_improvement != 0
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
        
        # External content usage
        external_usage = ExternalContentUsage.objects.filter(user=request.user)
        external_stats = {
            'total_external_sessions': external_usage.count(),
            'favorite_sources': list(external_usage.values('meditation__source')
                                   .annotate(count=models.Count('id'))
                                   .order_by('-count')[:3])
        }
        
        return Response({
            'total_sessions': profile.total_sessions,
            'total_minutes': profile.total_minutes,
            'current_streak': profile.consecutive_days,
            'current_level': profile.current_level,
            'avg_mood_improvement': round(avg_mood_improvement, 2),
            'most_effective_types': type_effectiveness,
            'favorite_time': favorite_hour,
            'completion_rate': round(completion_rate * 100, 2),
            'external_content': external_stats
        })
    
    @action(detail=False, methods=['post'])
    def update_preferences(self, request):
        """Update user preferences"""
        profile = self.get_object()
        
        serializer = UserProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            
            # Also update external preferences if provided
            external_prefs_data = request.data.get('external_preferences', {})
            if external_prefs_data:
                external_prefs, _ = UserExternalPreferences.objects.get_or_create(
                    user=request.user
                )
                
                for key, value in external_prefs_data.items():
                    if hasattr(external_prefs, key):
                        setattr(external_prefs, key, value)
                
                external_prefs.save()
            
            return Response({'message': 'Preferences updated successfully'})
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def recommendations_history(self, request):
        """Get user's recommendation history"""
        recommendations = MeditationRecommendation.objects.filter(
            user=request.user
        ).select_related('meditation').order_by('-recommended_at')[:50]
        
        serializer = RecommendationSerializer(recommendations, many=True)
        return Response({
            'recommendations': serializer.data,
            'total_recommendations': recommendations.count(),
            'completed_recommendations': recommendations.filter(completed=True).count(),
            'avg_rating': recommendations.filter(user_rating__isnull=False).aggregate(
                avg=models.Avg('user_rating')
            )['avg'] or 0
        })

# External Content Management ViewSet
class ExternalContentUsageViewSet(viewsets.ModelViewSet):
    """Track and manage external content usage"""
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return ExternalContentUsage.objects.filter(user=self.request.user)
    
    @action(detail=False, methods=['post'])
    def track_usage(self, request):
        """Track external content usage"""
        meditation_id = request.data.get('meditation_id')
        duration_seconds = request.data.get('duration_seconds', 0)
        completion_percentage = request.data.get('completion_percentage', 0)
        rating = request.data.get('rating')
        helpful = request.data.get('helpful')
        
        try:
            meditation = Meditation.objects.get(id=meditation_id)
            
            usage, created = ExternalContentUsage.objects.update_or_create(
                user=request.user,
                meditation=meditation,
                defaults={
                    'duration_seconds': duration_seconds,
                    'completion_percentage': completion_percentage,
                    'rating': rating,
                    'helpful': helpful,
                    'completed_at': timezone.now() if completion_percentage >= 80 else None
                }
            )
            
            return Response({
                'message': 'Usage tracked successfully',
                'usage_id': usage.id,
                'created': created
            })
            
        except Meditation.DoesNotExist:
            return Response(
                {'error': 'Meditation not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f'Error tracking usage: {str(e)}')
            return Response(
                {'error': 'Failed to track usage'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )