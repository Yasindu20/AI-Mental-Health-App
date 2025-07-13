import re
import spacy
from typing import Dict, List, Tuple, Optional
import numpy as np
from datetime import datetime, timedelta
from django.utils import timezone

class SmartCrisisDetector:
    """Advanced crisis detection with contextual understanding"""
    
    def __init__(self):
        # Load spaCy model for NLP (install with: python -m spacy download en_core_web_sm)
        try:
            self.nlp = spacy.load("en_core_web_sm")
        except:
            self.nlp = None
            
        # Crisis indicators with weights
        self.crisis_indicators = {
            'direct_harm': {
                'keywords': ['kill myself', 'end my life', 'suicide', 'take my life', 
                           'better off dead', 'not worth living', 'want to die'],
                'weight': 1.0,
                'level': 'emergency'
            },
            'self_harm': {
                'keywords': ['hurt myself', 'cut myself', 'self harm', 'cutting', 
                           'burning myself', 'overdose'],
                'weight': 0.9,
                'level': 'critical'
            },
            'harm_others': {
                'keywords': ['kill someone', 'hurt someone', 'harm others', 
                           'violent thoughts', 'homicidal'],
                'weight': 0.95,
                'level': 'emergency'
            },
            'planning': {
                'keywords': ['have a plan', 'bought pills', 'wrote a note', 
                           'saying goodbye', 'giving away', 'method to'],
                'weight': 0.8,
                'level': 'critical'
            },
            'hopelessness': {
                'keywords': ['no hope', 'hopeless', 'no point', 'give up', 
                           'cant go on', 'no future', 'trapped'],
                'weight': 0.5,
                'level': 'warning'
            },
            'isolation': {
                'keywords': ['all alone', 'no one cares', 'nobody understands', 
                           'better without me', 'burden to everyone'],
                'weight': 0.4,
                'level': 'concern'
            }
        }
        
        # Contextual modifiers that increase/decrease risk
        self.risk_modifiers = {
            'temporal_immediate': {
                'patterns': ['right now', 'tonight', 'today', 'going to'],
                'modifier': 1.3
            },
            'temporal_past': {
                'patterns': ['used to', 'in the past', 'years ago', 'when I was'],
                'modifier': 0.7
            },
            'conditional': {
                'patterns': ['if I', 'would if', 'might if', 'sometimes think'],
                'modifier': 0.8
            },
            'seeking_help': {
                'patterns': ['need help', 'please help', 'what should I do', 'talk to someone'],
                'modifier': 0.6
            }
        }
        
        # Protective factors that might reduce risk
        self.protective_factors = {
            'future_orientation': ['planning to', 'looking forward', 'next week', 'goals'],
            'social_connection': ['my friend', 'family', 'therapist', 'support group'],
            'coping_mention': ['meditation', 'exercise', 'therapy', 'medication'],
            'ambivalence': ['but', 'however', 'part of me', 'sometimes']
        }
    
    def detect_crisis(self, message: str, user_context: Optional[Dict] = None) -> Dict:
        """
        Detect crisis level with contextual understanding
        
        Returns:
            {
                'level': CrisisLevel,
                'confidence': float (0-1),
                'factors': List[str],
                'immediate_risk': bool,
                'recommended_action': str
            }
        """
        message_lower = message.lower()
        
        # Initialize detection results
        risk_score = 0.0
        detected_factors = []
        max_level = 'none'
        
        # Check for crisis indicators
        for indicator_type, indicator_data in self.crisis_indicators.items():
            for keyword in indicator_data['keywords']:
                if keyword in message_lower:
                    risk_score += indicator_data['weight']
                    detected_factors.append(indicator_type)
                    if self._compare_levels(indicator_data['level'], max_level) > 0:
                        max_level = indicator_data['level']
                    break
        
        # Apply contextual modifiers
        context_modifier = 1.0
        for modifier_type, modifier_data in self.risk_modifiers.items():
            for pattern in modifier_data['patterns']:
                if pattern in message_lower:
                    context_modifier *= modifier_data['modifier']
                    detected_factors.append(f'modifier_{modifier_type}')
                    break
        
        # Check protective factors
        protective_count = 0
        for factor_type, patterns in self.protective_factors.items():
            for pattern in patterns:
                if pattern in message_lower:
                    protective_count += 1
                    detected_factors.append(f'protective_{factor_type}')
                    break
        
        # Reduce risk based on protective factors
        if protective_count > 0:
            context_modifier *= (1 - (0.1 * protective_count))
        
        # Apply user context if available
        if user_context:
            context_modifier = self._apply_user_context(user_context, context_modifier)
        
        # Calculate final risk score
        risk_score *= context_modifier
        
        # Perform sentiment analysis if spaCy is available
        if self.nlp and risk_score > 0:
            sentiment_score = self._analyze_sentiment(message)
            risk_score *= (1 + sentiment_score)
        
        # Determine crisis level based on risk score
        if risk_score >= 1.5:
            level = 'emergency'
        elif risk_score >= 1.0:
            level = 'critical'
        elif risk_score >= 0.5:
            level = 'warning'
        elif risk_score >= 0.2:
            level = 'concern'
        else:
            level = 'none'
        
        # Check for immediate risk
        immediate_risk = any(word in message_lower for word in ['right now', 'tonight', 'about to'])
        
        # Generate confidence score
        confidence = min(risk_score / 2.0, 0.95)  # Cap at 95% confidence
        
        return {
            'level': level,
            'confidence': confidence,
            'factors': detected_factors,
            'immediate_risk': immediate_risk,
            'recommended_action': self._get_recommended_action(level, immediate_risk),
            'risk_score': risk_score
        }
    
    def _compare_levels(self, level1: str, level2: str) -> int:
        """Compare crisis levels. Returns 1 if level1 > level2, -1 if less, 0 if equal"""
        levels = ['none', 'concern', 'warning', 'critical', 'emergency']
        try:
            return levels.index(level1) - levels.index(level2)
        except ValueError:
            return 0
    
    def _apply_user_context(self, context: Dict, modifier: float) -> float:
        """Apply user-specific context to risk assessment"""
        # Recent crisis history increases risk
        if context.get('recent_crisis_count', 0) > 0:
            modifier *= 1.2
        
        # Active safety plan reduces risk
        if context.get('has_safety_plan', False):
            modifier *= 0.8
        
        # Strong support network reduces risk
        if context.get('support_network_size', 0) > 3:
            modifier *= 0.9
        
        # Recent positive mood trends reduce risk
        mood_history = context.get('mood_history', [])
        if mood_history and len(mood_history) >= 3:
            recent_moods = [m['score'] for m in mood_history[-3:]]
            if all(m >= 6 for m in recent_moods):
                modifier *= 0.8
        
        return modifier
    
    def _analyze_sentiment(self, message: str) -> float:
        """Analyze sentiment to adjust risk score"""
        try:
            doc = self.nlp(message)
            # Simple sentiment based on word polarity
            negative_words = ['hate', 'horrible', 'terrible', 'awful', 'worst', 'unbearable']
            positive_words = ['hope', 'better', 'improve', 'help', 'trying', 'grateful']
            
            neg_count = sum(1 for token in doc if token.text.lower() in negative_words)
            pos_count = sum(1 for token in doc if token.text.lower() in positive_words)
            
            if neg_count > pos_count:
                return 0.2  # Increase risk
            elif pos_count > neg_count:
                return -0.2  # Decrease risk
            return 0.0
        except:
            return 0.0
    
    def _get_recommended_action(self, level: str, immediate_risk: bool) -> str:
        """Get recommended action based on crisis level"""
        if level == 'emergency' or immediate_risk:
            return 'immediate_intervention'
        elif level == 'critical':
            return 'urgent_resources'
        elif level == 'warning':
            return 'provide_resources'
        elif level == 'concern':
            return 'supportive_response'
        else:
            return 'continue_conversation'
    
    def generate_crisis_response(self, level: str, factors: List[str], 
                               resources: List[Dict] = None) -> Dict:
        """Generate appropriate crisis response based on detection"""
        
        responses = {
            'emergency': {
                'message': "I'm very concerned about what you're sharing. Your life has value and help is available right now. Please reach out to a crisis counselor immediately:",
                'show_resources': True,
                'priority': 'immediate',
                'suggest_emergency': True
            },
            'critical': {
                'message': "I hear you're going through an incredibly difficult time. You don't have to face this alone. There are people who want to help:",
                'show_resources': True,
                'priority': 'urgent',
                'suggest_emergency': False
            },
            'warning': {
                'message': "It sounds like you're dealing with some really heavy feelings. Thank you for trusting me with this. Here are some resources that might help:",
                'show_resources': True,
                'priority': 'moderate',
                'suggest_emergency': False
            },
            'concern': {
                'message': "I can sense you're struggling right now. It's okay to feel this way, and it's brave of you to reach out. Would you like to talk more about what's on your mind?",
                'show_resources': False,
                'priority': 'low',
                'suggest_emergency': False
            }
        }
        
        response_data = responses.get(level, responses['concern'])
        
        # Add personalized elements based on factors
        if 'protective_seeking_help' in factors:
            response_data['message'] += " I'm glad you're reaching out for support."
        
        return response_data