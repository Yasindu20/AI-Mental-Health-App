# backend/ollama_integration/enhanced_llama_service.py
from .llama_service import LlamaService
import json
from typing import List, Dict

class EnhancedLlamaService(LlamaService):
    """Enhanced Llama service with mental state analysis"""
    
    def analyze_mental_state(self, conversation_history: List[Dict]) -> Dict:
        """Use Llama to analyze mental state from conversation"""
        
        # Prepare conversation context
        messages = [
            {
                "role": "system",
                "content": """You are a mental health analysis expert. Analyze the user's messages to identify:
1. Primary mental/emotional state (anxiety, depression, stress, anger, etc.)
2. Severity level (1-10 scale)
3. Key themes or concerns
4. Emotional tone
5. Recommended support approach

Respond ONLY with a JSON object in this exact format:
{
    "primary_state": "anxiety",
    "severity": 7,
    "secondary_states": ["stress", "insomnia"],
    "themes": ["work", "relationships"],
    "emotional_tone": "distressed",
    "confidence": 0.85
}"""
            }
        ]
        
        # Add conversation history
        for msg in conversation_history[-10:]:  # Last 10 messages
            messages.append({
                "role": "user" if msg['is_user'] else "assistant",
                "content": msg['content']
            })
        
        # Add analysis request
        messages.append({
            "role": "user",
            "content": "Analyze the mental state from this conversation."
        })
        
        try:
            response = self._make_request(messages)
            # Parse JSON response
            return json.loads(response)
        except:
            # Fallback analysis
            return {
                "primary_state": "stress",
                "severity": 5,
                "secondary_states": [],
                "themes": [],
                "emotional_tone": "neutral",
                "confidence": 0.5
            }
    
    def personalize_meditation_script(self, meditation: Dict, 
                                    user_state: Dict) -> str:
        """Generate personalized meditation script"""
        
        prompt = f"""Create a personalized {meditation['type']} meditation script for someone experiencing {user_state['primary_concern']}.

Meditation: {meditation['name']}
Duration: {meditation['duration_minutes']} minutes
User's state: {user_state['emotional_tone']}
Severity: {user_state['severity_score']}/10

Requirements:
1. Start with a calming introduction
2. Address their specific concern
3. Use appropriate pacing for the duration
4. End with positive affirmations
5. Keep language simple and soothing

Generate the complete meditation script:"""
        
        messages = [
            {
                "role": "system",
                "content": "You are a certified meditation instructor creating personalized guided meditations."
            },
            {
                "role": "user",
                "content": prompt
            }
        ]
        
        return self._make_request(messages)