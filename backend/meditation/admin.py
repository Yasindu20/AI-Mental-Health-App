from django.contrib import admin
from django.db import models
from .models import Meditation, MeditationSession, UserMeditationProfile

@admin.register(Meditation)
class MeditationAdmin(admin.ModelAdmin):
    list_display = ['name', 'type', 'level', 'duration_minutes', 
                   'effectiveness_score', 'times_played', 'source']
    list_filter = ['type', 'level', 'source', 'target_states']
    search_fields = ['name', 'description', 'instructor_name', 'keywords']
    readonly_fields = ['times_played', 'average_rating', 'total_ratings', 
                      'published_date', 'last_updated']
    filter_horizontal = []
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'type', 'level', 'duration_minutes')
        }),
        ('Content', {
            'fields': ('description', 'instructions', 'benefits', 'script')
        }),
        ('Categorization', {
            'fields': ('target_states', 'subcategory', 'tags', 'keywords')
        }),
        ('Media', {
            'fields': ('audio_url', 'video_url', 'thumbnail_url', 
                      'background_music_url')
        }),
        ('Instructor', {
            'fields': ('instructor_name', 'instructor_bio')
        }),
        ('Metadata', {
            'fields': ('source', 'effectiveness_score', 'prerequisites')
        }),
        ('Statistics (Read-only)', {
            'fields': ('times_played', 'average_rating', 'total_ratings',
                      'published_date', 'last_updated')
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related()

@admin.action(description='Import meditations from CSV')
def import_from_csv(modeladmin, request, queryset):
    # Future implementation for CSV import
    from django.contrib import messages
    messages.info(request, "CSV import functionality coming soon!")

@admin.action(description='Update effectiveness scores')
def update_effectiveness(modeladmin, request, queryset):
    updated_count = 0
    for meditation in queryset:
        sessions = MeditationSession.objects.filter(
            meditation=meditation,
            post_mood_score__isnull=False,
            pre_mood_score__isnull=False
        )
        if sessions.exists():
            avg_improvement = sessions.aggregate(
                avg=models.Avg(models.F('post_mood_score') - models.F('pre_mood_score'))
            )['avg']
            if avg_improvement is not None:
                # Normalize to 0-1 scale
                meditation.effectiveness_score = min(
                    max(0.5 + (avg_improvement * 0.1), 0.0), 1.0
                )
                meditation.save()
                updated_count += 1
    
    from django.contrib import messages
    messages.success(request, f"Updated effectiveness scores for {updated_count} meditations.")

# Add actions to admin
MeditationAdmin.actions = [import_from_csv, update_effectiveness]

@admin.register(MeditationSession)
class MeditationSessionAdmin(admin.ModelAdmin):
    list_display = ['user_profile', 'meditation', 'started_at', 
                   'completed_at', 'mood_improvement', 'completion_percentage']
    list_filter = ['completed_at', 'helpful', 'meditation__type']
    search_fields = ['user_profile__user__username', 'meditation__name']
    readonly_fields = ['mood_improvement']
    date_hierarchy = 'started_at'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'user_profile__user', 'meditation'
        )

@admin.register(UserMeditationProfile)
class UserMeditationProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'current_level', 'total_sessions', 
                   'total_minutes', 'consecutive_days', 'last_session_date']
    list_filter = ['current_level', 'preferred_time_of_day']
    search_fields = ['user__username', 'user__email']
    readonly_fields = ['total_sessions', 'total_minutes', 'consecutive_days']
    
    fieldsets = (
        ('User Information', {
            'fields': ('user',)
        }),
        ('Preferences', {
            'fields': ('preferred_types', 'preferred_duration', 
                      'preferred_time_of_day', 'current_level')
        }),
        ('Statistics (Read-only)', {
            'fields': ('total_sessions', 'total_minutes', 'consecutive_days', 
                      'last_session_date', 'avg_mood_improvement')
        }),
        ('Advanced', {
            'fields': ('most_effective_types',),
            'classes': ('collapse',)
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user')