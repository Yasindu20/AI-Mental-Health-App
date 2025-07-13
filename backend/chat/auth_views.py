# chat/auth_views.py
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.models import User
from django.views.decorators.csrf import csrf_exempt
from .serializers import UserSerializer

@api_view(['POST'])
@permission_classes([AllowAny])
@csrf_exempt
def register(request):
    username = request.data.get('username')
    password = request.data.get('password')
    email = request.data.get('email', '')
    
    if not username or not password:
        return Response(
            {'error': 'Username and password required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    if User.objects.filter(username=username).exists():
        return Response(
            {'error': 'Username already exists'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    user = User.objects.create_user(username=username, password=password, email=email)
    
    # Create token for the user
    token, created = Token.objects.get_or_create(user=user)
    
    # Log the user in (create session)
    login(request, user)
    
    return Response({
        'user': UserSerializer(user).data,
        'token': token.key
    })

@api_view(['POST'])
@permission_classes([AllowAny])
@csrf_exempt
def login_view(request):
    username = request.data.get('username')
    password = request.data.get('password')
    
    user = authenticate(request, username=username, password=password)
    if user:
        # Create or get token
        token, created = Token.objects.get_or_create(user=user)
        
        # Log the user in (create session)
        login(request, user)
        
        return Response({
            'user': UserSerializer(user).data,
            'token': token.key
        })
    
    return Response(
        {'error': 'Invalid credentials'}, 
        status=status.HTTP_401_UNAUTHORIZED
    )

@api_view(['POST'])
def logout_view(request):
    # Delete the user's token
    if hasattr(request.user, 'auth_token'):
        request.user.auth_token.delete()
    
    # Also log out of session
    logout(request)
    
    return Response({'message': 'Logged out successfully'})