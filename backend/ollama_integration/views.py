from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny 
from rest_framework.response import Response
from django.utils import timezone
from django.http import StreamingHttpResponse
import json

from chat.models import Conversation, Message, UserContext
from .llama_service import ollama_service
import logging

logger = logging.getLogger(__name__)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def meditation_chat(request):
    """Handle meditation chat messages with Ollama"""
    
    message_text = request.data.get('message', '').strip()
    conversation_id = request.data.get('conversation_id')
    
    if not message_text:
        return Response(
            {'error': 'Message cannot be empty'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Get or create conversation
    if conversation_id:
        try:
            conversation = Conversation.objects.get(
                id=conversation_id, 
                user=request.user
            )
        except Conversation.DoesNotExist:
            conversation = Conversation.objects.create(
                user=request.user,
                mode='meditation'
            )
    else:
        conversation = Conversation.objects.create(
            user=request.user,
            mode='meditation'
        )
    
    # Save user message
    user_message = Message.objects.create(
        conversation=conversation,
        content=message_text,
        is_user=True
    )
    
    # Get user context
    user_context, _ = UserContext.objects.get_or_create(user=request.user)
    
    # Detect mood
    mood = _detect_mood(message_text)
    
    # Prepare context for Ollama
    context = {
        'current_mood': mood,
        'recent_moods': user_context.mood_history[-5:] if user_context.mood_history else [],
        'time_of_day': _get_time_of_day(),
    }
    
    # Get conversation history
    recent_messages = conversation.messages.order_by('-created_at')[:10]
    conversation_history = [
        {
            'is_user': msg.is_user,
            'content': msg.content
        }
        for msg in reversed(recent_messages)
    ][:-1]  # Exclude the message we just saved
    
    try:
        # Generate response using Ollama
        response_data = ollama_service.generate_meditation_response(
            message=message_text,
            context=context,
            conversation_history=conversation_history
        )
        
        # Save AI response
        ai_message = Message.objects.create(
            conversation=conversation,
            content=response_data['response'],
            is_user=False,
            emotion_detected=mood
        )
        
        # Update mood history
        if mood:
            user_context.add_mood_entry(
                mood=mood, 
                score=_mood_to_score(mood)
            )
            user_context.last_mood_check = timezone.now()
            user_context.save()
        
        # Update conversation
        conversation.updated_at = timezone.now()
        conversation.save()
        
        return Response({
            'conversation_id': conversation.id,
            'ai_message': {
                'id': ai_message.id,
                'content': ai_message.content,
                'is_user': ai_message.is_user,
                'created_at': ai_message.created_at,
                'emotion_detected': ai_message.emotion_detected,
            },
            'meditation_suggested': response_data.get('meditation_suggested', False),
            'techniques': response_data.get('techniques', []),
            'mood_detected': mood,
        })
        
    except Exception as e:
        logger.error(f"Error in meditation chat: {str(e)}")
        
        # Fallback response
        ai_message = Message.objects.create(
            conversation=conversation,
            content="I'm here with you. Let's take a deep breath together. Inhale slowly... and exhale. How are you feeling right now?",
            is_user=False
        )
        
        return Response({
            'conversation_id': conversation.id,
            'ai_message': {
                'id': ai_message.id,
                'content': ai_message.content,
                'is_user': ai_message.is_user,
                'created_at': ai_message.created_at,
            },
            'meditation_suggested': True,
            'techniques': ['breathing'],
        })

@api_view(['GET'])
@permission_classes([AllowAny])
def check_ollama_status(request):
    """Check if Ollama is running and model is available"""
    
    is_connected = ollama_service.check_connection()
    available_models = ollama_service.list_models() if is_connected else []
    
    return Response({
        'connected': is_connected,
        'models': available_models,
        'current_model': ollama_service.model_name,
        'model_available': ollama_service.model_name in available_models
    })

def _detect_mood(text: str) -> str:
    """Simple mood detection"""
    text_lower = text.lower()
    
    mood_keywords = {
        'anxious': ['anxious', 'worried', 'nervous', 'stressed', 'panic', 'overwhelming'],
        'sad': ['sad', 'depressed', 'down', 'unhappy', 'lonely', 'crying'],
        'angry': ['angry', 'frustrated', 'mad', 'annoyed', 'irritated', 'furious'],
        'happy': ['happy', 'good', 'great', 'wonderful', 'excited', 'joyful'],
        'calm': ['calm', 'peaceful', 'relaxed', 'serene', 'tranquil', 'centered'],
        'tired': ['tired', 'exhausted', 'fatigue', 'sleepy', 'drained'],
        'grateful': ['grateful', 'thankful', 'blessed', 'appreciative'],
    }
    
    for mood, keywords in mood_keywords.items():
        if any(keyword in text_lower for keyword in keywords):
            return mood
    
    return 'neutral'

def _mood_to_score(mood: str) -> int:
    """Convert mood to numerical score"""
    mood_scores = {
        'happy': 8,
        'grateful': 8,
        'calm': 7,
        'neutral': 5,
        'tired': 4,
        'anxious': 4,
        'sad': 3,
        'angry': 3,
    }
    return mood_scores.get(mood, 5)

def _get_time_of_day() -> str:
    """Get current time of day for context"""
    hour = timezone.now().hour
    if hour < 6:
        return "early morning"
    elif hour < 12:
        return "morning"
    elif hour < 17:
        return "afternoon"
    elif hour < 21:
        return "evening"
    else:
        return "night"