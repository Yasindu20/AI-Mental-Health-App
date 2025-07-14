from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from .models import Conversation, Message, UserContext
from .serializers import (
    ConversationSerializer, MessageSerializer, 
    UserContextSerializer, ChatRequestSerializer
)
from ollama_integration.llama_service import llama_service
import logging

logger = logging.getLogger(__name__)

class ConversationViewSet(viewsets.ModelViewSet):
    serializer_class = ConversationSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Conversation.objects.filter(user=self.request.user)
    
    @action(detail=False, methods=['post'])
    def chat(self, request):
        """Handle chat messages with Llama 3.2"""
        message_text = request.data.get('message', '').strip()
        
        if not message_text:
            return Response(
                {'error': 'Message cannot be empty'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get or create conversation
        conversation_id = request.data.get('conversation_id')
        if conversation_id:
            try:
                conversation = Conversation.objects.get(
                    id=conversation_id, 
                    user=request.user
                )
            except Conversation.DoesNotExist:
                conversation = Conversation.objects.create(
                    user=request.user,
                    mode='meditation'  # Single mode now
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
        context, _ = UserContext.objects.get_or_create(user=request.user)
        
        # Detect mood from message
        user_mood = self._detect_mood(message_text)
        
        # Prepare context for Llama
        llama_context = {
            'recent_topics': self._get_recent_topics(conversation),
            'mood_history': context.mood_history[-5:] if context.mood_history else [],
        }
        
        try:
            # Generate response using Llama
            llama_response = llama_service.generate_meditation_response(
                message=message_text,
                context=llama_context,
                user_mood=user_mood
            )
            
            # Save AI response
            ai_message = Message.objects.create(
                conversation=conversation,
                content=llama_response['response'],
                is_user=False,
                emotion_detected=user_mood
            )
            
            # Update mood history
            if user_mood:
                context.add_mood_entry(mood=user_mood, score=self._mood_to_score(user_mood))
            
            # Update conversation
            conversation.updated_at = timezone.now()
            conversation.save()
            
            return Response({
                'conversation_id': conversation.id,
                'user_message': MessageSerializer(user_message).data,
                'ai_message': MessageSerializer(ai_message).data,
                'meditation_suggested': llama_response.get('meditation_suggested', False),
                'techniques': llama_response.get('techniques', []),
                'mood_detected': user_mood,
            })
            
        except Exception as e:
            logger.error(f"Error in chat: {str(e)}")
            # Fallback response
            ai_message = Message.objects.create(
                conversation=conversation,
                content="I'm here to listen and support you. Let's take a deep breath together. "
                       "Inhale slowly... and exhale. How are you feeling right now?",
                is_user=False
            )
            
            return Response({
                'conversation_id': conversation.id,
                'user_message': MessageSerializer(user_message).data,
                'ai_message': MessageSerializer(ai_message).data,
                'meditation_suggested': True,
                'techniques': ['breathing'],
            })
    
    def _detect_mood(self, text: str) -> str:
        """Simple mood detection"""
        text_lower = text.lower()
        
        mood_keywords = {
            'anxious': ['anxious', 'worried', 'nervous', 'stressed', 'panic'],
            'sad': ['sad', 'depressed', 'down', 'unhappy', 'lonely'],
            'angry': ['angry', 'frustrated', 'mad', 'annoyed', 'irritated'],
            'happy': ['happy', 'good', 'great', 'wonderful', 'excited'],
            'calm': ['calm', 'peaceful', 'relaxed', 'serene', 'tranquil'],
        }
        
        for mood, keywords in mood_keywords.items():
            if any(keyword in text_lower for keyword in keywords):
                return mood
                
        return 'neutral'
    
    def _mood_to_score(self, mood: str) -> int:
        """Convert mood to numerical score"""
        mood_scores = {
            'happy': 8,
            'calm': 7,
            'neutral': 5,
            'anxious': 4,
            'sad': 3,
            'angry': 3,
        }
        return mood_scores.get(mood, 5)
    
    def _get_recent_topics(self, conversation) -> list:
        """Extract recent conversation topics"""
        recent_messages = conversation.messages.filter(is_user=True).order_by('-created_at')[:5]
        topics = []
        
        topic_keywords = {
            'stress': ['stress', 'pressure', 'overwhelm'],
            'sleep': ['sleep', 'insomnia', 'tired', 'rest'],
            'anxiety': ['anxiety', 'worry', 'fear'],
            'work': ['work', 'job', 'boss', 'colleague'],
            'relationships': ['relationship', 'partner', 'friend', 'family'],
        }
        
        for message in recent_messages:
            message_lower = message.content.lower()
            for topic, keywords in topic_keywords.items():
                if any(keyword in message_lower for keyword in keywords):
                    if topic not in topics:
                        topics.append(topic)
                        
        return topics