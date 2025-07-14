# backend/mental_health_api/urls.py
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
            'register': '/api/register/',
            'login': '/api/login/',
        },
        'protected_endpoints': {
            'api_root': '/api/',
            'conversations': '/api/conversations/',
            'meditation_chat': '/api/meditation/chat/',
            'user_context': '/api/context/',
            'crisis_resources': '/api/crisis-resources/',
            'emergency_contacts': '/api/emergency-contacts/',
            'crisis_profile': '/api/crisis-profile/',
            'logout': '/api/logout/',
        },
        'admin': '/admin/',
        'note': 'To access protected endpoints, include: Authorization: Token YOUR_TOKEN'
    })

# Simple root view for the main domain
def root_view(request):
    """Root domain handler"""
    return JsonResponse({
        'message': 'Mental Health API Server',
        'status': 'running',
        'api_info': '/api/info/',
        'api_root': '/api/',
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

urlpatterns = [
    # Root domain
    path('', root_view),
    
    # Admin
    path('admin/', admin.site.urls),
    
    # Public API info
    path('api/info/', api_info_view),
    
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