from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.contrib.auth.models import User
from django.utils import timezone
from .models import Conversation, Message, UserContext, ConversationMode
from .serializers import (ConversationSerializer, MessageSerializer, 
                         UserContextSerializer, ChatRequestSerializer)
from ai_engine.empathetic_ai import EmpatheticAI

class ConversationViewSet(viewsets.ModelViewSet):
    serializer_class = ConversationSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Conversation.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
    
    @action(detail=False, methods=['post'])
    def chat(self, request):
        """Handle chat messages"""
        serializer = ChatRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        data = serializer.validated_data
        message_text = data['message']
        mode = data.get('mode', 'unstructured')
        conversation_id = data.get('conversation_id')
        
        # Get or create conversation
        if conversation_id:
            try:
                conversation = Conversation.objects.get(
                    id=conversation_id, 
                    user=request.user
                )
            except Conversation.DoesNotExist:
                return Response(
                    {'error': 'Conversation not found'}, 
                    status=status.HTTP_404_NOT_FOUND
                )
        else:
            conversation = Conversation.objects.create(
                user=request.user,
                mode=mode
            )
        
        # Save user message
        user_message = Message.objects.create(
            conversation=conversation,
            content=message_text,
            is_user=True
        )
        
        # Get or create user context
        context, created = UserContext.objects.get_or_create(user=request.user)
        
        # Generate AI response
        ai = EmpatheticAI()
        ai_response = ai.generate_response(
            message_text, 
            context={
                'mood_history': context.mood_history,
                'triggers': context.triggers,
                'coping_strategies': context.coping_strategies
            },
            mode=mode
        )
        
        # Save AI message
        ai_message = Message.objects.create(
            conversation=conversation,
            content=ai_response['response'],
            is_user=False,
            emotion_detected=ai_response.get('emotion', '')
        )
        
        # Update user context if mood check
        if mode == 'mood_check' and 'mood_score' in ai_response:
            context.add_mood_entry(
                mood=ai_response['emotion'],
                score=ai_response['mood_score']
            )
            context.last_mood_check = timezone.now()
            context.save()
        
        # Update conversation
        conversation.updated_at = timezone.now()
        conversation.save()
        
        return Response({
            'conversation_id': conversation.id,
            'user_message': MessageSerializer(user_message).data,
            'ai_message': MessageSerializer(ai_message).data,
            'suggestions': ai_response.get('suggestions', []),
            'exercise_type': ai_response.get('exercise_type'),
            'emotion_detected': ai_response.get('emotion')
        })
    
    @action(detail=True, methods=['get'])
    def history(self, request, pk=None):
        """Get conversation history"""
        conversation = self.get_object()
        messages = conversation.messages.all()
        return Response(MessageSerializer(messages, many=True).data)
    
    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get active conversations"""
        conversations = self.get_queryset().filter(is_active=True)
        return Response(ConversationSerializer(conversations, many=True).data)

class UserContextViewSet(viewsets.ModelViewSet):
    serializer_class = UserContextSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return UserContext.objects.filter(user=self.request.user)
    
    @action(detail=False, methods=['get'])
    def mood_trends(self, request):
        """Get mood trends for the user"""
        context, created = UserContext.objects.get_or_create(user=request.user)
        
        # Calculate mood trends (last 30 days)
        recent_moods = [m for m in context.mood_history 
                       if timezone.now() - timezone.datetime.fromisoformat(m['timestamp']) 
                       < timezone.timedelta(days=30)]
        
        if not recent_moods:
            return Response({'message': 'No mood data available yet'})
        
        # Calculate average mood score
        avg_score = sum(m['score'] for m in recent_moods) / len(recent_moods)
        
        # Group by emotion
        emotion_counts = {}
        for mood in recent_moods:
            emotion = mood['mood']
            emotion_counts[emotion] = emotion_counts.get(emotion, 0) + 1
        
        return Response({
            'average_mood_score': round(avg_score, 2),
            'total_entries': len(recent_moods),
            'emotion_distribution': emotion_counts,
            'recent_moods': recent_moods[-7:]  # Last 7 entries
        })