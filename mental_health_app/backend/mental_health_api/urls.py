# mental_health_api/urls.py
from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from django.views.decorators.csrf import ensure_csrf_cookie
from django.http import JsonResponse
from chat.views import ConversationViewSet, UserContextViewSet
from chat.auth_views import register, login_view, logout_view
from crisis_detection.views import (
    CrisisResourceViewSet, UserEmergencyContactViewSet,
    UserCrisisProfileViewSet, CrisisDetectionViewSet
)

router = DefaultRouter()
router.register(r'conversations', ConversationViewSet, basename='conversation')
router.register(r'context', UserContextViewSet, basename='context')

# Add crisis_detection endpoints
router.register(r'crisis-resources', CrisisResourceViewSet, basename='crisis-resource')
router.register(r'emergency-contacts', UserEmergencyContactViewSet, basename='emergency-contact')
router.register(r'crisis-profile', UserCrisisProfileViewSet, basename='crisis-profile')
router.register(r'crisis-detections', CrisisDetectionViewSet, basename='crisis-detection')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include(router.urls)),
    path('api-auth/', include('rest_framework.urls')),
    path('api/register/', register),
    path('api/login/', login_view),
    path('api/logout/', logout_view),
    path('api/csrf/', ensure_csrf_cookie(lambda request: JsonResponse({'success': True}))),
]