from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    MeditationViewSet, RecommendationViewSet, MeditationSessionViewSet,
    UserMeditationProfileViewSet, ExternalContentUsageViewSet
)

router = DefaultRouter()
router.register(r'meditations', MeditationViewSet, basename='meditation')
router.register(r'recommendations', RecommendationViewSet, basename='recommendation')
router.register(r'sessions', MeditationSessionViewSet, basename='session')
router.register(r'profile', UserMeditationProfileViewSet, basename='profile')
router.register(r'external-usage', ExternalContentUsageViewSet, basename='external-usage')

urlpatterns = [
    path('', include(router.urls)),
]