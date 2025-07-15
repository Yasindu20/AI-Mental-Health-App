# backend/ai_engine/mental_state_analyzer.py
import numpy as np
from typing import Dict, List, Tuple
from collections import Counter
import re

class MentalStateAnalyzer:
    """Advanced mental state analysis using NLP and pattern recognition"""
    
    def __init__(self):
        # Mental state indicators with weights
        self.state_indicators = {
            'anxiety': {
                'keywords': ['anxious', 'worried', 'nervous', 'panic', 'fear', 
                           'overwhelmed', 'racing thoughts', 'can\'t breathe',
                           'heart racing', 'sweating', 'trembling'],
                'phrases': ['what if', 'I\'m scared', 'can\'t stop thinking',
                          'worst case', 'freaking out'],
                'weight': 1.0
            },
            'depression': {
                'keywords': ['sad', 'depressed', 'hopeless', 'empty', 'numb',
                           'worthless', 'guilty', 'tired', 'exhausted', 'lonely'],
                'phrases': ['no point', 'give up', 'can\'t go on', 'hate myself',
                          'better off without me'],
                'weight': 1.0
            },
            'stress': {
                'keywords': ['stressed', 'pressure', 'deadline', 'overloaded',
                           'busy', 'rushing', 'juggling', 'demands'],
                'phrases': ['too much', 'can\'t handle', 'falling behind',
                          'no time', 'burning out'],
                'weight': 0.9
            },
            'anger': {
                'keywords': ['angry', 'furious', 'mad', 'pissed', 'frustrated',
                           'irritated', 'annoyed', 'rage', 'hate'],
                'phrases': ['fed up', 'had enough', 'lose it', 'blow up'],
                'weight': 0.8
            },
            'insomnia': {
                'keywords': ['can\'t sleep', 'insomnia', 'awake', 'tired',
                           'exhausted', 'sleepless', 'restless'],
                'phrases': ['up all night', 'mind racing', 'tossing and turning'],
                'weight': 0.7
            }
        }
        
        # Emotional intensity modifiers
        self.intensity_modifiers = {
            'high': ['very', 'extremely', 'totally', 'completely', 'absolutely',
                    'incredibly', 'severely', 'intensely'],
            'medium': ['quite', 'pretty', 'fairly', 'somewhat', 'rather'],
            'low': ['slightly', 'a bit', 'a little', 'mildly', 'somewhat']
        }
        
        # Time-based patterns
        self.temporal_patterns = {
            'chronic': ['always', 'constantly', 'never', 'all the time', 'every day'],
            'frequent': ['often', 'frequently', 'usually', 'regularly'],
            'occasional': ['sometimes', 'occasionally', 'now and then']
        }
    
    def analyze_conversation(self, messages: List[Dict]) -> Dict:
        """Analyze full conversation for mental state patterns"""
        
        # Combine all user messages
        user_text = ' '.join([m['content'] for m in messages if m['is_user']])
        
        # Perform analysis
        state_scores = self._calculate_state_scores(user_text)
        emotional_tone = self._detect_emotional_tone(user_text)
        themes = self._extract_themes(user_text)
        severity = self._calculate_severity(state_scores, user_text)
        
        # Determine primary and secondary concerns
        sorted_states = sorted(state_scores.items(), key=lambda x: x[1], reverse=True)
        primary_concern = sorted_states[0][0] if sorted_states[0][1] > 0.3 else 'stress'
        secondary_concerns = [s[0] for s in sorted_states[1:4] if s[1] > 0.2]
        
        # Generate recommendations
        recommendations = self._generate_recommendations(
            primary_concern, secondary_concerns, severity
        )
        
        return {
            'anxiety_level': state_scores.get('anxiety', 0) * 10,
            'depression_level': state_scores.get('depression', 0) * 10,
            'stress_level': state_scores.get('stress', 0) * 10,
            'anger_level': state_scores.get('anger', 0) * 10,
            'focus_issues': state_scores.get('focus', 0) * 10,
            'primary_concern': primary_concern,
            'secondary_concerns': secondary_concerns,
            'emotional_tone': emotional_tone,
            'key_themes': themes,
            'severity_score': severity,
            'confidence_score': self._calculate_confidence(user_text),
            'recommended_meditation_types': recommendations['types'],
            'recommended_duration': recommendations['duration'],
            'urgency_level': recommendations['urgency']
        }
    
    def _calculate_state_scores(self, text: str) -> Dict[str, float]:
        """Calculate scores for each mental state"""
        text_lower = text.lower()
        scores = {}
        
        for state, indicators in self.state_indicators.items():
            score = 0.0
            
            # Check keywords
            for keyword in indicators['keywords']:
                if keyword in text_lower:
                    score += 0.1 * indicators['weight']
            
            # Check phrases
            for phrase in indicators['phrases']:
                if phrase in text_lower:
                    score += 0.2 * indicators['weight']
            
            # Apply intensity modifiers
            intensity = self._detect_intensity(text_lower)
            score *= intensity
            
            # Apply temporal modifiers
            temporality = self._detect_temporality(text_lower)
            score *= temporality
            
            scores[state] = min(score, 1.0)  # Cap at 1.0
        
        return scores
    
    def _detect_emotional_tone(self, text: str) -> str:
        """Detect overall emotional tone"""
        # Simplified emotion detection
        positive_words = ['happy', 'good', 'better', 'hope', 'love', 'grateful']
        negative_words = ['sad', 'bad', 'worse', 'hate', 'awful', 'terrible']
        
        text_lower = text.lower()
        pos_count = sum(1 for word in positive_words if word in text_lower)
        neg_count = sum(1 for word in negative_words if word in text_lower)
        
        if neg_count > pos_count * 2:
            return 'very_negative'
        elif neg_count > pos_count:
            return 'negative'
        elif pos_count > neg_count:
            return 'positive'
        else:
            return 'neutral'
    
    def _extract_themes(self, text: str) -> List[str]:
        """Extract key themes from text"""
        theme_keywords = {
            'work': ['work', 'job', 'boss', 'colleague', 'deadline', 'project'],
            'relationship': ['partner', 'spouse', 'friend', 'family', 'love', 'breakup'],
            'health': ['sick', 'pain', 'doctor', 'medicine', 'hospital', 'symptom'],
            'financial': ['money', 'bills', 'debt', 'salary', 'expense', 'budget'],
            'self': ['myself', 'I am', 'my life', 'identity', 'worth', 'value'],
            'future': ['future', 'tomorrow', 'plan', 'goal', 'dream', 'hope'],
            'past': ['past', 'memory', 'regret', 'mistake', 'used to', 'before']
        }
        
        text_lower = text.lower()
        themes = []
        
        for theme, keywords in theme_keywords.items():
            if any(keyword in text_lower for keyword in keywords):
                themes.append(theme)
        
        return themes[:3]  # Return top 3 themes
    
    def _calculate_severity(self, state_scores: Dict[str, float], text: str) -> float:
        """Calculate overall severity score"""
        # Base severity on state scores
        max_score = max(state_scores.values()) if state_scores else 0
        avg_score = np.mean(list(state_scores.values())) if state_scores else 0
        
        # Check for crisis indicators
        crisis_words = ['suicide', 'kill', 'die', 'end it', 'harm']
        crisis_multiplier = 2.0 if any(word in text.lower() for word in crisis_words) else 1.0
        
        severity = (max_score * 0.6 + avg_score * 0.4) * crisis_multiplier
        return min(severity * 10, 10.0)  # Scale to 0-10
    
    def _detect_intensity(self, text: str) -> float:
        """Detect emotional intensity"""
        for intensity, modifiers in self.intensity_modifiers.items():
            if any(mod in text for mod in modifiers):
                if intensity == 'high':
                    return 1.5
                elif intensity == 'medium':
                    return 1.2
                else:
                    return 0.8
        return 1.0
    
    def _detect_temporality(self, text: str) -> float:
        """Detect temporal patterns"""
        for pattern, indicators in self.temporal_patterns.items():
            if any(ind in text for ind in indicators):
                if pattern == 'chronic':
                    return 1.3
                elif pattern == 'frequent':
                    return 1.1
                else:
                    return 0.9
        return 1.0
    
    def _calculate_confidence(self, text: str) -> float:
        """Calculate confidence in analysis"""
        # Simple heuristic based on text length and clarity
        word_count = len(text.split())
        if word_count < 10:
            return 0.3
        elif word_count < 50:
            return 0.6
        elif word_count < 200:
            return 0.8
        else:
            return 0.9
    
    def _generate_recommendations(self, primary: str, secondary: List[str], 
                                severity: float) -> Dict:
        """Generate meditation recommendations based on analysis"""
        
        # Map concerns to meditation types
        concern_to_meditation = {
            'anxiety': ['breathing', 'mindfulness', 'body_scan', 'progressive_relaxation'],
            'depression': ['loving_kindness', 'mindfulness', 'movement', 'mantra'],
            'stress': ['breathing', 'body_scan', 'visualization', 'progressive_relaxation'],
            'anger': ['breathing', 'loving_kindness', 'movement', 'mindfulness'],
            'insomnia': ['body_scan', 'progressive_relaxation', 'visualization', 'breathing'],
            'focus': ['mindfulness', 'breathing', 'mantra', 'zen']
        }
        
        # Get recommended types
        types = concern_to_meditation.get(primary, ['mindfulness', 'breathing'])
        for concern in secondary:
            types.extend(concern_to_meditation.get(concern, []))
        
        # Remove duplicates while preserving order
        seen = set()
        unique_types = []
        for t in types:
            if t not in seen:
                seen.add(t)
                unique_types.append(t)
        
        # Determine duration based on severity and user level
        if severity >= 7:
            duration = 20  # Longer sessions for high severity
        elif severity >= 4:
            duration = 15
        else:
            duration = 10
        
        # Determine urgency
        if severity >= 8:
            urgency = 'critical'
        elif severity >= 6:
            urgency = 'high'
        elif severity >= 4:
            urgency = 'medium'
        else:
            urgency = 'low'
        
        return {
            'types': unique_types[:4],  # Top 4 types
            'duration': duration,
            'urgency': urgency
        }