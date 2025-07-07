import random
import re
from typing import Dict, List, Tuple
from datetime import datetime
import json

class EmpatheticAI:
    """Simple rule-based AI with empathetic responses"""
    
    def __init__(self):
        self.emotion_keywords = {
            'sad': ['sad', 'depressed', 'down', 'unhappy', 'miserable', 'lonely', 'isolated'],
            'anxious': ['anxious', 'worried', 'nervous', 'scared', 'panic', 'stress', 'overwhelmed'],
            'angry': ['angry', 'mad', 'frustrated', 'annoyed', 'irritated', 'furious'],
            'happy': ['happy', 'good', 'great', 'wonderful', 'excited', 'joyful'],
            'neutral': ['okay', 'fine', 'alright', 'normal']
        }
        
        self.empathetic_responses = {
            'sad': [
                "I hear that you're feeling down. That must be really difficult for you.",
                "It sounds like you're going through a tough time. I'm here to listen.",
                "Thank you for sharing that with me. Feeling sad can be really overwhelming.",
                "I can sense the sadness in what you're sharing. Your feelings are valid."
            ],
            'anxious': [
                "It sounds like you're dealing with a lot of worry right now. That can be exhausting.",
                "Anxiety can feel really overwhelming. You're not alone in this.",
                "I understand you're feeling anxious. Let's work through this together.",
                "Those anxious feelings can be really challenging. I'm here to support you."
            ],
            'angry': [
                "I can hear the frustration in your words. It's okay to feel angry.",
                "It sounds like you're dealing with some strong emotions. That's understandable.",
                "Anger is a valid emotion. Thank you for being open about how you feel.",
                "I hear your frustration. Sometimes things can feel really unfair."
            ],
            'happy': [
                "It's wonderful to hear that you're feeling good! What's contributing to your happiness?",
                "That's great to hear! I'm glad you're experiencing positive emotions.",
                "Your happiness is contagious! Tell me more about what's going well.",
                "It sounds like things are going well for you. That's fantastic!"
            ],
            'neutral': [
                "Thank you for checking in. How has your day been so far?",
                "I'm here to listen. What's on your mind today?",
                "Sometimes 'okay' is perfectly fine. Is there anything specific you'd like to talk about?",
                "I appreciate you taking the time to connect. What would you like to explore today?"
            ]
        }
        
        self.followup_questions = {
            'sad': [
                "Would you like to tell me more about what's making you feel this way?",
                "How long have you been feeling like this?",
                "What usually helps you when you're feeling down?",
                "Is there something specific that triggered these feelings?"
            ],
            'anxious': [
                "What thoughts are running through your mind right now?",
                "Are there specific situations that trigger your anxiety?",
                "What helps you feel calmer when anxiety strikes?",
                "Would you like to try a breathing exercise together?"
            ],
            'angry': [
                "What situation led to these feelings of anger?",
                "How does your body feel when you're angry?",
                "What would help you feel more at peace right now?",
                "Have you been able to express your anger in a healthy way?"
            ]
        }
        
        self.cbt_prompts = {
            'thought_challenge': [
                "Let's examine this thought together. What evidence do you have for and against it?",
                "If a friend told you this, what would you say to them?",
                "Is there another way to look at this situation?",
                "How likely is it that your worry will actually happen?"
            ],
            'behavioral_activation': [
                "What's one small thing you could do today that might lift your mood?",
                "When was the last time you did something you enjoyed?",
                "Could we plan a pleasant activity for later today?",
                "What activities used to bring you joy?"
            ]
        }
        
        self.mindfulness_exercises = [
            {
                'name': '5-4-3-2-1 Grounding',
                'intro': "Let's try a grounding exercise to help you feel more present.",
                'steps': [
                    "Name 5 things you can see around you",
                    "Name 4 things you can touch",
                    "Name 3 things you can hear",
                    "Name 2 things you can smell",
                    "Name 1 thing you can taste"
                ]
            },
            {
                'name': 'Box Breathing',
                'intro': "Let's practice box breathing to help calm your nervous system.",
                'steps': [
                    "Breathe in for 4 counts",
                    "Hold your breath for 4 counts",
                    "Breathe out for 4 counts",
                    "Hold empty for 4 counts",
                    "Repeat 4 times"
                ]
            }
        ]
    
    def detect_emotion(self, text: str) -> str:
        """Detect the primary emotion in the text"""
        text_lower = text.lower()
        emotion_scores = {}
        
        for emotion, keywords in self.emotion_keywords.items():
            score = sum(1 for keyword in keywords if keyword in text_lower)
            if score > 0:
                emotion_scores[emotion] = score
        
        if not emotion_scores:
            return 'neutral'
        
        return max(emotion_scores, key=emotion_scores.get)
    
    def detect_crisis_keywords(self, text: str) -> bool:
        """Check for crisis keywords that need immediate attention"""
        crisis_keywords = ['suicide', 'kill myself', 'end it all', 'not worth living', 
                          'self harm', 'hurt myself', 'cutting']
        text_lower = text.lower()
        return any(keyword in text_lower for keyword in crisis_keywords)
    
    def generate_response(self, message: str, context: Dict = None, mode: str = 'unstructured') -> Dict:
        """Generate an empathetic response based on the message and context"""
        
        # Check for crisis
        if self.detect_crisis_keywords(message):
            return {
                'response': "I'm really concerned about what you're sharing. You don't have to go through this alone. Please reach out to a crisis helpline right away:\n\n• National Suicide Prevention Lifeline: 988\n• Crisis Text Line: Text HOME to 741741\n• International: findahelpline.com\n\nWould you like me to help you find local resources?",
                'emotion': 'crisis',
                'suggestions': ['crisis_resources']
            }
        
        emotion = self.detect_emotion(message)
        
        if mode == 'unstructured':
            return self._generate_unstructured_response(message, emotion, context)
        elif mode == 'cbt_exercise':
            return self._generate_cbt_response(message, emotion, context)
        elif mode == 'mindfulness':
            return self._generate_mindfulness_response(message, context)
        elif mode == 'mood_check':
            return self._generate_mood_check_response(message, context)
    
    def _generate_unstructured_response(self, message: str, emotion: str, context: Dict) -> Dict:
        """Generate response for unstructured conversation"""
        # Select empathetic response
        response = random.choice(self.empathetic_responses.get(emotion, self.empathetic_responses['neutral']))
        
        # Add followup question
        if emotion in ['sad', 'anxious', 'angry']:
            followup = random.choice(self.followup_questions.get(emotion, []))
            response = f"{response} {followup}"
        
        # Personalize based on context
        if context and context.get('mood_history'):
            recent_moods = context['mood_history'][-3:]
            if all(m['score'] < 5 for m in recent_moods):
                response += "\n\nI've noticed you've been having some difficult days. Remember, it's okay to have ups and downs."
        
        return {
            'response': response,
            'emotion': emotion,
            'suggestions': self._get_suggestions(emotion)
        }
    
    def _generate_cbt_response(self, message: str, emotion: str, context: Dict) -> Dict:
        """Generate CBT-based response"""
        if emotion in ['sad', 'anxious']:
            prompt = random.choice(self.cbt_prompts['thought_challenge'])
            response = f"I hear that you're feeling {emotion}. {prompt}"
        else:
            prompt = random.choice(self.cbt_prompts['behavioral_activation'])
            response = f"Let's work on lifting your mood. {prompt}"
        
        return {
            'response': response,
            'emotion': emotion,
            'exercise_type': 'cbt',
            'suggestions': ['thought_diary', 'activity_planning']
        }
    
    def _generate_mindfulness_response(self, message: str, context: Dict) -> Dict:
        """Generate mindfulness exercise response"""
        exercise = random.choice(self.mindfulness_exercises)
        
        steps_text = "\n".join([f"{i+1}. {step}" for i, step in enumerate(exercise['steps'])])
        response = f"{exercise['intro']}\n\n{steps_text}\n\nTake your time with each step. Let me know when you're ready to continue."
        
        return {
            'response': response,
            'emotion': 'calm',
            'exercise_type': 'mindfulness',
            'exercise_name': exercise['name']
        }
    
    def _generate_mood_check_response(self, message: str, context: Dict) -> Dict:
        """Generate mood check-in response"""
        # Simple mood parsing (in production, use NLP)
        mood_score = 5  # Default
        
        if any(word in message.lower() for word in ['great', 'excellent', 'wonderful']):
            mood_score = 8
        elif any(word in message.lower() for word in ['good', 'fine', 'okay']):
            mood_score = 6
        elif any(word in message.lower() for word in ['bad', 'terrible', 'awful']):
            mood_score = 3
        elif any(word in message.lower() for word in ['sad', 'depressed', 'horrible']):
            mood_score = 2
        
        response = f"Thank you for checking in. I'm noting that your mood is around {mood_score}/10 today."
        
        if mood_score < 5:
            response += " I'm here if you'd like to talk about what's troubling you."
        elif mood_score > 7:
            response += " It's great to see you're feeling positive! What's contributing to your good mood?"
        
        return {
            'response': response,
            'emotion': 'neutral',
            'mood_score': mood_score,
            'suggestions': self._get_suggestions_for_mood(mood_score)
        }
    
    def _get_suggestions(self, emotion: str) -> List[str]:
        """Get activity suggestions based on emotion"""
        suggestions = {
            'sad': ['gentle_walk', 'call_friend', 'gratitude_journal', 'favorite_music'],
            'anxious': ['breathing_exercise', 'progressive_relaxation', 'worry_time', 'grounding'],
            'angry': ['physical_exercise', 'journal_feelings', 'count_to_ten', 'take_break'],
            'happy': ['share_joy', 'gratitude_practice', 'plan_activity', 'help_others'],
            'neutral': ['mood_check', 'mindfulness', 'daily_planning', 'self_care']
        }
        return suggestions.get(emotion, suggestions['neutral'])
    
    def _get_suggestions_for_mood(self, mood_score: int) -> List[str]:
        """Get suggestions based on mood score"""
        if mood_score < 4:
            return ['reach_out', 'self_compassion', 'gentle_activity', 'crisis_resources']
        elif mood_score < 7:
            return ['mood_boost_activity', 'social_connection', 'nature_time', 'creative_outlet']
        else:
            return ['maintain_routine', 'share_positivity', 'gratitude', 'help_others']