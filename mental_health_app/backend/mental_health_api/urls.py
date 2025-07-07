from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from chat.views import ConversationViewSet, UserContextViewSet
from chat.auth_views import register, login_view, logout_view

router = DefaultRouter()
router.register(r'conversations', ConversationViewSet, basename='conversation')
router.register(r'context', UserContextViewSet, basename='context')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include(router.urls)),
    path('api-auth/', include('rest_framework.urls')),
    path('api/register/', register),
    path('api/login/', login_view),
    path('api/logout/', logout_view),
]