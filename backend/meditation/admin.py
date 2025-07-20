# backend/meditation/admin.py
from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.utils.safestring import mark_safe
from django.http import HttpResponse
import csv

from .models import (
    Meditation, MeditationRecommendation, UserMeditationProfile,
    MeditationSession, UserMentalStateAnalysis, ExternalContentUsage,
    UserExternalPreferences, ContentSyncJob, ExternalAPIQuota
)

# Generic CSV export action
def export_as_csv(modeladmin, request, queryset):
    """Generic CSV export action"""
    opts = modeladmin.model._meta
    response = HttpResponse(content_type='text/csv')
    response['Content-Disposition'] = f'attachment; filename={opts.verbose_name}.csv'
    
    writer = csv.writer(response)
    field_names = [field.name for field in opts.fields]
    writer.writerow(field_names)
    
    for obj in queryset:
        writer.writerow([getattr(obj, field) for field in field_names])
    
    return response

export_as_csv.short_description = "Export selected items as CSV"

@admin.register(Meditation)
class MeditationAdmin(admin.ModelAdmin):
    list_display = [
        'name', 'source', 'type', 'level', 'duration_minutes', 
        'effectiveness_score', 'times_played', 'is_external_content', 'created_at'
    ]
    list_filter = [
        'source', 'type', 'level', 'is_free', 'requires_subscription',
        'language', 'created_at', 'updated_at'
    ]
    search_fields = ['name', 'description', 'instructor_name', 'artist_name', 'channel_name']
    readonly_fields = [
        'created_at', 'updated_at', 'last_synced', 'times_played', 
        'external_content_info', 'engagement_metrics'
    ]
    ordering = ['-effectiveness_score', '-created_at']
    actions = ['sync_external_content', 'reset_metrics', export_as_csv]
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'type', 'level', 'duration_minutes', 'description')
        }),
        ('Content Source', {
            'fields': ('source', 'external_id', 'language', 'is_free', 'requires_subscription')
        }),
        ('Media URLs', {
            'fields': ('audio_url', 'video_url', 'spotify_url', 'thumbnail_url', 'background_music_url'),
            'classes': ('collapse',)
        }),
        ('Content Details', {
            'fields': ('script', 'instructions', 'benefits', 'target_states', 'tags', 'keywords'),
            'classes': ('collapse',)
        }),
        ('Creator Information', {
            'fields': ('instructor_name', 'instructor_bio', 'artist_name', 'channel_name', 'album_name'),
            'classes': ('collapse',)
        }),
        ('Metrics & Engagement', {
            'fields': ('engagement_metrics', 'external_content_info'),
            'classes': ('collapse',)
        }),
        ('System Information', {
            'fields': ('created_at', 'updated_at', 'last_synced'),
            'classes': ('collapse',)
        }),
    )
    
    def is_external_content(self, obj):
        return obj.is_external
    is_external_content.boolean = True
    is_external_content.short_description = 'External Content'
    
    def external_content_info(self, obj):
        if not obj.is_external:
            return "Internal Content"
        
        info = []
        if obj.view_count:
            info.append(f"Views: {obj.view_count:,}")
        if obj.like_count:
            info.append(f"Likes: {obj.like_count:,}")
        if obj.spotify_popularity:
            info.append(f"Spotify Popularity: {obj.spotify_popularity}")
        if obj.downloads:
            info.append(f"Downloads: {obj.downloads:,}")
        
        return " | ".join(info) if info else "No external metrics"
    external_content_info.short_description = 'External Metrics'
    
    def engagement_metrics(self, obj):
        return format_html(
            "<strong>Effectiveness:</strong> {:.2f}<br>"
            "<strong>Avg Rating:</strong> {:.1f} ({} ratings)<br>"
            "<strong>Times Played:</strong> {}",
            obj.effectiveness_score,
            obj.average_rating,
            obj.total_ratings,
            obj.times_played
        )
    engagement_metrics.short_description = 'Engagement'
    
    def sync_external_content(self, request, queryset):
        external_meditations = queryset.exclude(source='original')
        # This would trigger a sync job in a real implementation
        self.message_user(request, f'Sync requested for {external_meditations.count()} external meditations')
    sync_external_content.short_description = 'Sync external content'
    
    def reset_metrics(self, request, queryset):
        updated = queryset.update(
            times_played=0,
            average_rating=0.0,
            total_ratings=0,
            effectiveness_score=0.5
        )
        self.message_user(request, f'Reset metrics for {updated} meditations')
    reset_metrics.short_description = 'Reset engagement metrics'

