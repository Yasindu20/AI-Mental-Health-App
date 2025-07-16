from django.contrib import admin
from .models import Meditation, MeditationSession, UserMeditationProfile

@admin.register(Meditation)
class MeditationAdmin(admin.ModelAdmin):
    list_display = ['name', 'type', 'level', 'duration_minutes', 
                   'effectiveness_score', 'times_played', 'source']
    list_filter = ['type', 'level', 'source', 'target_states']
    search_fields = ['name', 'description', 'instructor_name', 'keywords']
    readonly_fields = ['times_played', 'average_rating', 'total_ratings', 
                      'published_date', 'last_updated']
    
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
    
@admin.action(description='Import meditations from CSV')
def import_from_csv(modeladmin, request, queryset):
    # Implement CSV import logic
    pass

@admin.action(description='Update effectiveness scores')
def update_effectiveness(modeladmin, request, queryset):
    for meditation in queryset:
        sessions = MeditationSession.objects.filter(
            meditation=meditation,
            post_mood_score__isnull=False
        )
        if sessions.exists():
            avg_improvement = sessions.aggregate(
                avg=models.Avg(models.F('post_mood_score') - models.F('pre_mood_score'))
            )['avg']
            meditation.effectiveness_score = min(
                0.5 + (avg_improvement * 0.1), 1.0
            )
            meditation.save()

actions = [import_from_csv, update_effectiveness]

@admin.register(MeditationSession)
class MeditationSessionAdmin(admin.ModelAdmin):
    list_display = ['user_profile', 'meditation', 'started_at', 
                   'completed_at', 'mood_improvement']
    list_filter = ['completed_at', 'helpful']
    search_fields = ['user_profile__user__username', 'meditation__name']
    readonly_fields = ['mood_improvement']

@admin.register(UserMeditationProfile)
class UserMeditationProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'current_level', 'total_sessions', 
                   'total_minutes', 'consecutive_days']
    list_filter = ['current_level', 'preferred_time_of_day']
    search_fields = ['user__username']