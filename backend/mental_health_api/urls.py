from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse
from rest_framework.routers import DefaultRouter
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from chat.views import ConversationViewSet, UserContextViewSet
from chat.auth_views import register, login_view, logout_view
from ollama_integration.views import meditation_chat, check_ollama_status
from crisis_detection.views import (
    CrisisResourceViewSet, 
    UserEmergencyContactViewSet, 
    UserCrisisProfileViewSet,
    CrisisDetectionViewSet
)
from meditation.views import (
    MeditationViewSet,
    RecommendationViewSet,
    MeditationSessionViewSet,
    UserMeditationProfileViewSet
)

# Create a public API info view
@api_view(['GET'])
@permission_classes([AllowAny])
def api_info_view(request):
    """Public API information endpoint"""
    return Response({
        'message': 'Mental Health API',
        'version': '1.0.0',
        'status': 'online',
        'authentication': 'Token-based authentication required for protected endpoints',
        'public_endpoints': {
            'api_info': '/api/info/',
            'meditation_status': '/api/meditation/status/',
            'external_content_test': '/api/external-content-test/',
            'register': '/api/register/',
            'login': '/api/login/',
        },
        'protected_endpoints': {
            'api_root': '/api/',
            'conversations': '/api/conversations/',
            'meditation_chat': '/api/meditation/chat/',
            'meditations': '/api/meditations/',
            'external_content': '/api/meditations/external_content/',
            'recommendations': '/api/recommendations/',
            'sessions': '/api/sessions/',
            'profile': '/api/profile/',
            'user_context': '/api/context/',
            'crisis_resources': '/api/crisis-resources/',
            'emergency_contacts': '/api/emergency-contacts/',
            'crisis_profile': '/api/crisis-profile/',
            'logout': '/api/logout/',
        },
        'admin': '/admin/',
        'note': 'To access protected endpoints, include: Authorization: Token YOUR_TOKEN'
    })

# Public test endpoint for external content
@api_view(['GET'])
@permission_classes([AllowAny])
def external_content_test(request):
    """Public test endpoint for external content"""
    try:
        from meditation.external_apis.content_aggregator import content_aggregator
        
        # Get service status
        service_status = content_aggregator.get_service_status() if content_aggregator else {}
        
        # Get a small sample of content for testing
        sample_content = []
        if content_aggregator:
            try:
                sample_content = content_aggregator.get_all_external_content(max_per_source=3)
            except Exception as e:
                pass
        
        return Response({
            'status': 'External Content API Test',
            'service_status': service_status,
            'available_services': [k for k, v in service_status.items() if v],
            'sample_content_count': len(sample_content),
            'sample_content': sample_content[:5],  # Only show first 5 items
            'debug_info': 'This is a public test endpoint. Use /api/meditations/external_content/ with authentication for full access.',
            'auth_required_for_full_access': True
        })
    except Exception as e:
        return Response({
            'error': 'Failed to test external content',
            'details': str(e),
            'debug_info': 'Check server logs for more details'
        })

@api_view(['GET'])
@permission_classes([AllowAny])
def external_content_debug(request):
    """Debug endpoint for external content - shows raw data"""
    try:
        from meditation.external_apis.content_aggregator import content_aggregator
        
        if not content_aggregator:
            return Response({
                'error': 'Content aggregator not available',
                'debug': 'External APIs not properly initialized'
            })
        
        # Get small sample from each source
        youtube_content = content_aggregator.get_all_external_content(['youtube'], max_per_source=3)
        spotify_content = content_aggregator.get_all_external_content(['spotify'], max_per_source=3)
        huggingface_content = content_aggregator.get_all_external_content(['huggingface'], max_per_source=3)
        
        return Response({
            'youtube_count': len(youtube_content),
            'spotify_count': len(spotify_content),
            'huggingface_count': len(huggingface_content),
            'total_count': len(youtube_content) + len(spotify_content) + len(huggingface_content),
            'sample_youtube': youtube_content[:1] if youtube_content else [],
            'sample_spotify': spotify_content[:1] if spotify_content else [],
            'sample_huggingface': huggingface_content[:1] if huggingface_content else [],
            'services_status': content_aggregator.get_service_status(),
        })
    except Exception as e:
        return Response({
            'error': str(e),
            'debug': 'Check server logs for details'
        })

# Simple root view for the main domain
def root_view(request):
    """Root domain handler"""
    return JsonResponse({
        'message': 'Mental Health API Server',
        'status': 'running',
        'api_info': '/api/info/',
        'api_root': '/api/',
        'external_content_test': '/api/external-content-test/',
        'version': '1.0.0'
    })

# Custom router class to make the root public
class PublicDefaultRouter(DefaultRouter):
    """Custom router that allows public access to the API root"""
    
    def get_api_root_view(self, api_urls=None):
        """Return the root view, but make it public"""
        api_root_dict = {}
        list_name = self.routes[0].name
        for prefix, viewset, basename in self.registry:
            api_root_dict[prefix] = list_name.format(basename=basename)

        @api_view(['GET'])
        @permission_classes([AllowAny])  # Make this public
        def api_root(request, format=None):
            """Public API root view showing available endpoints"""
            return Response({
                'message': 'Mental Health API - Protected Endpoints',
                'note': 'These endpoints require authentication: Authorization: Token YOUR_TOKEN',
                'endpoints': api_root_dict,
                'authentication_endpoints': {
                    'register': '/api/register/',
                    'login': '/api/login/',
                    'logout': '/api/logout/',
                },
                'public_endpoints': {
                    'api_info': '/api/info/',
                    'meditation_status': '/api/meditation/status/',
                    'external_content_test': '/api/external-content-test/',
                }
            })

        return api_root

router = PublicDefaultRouter()
router.register(r'conversations', ConversationViewSet, basename='conversation')
router.register(r'context', UserContextViewSet, basename='context')
router.register(r'crisis-resources', CrisisResourceViewSet, basename='crisis-resource')
router.register(r'emergency-contacts', UserEmergencyContactViewSet, basename='emergency-contact')
router.register(r'crisis-profile', UserCrisisProfileViewSet, basename='crisis-profile')
router.register(r'crisis-detections', CrisisDetectionViewSet, basename='crisis-detection')
router.register(r'meditations', MeditationViewSet, basename='meditation')
router.register(r'recommendations', RecommendationViewSet, basename='recommendation')
router.register(r'sessions', MeditationSessionViewSet, basename='session')
router.register(r'profile', UserMeditationProfileViewSet, basename='profile')

urlpatterns = [
    # Root domain
    path('', root_view),

    path('api/debug/external-content/', external_content_debug),
    
    # Admin
    path('admin/', admin.site.urls),
    
    # Public API info
    path('api/info/', api_info_view),
    
    # Public external content test endpoint
    path('api/external-content-test/', external_content_test),
    
    # Authentication endpoints (public)
    path('api/register/', register),
    path('api/login/', login_view),
    path('api/logout/', logout_view),
    
    # Ollama endpoints
    path('api/meditation/chat/', meditation_chat),
    path('api/meditation/status/', check_ollama_status),
    
    # API routes (now with public root)
    path('api/', include(router.urls)),
]