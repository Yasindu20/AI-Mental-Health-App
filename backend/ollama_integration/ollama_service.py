import requests
import json
import logging
from typing import Dict, List, Optional
import time

logger = logging.getLogger(__name__)

class OllamaService:
    """Service for handling Ollama API interactions"""
    
    def __init__(self):
        self.base_url = "http://localhost:11434"
        self.model_name = "llama3.2:3b-instruct-q4_0"
        self.timeout = 30
        
    def check_connection(self) -> bool:
        """Check if Ollama is running"""
        try:
            response = requests.get(f"{self.base_url}/api/tags")
            return response.status_code == 200
        except:
            return False
    
    def list_models(self) -> List[str]:
        """List available models"""
        try:
            response = requests.get(f"{self.base_url}/api/tags")
            if response.status_code == 200:
                models = response.json().get('models', [])
                return [model['name'] for model in models]
            return []
        except Exception as e:
            logger.error(f"Error listing models: {str(e)}")
            return []
    
    def generate_meditation_response(
        self, 
        message: str, 
        context: Optional[Dict] = None,
        conversation_history: Optional[List[Dict]] = None
    ) -> Dict:
        """Generate meditation-focused response using Ollama"""
        
        if not self.check_connection():
            logger.error("Ollama is not running. Please start Ollama first.")
            return {
                'response': "I'm having trouble connecting to my meditation guidance system. Please make sure the meditation service is running.",
                'error': True
            }
        
        # Build conversation context
        messages = self._build_conversation_context(
            message, 
            context, 
            conversation_history
        )
        
        # Prepare request
        request_data = {
            "model": self.model_name,
            "messages": messages,
            "stream": False,
            "options": {
                "temperature": 0.7,
                "top_p": 0.9,
                "num_predict": 300,
            }
        }
        
        try:
            # Make request to Ollama
            response = requests.post(
                f"{self.base_url}/api/chat",
                json=request_data,
                timeout=self.timeout
            )
            
            if response.status_code == 200:
                result = response.json()
                response_text = result['message']['content']
                
                # Analyze response for meditation elements
                analysis = self._analyze_response(response_text)
                
                return {
                    'response': response_text,
                    'meditation_suggested': analysis['meditation_suggested'],
                    'techniques': analysis['techniques'],
                    'mood_addressed': analysis['mood_addressed'],
                }
            else:
                logger.error(f"Ollama API error: {response.status_code}")
                return self._get_fallback_response()
                
        except requests.exceptions.Timeout:
            logger.error("Ollama request timed out")
            return {
                'response': "I'm taking a moment to gather my thoughts. Let's try a simple breathing exercise while we reconnect. Take a deep breath in... and out...",
                'meditation_suggested': True,
                'techniques': ['breathing'],
            }
        except Exception as e:
            logger.error(f"Error generating response: {str(e)}")
            return self._get_fallback_response()
    
    def _build_conversation_context(
        self, 
        message: str, 
        context: Optional[Dict], 
        conversation_history: Optional[List[Dict]]
    ) -> List[Dict]:
        """Build conversation context for Ollama"""
        
        # System prompt for meditation focus
        system_message = {
            "role": "system",
            "content": """You are a compassionate meditation and mindfulness coach. Your purpose is to:

1. Listen with deep empathy and understanding
2. Guide users through meditation and mindfulness practices
3. Suggest appropriate techniques based on their emotional state
4. Maintain a calm, peaceful, and supportive tone
5. Focus on present-moment awareness and self-compassion
6. Avoid giving medical advice - focus on mindfulness and meditation

Key principles:
- Be warm and non-judgmental
- Offer gentle guidance, not commands
- Validate feelings before suggesting practices
- Keep responses concise but meaningful
- Always maintain a sense of hope and possibility"""
        }
        
        messages = [system_message]
        
        # Add user context if available
        if context:
            context_message = self._build_context_message(context)
            if context_message:
                messages.append({
                    "role": "system",
                    "content": context_message
                })
        
        # Add conversation history (last 5 exchanges)
        if conversation_history:
            for msg in conversation_history[-10:]:  # Last 5 exchanges
                messages.append({
                    "role": "user" if msg.get('is_user') else "assistant",
                    "content": msg.get('content', '')
                })
        
        # Add current message
        messages.append({
            "role": "user",
            "content": message
        })
        
        return messages
    
    def _build_context_message(self, context: Dict) -> str:
        """Build context message from user data"""
        context_parts = []
        
        if context.get('current_mood'):
            context_parts.append(f"User's current mood: {context['current_mood']}")
        
        if context.get('recent_moods'):
            mood_trend = self._analyze_mood_trend(context['recent_moods'])
            context_parts.append(f"Recent mood trend: {mood_trend}")
        
        if context.get('preferred_techniques'):
            techniques = ", ".join(context['preferred_techniques'])
            context_parts.append(f"User prefers: {techniques}")
        
        if context.get('time_of_day'):
            context_parts.append(f"Current time: {context['time_of_day']}")
        
        return " | ".join(context_parts) if context_parts else ""
    
    def _analyze_mood_trend(self, recent_moods: List[Dict]) -> str:
        """Analyze mood trend from recent data"""
        if not recent_moods:
            return "No recent mood data"
        
        scores = [m.get('score', 5) for m in recent_moods if 'score' in m]
        if not scores:
            return "No mood scores available"
        
        avg_score = sum(scores) / len(scores)
        
        if avg_score < 4:
            return "struggling recently"
        elif avg_score < 6:
            return "mixed emotions"
        elif avg_score < 8:
            return "generally positive"
        else:
            return "feeling great"
    
    def _analyze_response(self, response_text: str) -> Dict:
        """Analyze AI response for meditation elements"""
        response_lower = response_text.lower()
        
        # Check if meditation was suggested
        meditation_keywords = [
            'meditat', 'mindful', 'breath', 'relax', 'calm',
            'peace', 'present moment', 'awareness', 'observe',
            'gentle', 'let\'s try', 'exercise', 'practice'
        ]
        meditation_suggested = any(
            keyword in response_lower for keyword in meditation_keywords
        )
        
        # Identify specific techniques mentioned
        techniques = []
        technique_patterns = {
            'breathing': ['breath', 'inhale', 'exhale', 'breathing'],
            'body_scan': ['body scan', 'tension', 'relax your body', 'physical sensations'],
            'mindfulness': ['mindful', 'present moment', 'awareness', 'observe'],
            'visualization': ['imagine', 'visualize', 'picture', 'envision'],
            'loving_kindness': ['loving', 'kindness', 'compassion', 'self-compassion'],
            'grounding': ['ground', '5-4-3-2-1', 'senses', 'feel your feet'],
            'progressive_relaxation': ['progressive', 'muscle', 'tense and relax'],
        }
        
        for technique, patterns in technique_patterns.items():
            if any(pattern in response_lower for pattern in patterns):
                techniques.append(technique)
        
        # Identify mood addressed
        mood_addressed = None
        mood_patterns = {
            'anxiety': ['anxious', 'anxiety', 'worried', 'worry', 'nervous'],
            'sadness': ['sad', 'down', 'depressed', 'blue', 'lonely'],
            'stress': ['stress', 'overwhelm', 'pressure', 'tense'],
            'anger': ['angry', 'frustrated', 'irritated', 'upset'],
            'fear': ['afraid', 'scared', 'fear', 'frightened'],
        }
        
        for mood, patterns in mood_patterns.items():
            if any(pattern in response_lower for pattern in patterns):
                mood_addressed = mood
                break
        
        return {
            'meditation_suggested': meditation_suggested,
            'techniques': techniques,
            'mood_addressed': mood_addressed,
        }
    
    def _get_fallback_response(self) -> Dict:
        """Get fallback response when Ollama fails"""
        return {
            'response': (
                "I'm here with you. Sometimes the best thing we can do is simply pause "
                "and breathe together. Would you like to try a gentle breathing exercise? "
                "Or perhaps you'd prefer to share what's on your mind?"
            ),
            'meditation_suggested': True,
            'techniques': ['breathing'],
        }
    
    def stream_meditation_response(
        self, 
        message: str, 
        context: Optional[Dict] = None
    ):
        """Stream response for real-time feel (generator function)"""
        messages = self._build_conversation_context(message, context, None)
        
        request_data = {
            "model": self.model_name,
            "messages": messages,
            "stream": True,
            "options": {
                "temperature": 0.7,
                "top_p": 0.9,
            }
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/api/chat",
                json=request_data,
                stream=True
            )
            
            for line in response.iter_lines():
                if line:
                    data = json.loads(line)
                    if 'message' in data and 'content' in data['message']:
                        yield data['message']['content']
                        
        except Exception as e:
            logger.error(f"Streaming error: {str(e)}")
            yield "I'm here to support you. Let's take this moment together."

# Create singleton instance
ollama_service = OllamaService()