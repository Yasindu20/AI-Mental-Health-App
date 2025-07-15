# backend/meditation/recommendation_engine.py
import numpy as np
from typing import List, Dict, Tuple
from django.db.models import Q, F, Count, Avg
from .models import (
    Meditation, MeditationRecommendation, UserMeditationProfile,
    MeditationSession, UserMentalStateAnalysis
)
from datetime import datetime, timedelta
from django.utils import timezone

class MeditationRecommendationEngine:
    """AI-powered meditation recommendation system"""
    
    def __init__(self):
        self.feature_weights = {
            'relevance_to_state': 0.35,
            'user_level_match': 0.20,
            'effectiveness_score': 0.15,
            'user_preference': 0.15,
            'variety': 0.10,
            'time_of_day': 0.05
        }
    
    def generate_recommendations(self, user, mental_state_analysis: UserMentalStateAnalysis, 
                               count: int = 5) -> List[MeditationRecommendation]:
        """Generate personalized meditation recommendations"""
        
        # Get user profile
        profile, _ = UserMeditationProfile.objects.get_or_create(user=user)
        
        # Get candidate meditations
        candidates = self._get_candidate_meditations(
            mental_state_analysis, profile
        )
        
        # Score each candidate
        scored_meditations = []
        for meditation in candidates:
            score = self._calculate_recommendation_score(
                meditation, mental_state_analysis, profile, user
            )
            reason = self._generate_recommendation_reason(
                meditation, mental_state_analysis, score
            )
            scored_meditations.append((meditation, score, reason))
        
        # Sort by score
        scored_meditations.sort(key=lambda x: x[1], reverse=True)
        
        # Create recommendation objects
        recommendations = []
        for meditation, score, reason in scored_meditations[:count]:
            relevance = self._calculate_relevance_score(
                meditation, mental_state_analysis
            )
            personalization = self._calculate_personalization_score(
                meditation, profile, user
            )
            
            rec = MeditationRecommendation.objects.create(
                user=user,
                meditation=meditation,
                mental_state_analysis=mental_state_analysis,
                relevance_score=relevance,
                personalization_score=personalization,
                reason=reason
            )
            recommendations.append(rec)
        
        return recommendations
    
    def _get_candidate_meditations(self, analysis: UserMentalStateAnalysis, 
                                 profile: UserMeditationProfile) -> List[Meditation]:
        """Get initial set of candidate meditations"""
        
        # Start with meditations that target the user's concerns
        query = Q()
        
        # Primary concern
        query |= Q(target_states__contains=analysis.primary_concern)
        
        # Secondary concerns
        for concern in analysis.secondary_concerns:
            query |= Q(target_states__contains=concern)
        
        # Filter by user level
        level_query = Q(level=profile.current_level)
        
        # Also include easier levels for variety
        if profile.current_level == 'intermediate':
            level_query |= Q(level='beginner')
        elif profile.current_level == 'advanced':
            level_query |= Q(level__in=['beginner', 'intermediate'])
        
        # Get meditations
        candidates = Meditation.objects.filter(query & level_query)
        
        # If not enough candidates, broaden search
        if candidates.count() < 10:
            candidates = Meditation.objects.filter(query)
        
        return list(candidates[:50])  # Limit to top 50 for performance
    
    def _calculate_recommendation_score(self, meditation: Meditation,
                                      analysis: UserMentalStateAnalysis,
                                      profile: UserMeditationProfile,
                                      user) -> float:
        """Calculate overall recommendation score"""
        
        scores = {
            'relevance_to_state': self._score_relevance_to_state(
                meditation, analysis
            ),
            'user_level_match': self._score_level_match(
                meditation, profile
            ),
            'effectiveness_score': self._score_effectiveness(
                meditation, user
            ),
            'user_preference': self._score_user_preference(
                meditation, profile, user
            ),
            'variety': self._score_variety(
                meditation, user
            ),
            'time_of_day': self._score_time_of_day(
                meditation, profile
            )
        }
        
        # Calculate weighted sum
        total_score = sum(
            scores[feature] * self.feature_weights[feature]
            for feature in scores
        )
        
        return total_score
    
    def _score_relevance_to_state(self, meditation: Meditation,
                                analysis: UserMentalStateAnalysis) -> float:
        """Score how relevant the meditation is to user's mental state"""
        score = 0.0
        
        # Check if meditation targets primary concern
        if analysis.primary_concern in meditation.target_states:
            score += 0.5
        
        # Check secondary concerns
        for concern in analysis.secondary_concerns:
            if concern in meditation.target_states:
                score += 0.2
        
        # Bonus for matching multiple concerns
        matched_concerns = len([
            c for c in [analysis.primary_concern] + analysis.secondary_concerns
            if c in meditation.target_states
        ])
        if matched_concerns >= 3:
            score += 0.3
        elif matched_concerns >= 2:
            score += 0.1
        
        # Consider severity - longer meditations for higher severity
        if analysis.severity_score >= 7:
            if meditation.duration_minutes >= 15:
                score += 0.2
        elif analysis.severity_score <= 3:
            if meditation.duration_minutes <= 10:
                score += 0.2
        
        return min(score, 1.0)
    
    def _score_level_match(self, meditation: Meditation,
                         profile: UserMeditationProfile) -> float:
        """Score how well meditation matches user's level"""
        if meditation.level == profile.current_level:
            return 1.0
        elif profile.current_level == 'intermediate':
            if meditation.level == 'beginner':
                return 0.7  # Can still do beginner
            else:
                return 0.3  # Advanced might be too hard
        elif profile.current_level == 'advanced':
            if meditation.level == 'intermediate':
                return 0.8
            else:
                return 0.5  # Beginner might be too easy
        else:  # Beginner
            if meditation.level == 'intermediate':
                return 0.3  # Might be challenging
            else:
                return 0.1  # Advanced too difficult
    
    def _score_effectiveness(self, meditation: Meditation, user) -> float:
        """Score based on meditation's general effectiveness and user history"""
        base_score = meditation.effectiveness_score
        
        # Check if user has done this meditation before
        sessions = MeditationSession.objects.filter(
            user_profile__user=user,
            meditation=meditation,
            completed_at__isnull=False
        )
        
        if sessions.exists():
            # Calculate average mood improvement
            avg_improvement = sessions.aggregate(
                avg_imp=Avg(F('post_mood_score') - F('pre_mood_score'))
            )['avg_imp'] or 0
            
            # Positive improvement boosts score
            if avg_improvement > 0:
                base_score += avg_improvement * 0.1
            
            # Check completion rate
            completion_rate = sessions.filter(
                completion_percentage__gte=80
            ).count() / sessions.count()
            
            base_score *= completion_rate
        
        return min(base_score, 1.0)
    
    def _score_user_preference(self, meditation: Meditation,
                             profile: UserMeditationProfile, user) -> float:
        """Score based on user preferences"""
        score = 0.5  # Neutral baseline
        
        # Preferred meditation types
        if meditation.type in profile.preferred_types:
            score += 0.3
        
        # Preferred duration
        duration_diff = abs(meditation.duration_minutes - profile.preferred_duration)
        if duration_diff == 0:
            score += 0.2
        elif duration_diff <= 5:
            score += 0.1
        elif duration_diff > 10:
            score -= 0.2
        
        # Check if in favorites
        if profile.favorite_meditations.filter(id=meditation.id).exists():
            score += 0.3
        
        # Check past ratings
        past_recommendations = MeditationRecommendation.objects.filter(
            user=user,
            meditation=meditation,
            user_rating__isnull=False
        )
        
        if past_recommendations.exists():
            avg_rating = past_recommendations.aggregate(
                avg=Avg('user_rating')
            )['avg']
            score += (avg_rating - 3) * 0.1  # -0.2 to +0.2
        
        return max(0, min(score, 1.0))
    
    def _score_variety(self, meditation: Meditation, user) -> float:
        """Score to ensure variety in recommendations"""
        # Check recent sessions
        recent_cutoff = timezone.now() - timedelta(days=7)
        recent_sessions = MeditationSession.objects.filter(
            user_profile__user=user,
            started_at__gte=recent_cutoff
        )
        
        # Penalize if same meditation done recently
        if recent_sessions.filter(meditation=meditation).exists():
            return 0.2
        
        # Penalize if same type done too much
        same_type_count = recent_sessions.filter(
            meditation__type=meditation.type
        ).count()
        
        if same_type_count >= 5:
            return 0.3
        elif same_type_count >= 3:
            return 0.6
        else:
            return 1.0
    
    def _score_time_of_day(self, meditation: Meditation,
                         profile: UserMeditationProfile) -> float:
        """Score based on time of day appropriateness"""
        current_hour = timezone.now().hour
        
        # Map meditation types to optimal times
        optimal_times = {
            'breathing': 'any',
            'body_scan': 'evening',
            'movement': 'morning',
            'visualization': 'any',
            'loving_kindness': 'any',
            'progressive_relaxation': 'evening',
            'mantra': 'morning',
            'zen': 'any'
        }
        
        optimal = optimal_times.get(meditation.type, 'any')
        
        if optimal == 'any':
            return 0.8
        elif optimal == 'morning' and 5 <= current_hour <= 11:
            return 1.0
        elif optimal == 'evening' and (current_hour >= 18 or current_hour <= 2):
            return 1.0
        else:
            return 0.5
    
    def _calculate_relevance_score(self, meditation: Meditation,
                                 analysis: UserMentalStateAnalysis) -> float:
        """Calculate detailed relevance score"""
        return self._score_relevance_to_state(meditation, analysis)
    
    def _calculate_personalization_score(self, meditation: Meditation,
                                       profile: UserMeditationProfile,
                                       user) -> float:
        """Calculate detailed personalization score"""
        pref_score = self._score_user_preference(meditation, profile, user)
        level_score = self._score_level_match(meditation, profile)
        return (pref_score + level_score) / 2
    
    def _generate_recommendation_reason(self, meditation: Meditation,
                                      analysis: UserMentalStateAnalysis,
                                      score: float) -> str:
        """Generate human-readable reason for recommendation"""
        reasons = []
        
        # State-based reason
        if analysis.primary_concern in meditation.target_states:
            concern_text = analysis.primary_concern.replace('_', ' ')
            reasons.append(f"Specifically designed to help with {concern_text}")
        
        # Effectiveness reason
        if meditation.effectiveness_score >= 0.8:
            reasons.append("Highly rated by users with similar concerns")
        
        # Duration reason
        if analysis.severity_score >= 7 and meditation.duration_minutes >= 15:
            reasons.append("Longer session to provide deeper relief")
        elif analysis.severity_score <= 3 and meditation.duration_minutes <= 10:
            reasons.append("Quick session perfect for mild symptoms")
        
        # Level reason
        if meditation.level == 'beginner':
            reasons.append("Easy to follow for beginners")
        
        # Type-specific reasons
        type_benefits = {
            'breathing': "Quickly calms the nervous system",
            'body_scan': "Releases physical tension",
            'loving_kindness': "Cultivates self-compassion",
            'mindfulness': "Brings you to the present moment",
            'visualization': "Uses imagination for healing"
        }
        
        if meditation.type in type_benefits:
            reasons.append(type_benefits[meditation.type])
        
        # Combine reasons
        if reasons:
            return ". ".join(reasons[:2])  # Use top 2 reasons
        else:
            return f"Recommended based on your current state and preferences (score: {score:.2f})"

# Initialize global instance
recommendation_engine = MeditationRecommendationEngine()