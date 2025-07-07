from rest_framework import serializers
from .models import Conversation, Message, UserContext
from django.contrib.auth.models import User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email']

class MessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Message
        fields = ['id', 'content', 'is_user', 'created_at', 'emotion_detected']

class ConversationSerializer(serializers.ModelSerializer):
    messages = MessageSerializer(many=True, read_only=True)
    
    class Meta:
        model = Conversation
        fields = ['id', 'mode', 'created_at', 'updated_at', 'is_active', 'messages']

class UserContextSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserContext
        fields = ['mood_history', 'preferences', 'triggers', 'coping_strategies', 
                 'personality_traits', 'last_mood_check']

class ChatRequestSerializer(serializers.Serializer):
    message = serializers.CharField()
    conversation_id = serializers.IntegerField(required=False)
    mode = serializers.ChoiceField(choices=['unstructured', 'cbt_exercise', 
                                           'mindfulness', 'mood_check'], 
                                  default='unstructured')