@admin.register(UserMeditationProfile)
class UserMeditationProfileAdmin(admin.ModelAdmin):
    list_display = [
        'user', 'current_level', 'total_sessions', 'total_minutes', 
        'consecutive_days', 'last_session_date', 'avg_mood_improvement'
    ]
    list_filter = ['current_level', 'preferred_time_of_day', 'last_session_date']
    search_fields = ['user__username', 'user__email']
    readonly_fields = [
        'total_sessions', 'total_minutes', 'consecutive_days', 
        'last_session_date', 'created_at', 'updated_at'
    ]
    actions = [export_as_csv]
    
    fieldsets = (
        ('User Information', {
            'fields': ('user', 'current_level')
        }),
        ('Preferences', {
            'fields': ('preferred_types', 'preferred_duration', 'preferred_time_of_day')
        }),
        ('Progress Statistics', {
            'fields': ('total_sessions', 'total_minutes', 'consecutive_days', 'last_session_date'),
            'classes': ('collapse',)
        }),
        ('Effectiveness Tracking', {
            'fields': ('avg_mood_improvement', 'most_effective_types'),
            'classes': ('collapse',)
        }),
        ('System Information', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

@admin.register(MeditationSession)
class MeditationSessionAdmin(admin.ModelAdmin):
    list_display = [
        'user_profile', 'meditation', 'started_at', 'duration_minutes',
        'completion_percentage', 'mood_improvement_display', 'helpful'
    ]
    list_filter = [
        'started_at', 'helpful', 'meditation__type', 'meditation__source',
        'completion_percentage'
    ]
    search_fields = [
        'user_profile__user__username', 'meditation__name'
    ]
    readonly_fields = ['started_at', 'duration_minutes', 'mood_improvement_display']
    date_hierarchy = 'started_at'
    actions = [export_as_csv]
    
    def duration_minutes(self, obj):
        return f"{obj.duration_seconds // 60}m {obj.duration_seconds % 60}s"
    duration_minutes.short_description = 'Duration'
    
    def mood_improvement_display(self, obj):
        improvement = obj.mood_improvement
        if improvement > 0:
            return format_html('<span style="color: green;">+{}</span>', improvement)
        elif improvement < 0:
            return format_html('<span style="color: red;">{}</span>', improvement)
        else:
            return "No change"
    mood_improvement_display.short_description = 'Mood Change'

@admin.register(MeditationRecommendation)
class MeditationRecommendationAdmin(admin.ModelAdmin):
    list_display = [
        'user', 'meditation', 'relevance_score', 'recommended_at',
        'viewed', 'started', 'completed', 'user_rating'
    ]
    list_filter = [
        'recommended_at', 'viewed', 'started', 'completed',
        'user_rating', 'meditation__type'
    ]
    search_fields = ['user__username', 'meditation__name', 'reason']
    readonly_fields = ['recommended_at']
    actions = [export_as_csv]
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user', 'meditation')

@admin.register(UserMentalStateAnalysis)
class UserMentalStateAnalysisAdmin(admin.ModelAdmin):
    list_display = [
        'user', 'primary_concern', 'severity_score', 'emotional_tone',
        'confidence_score', 'analyzed_at'
    ]
    list_filter = [
        'primary_concern', 'emotional_tone', 'urgency_level', 'analyzed_at'
    ]
    search_fields = ['user__username', 'primary_concern', 'emotional_tone']
    readonly_fields = ['analyzed_at', 'confidence_score']
    date_hierarchy = 'analyzed_at'
    actions = [export_as_csv]
    
    fieldsets = (
        ('User & Analysis Info', {
            'fields': ('user', 'conversation', 'analyzed_at', 'confidence_score')
        }),
        ('Mental State Scores', {
            'fields': ('anxiety_level', 'depression_level', 'stress_level', 'anger_level', 'focus_issues')
        }),
        ('Analysis Results', {
            'fields': ('primary_concern', 'secondary_concerns', 'emotional_tone', 'severity_score')
        }),
        ('Themes & Recommendations', {
            'fields': ('key_themes', 'recommended_meditation_types', 'recommended_duration', 'urgency_level')
        }),
    )

@admin.register(UserExternalPreferences)
class UserExternalPreferencesAdmin(admin.ModelAdmin):
    list_display = [
        'user', 'preferred_sources_display', 'min_external_duration',
        'max_external_duration', 'min_effectiveness_score', 'updated_at'
    ]
    list_filter = ['youtube_quality_preference', 'spotify_preview_only', 'prefer_high_quality']
    search_fields = ['user__username']
    readonly_fields = ['created_at', 'updated_at']
    actions = [export_as_csv]
    
    def preferred_sources_display(self, obj):
        return ", ".join(obj.preferred_sources) if obj.preferred_sources else "None"
    preferred_sources_display.short_description = 'Preferred Sources'

@admin.register(ExternalContentUsage)
class ExternalContentUsageAdmin(admin.ModelAdmin):
    list_display = [
        'user', 'meditation', 'started_at', 'duration_seconds',
        'completion_percentage', 'rating', 'helpful'
    ]
    list_filter = [
        'started_at', 'rating', 'helpful', 'meditation__source'
    ]
    search_fields = ['user__username', 'meditation__name']
    readonly_fields = ['started_at']
    date_hierarchy = 'started_at'
    actions = [export_as_csv]

@admin.register(ContentSyncJob)
class ContentSyncJobAdmin(admin.ModelAdmin):
    list_display = [
        'id', 'source', 'status', 'started_at', 'total_items',
        'processed_items', 'new_items', 'progress_percentage'
    ]
    list_filter = ['source', 'status', 'started_at']
    readonly_fields = ['started_at', 'completed_at', 'progress_percentage']
    ordering = ['-started_at']
    actions = [export_as_csv]
    
    def progress_percentage(self, obj):
        if obj.total_items > 0:
            percentage = (obj.processed_items / obj.total_items) * 100
            return f"{percentage:.1f}%"
        return "0%"
    progress_percentage.short_description = 'Progress'
    
    def get_readonly_fields(self, request, obj=None):
        if obj and obj.status in ['completed', 'failed']:
            return self.readonly_fields + ['status', 'total_items', 'processed_items', 'new_items']
        return self.readonly_fields

@admin.register(ExternalAPIQuota)
class ExternalAPIQuotaAdmin(admin.ModelAdmin):
    list_display = [
        'source', 'daily_requests', 'daily_limit', 'daily_remaining',
        'monthly_requests', 'monthly_limit', 'monthly_remaining', 'last_reset_date'
    ]
    list_filter = ['source', 'last_reset_date']
    readonly_fields = ['daily_remaining', 'monthly_remaining']
    actions = ['reset_daily_quota', 'reset_monthly_quota', export_as_csv]
    
    def reset_daily_quota(self, request, queryset):
        updated = queryset.update(daily_requests=0)
        self.message_user(request, f'Reset daily quota for {updated} sources')
    reset_daily_quota.short_description = 'Reset daily quota'
    
    def reset_monthly_quota(self, request, queryset):
        updated = queryset.update(monthly_requests=0)
        self.message_user(request, f'Reset monthly quota for {updated} sources')
    reset_monthly_quota.short_description = 'Reset monthly quota'

# Custom admin site configuration
admin.site.site_header = "Mental Health App Administration"
admin.site.site_title = "Mental Health Admin"
admin.site.index_title = "Welcome to Mental Health App Administration"