from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import User
from .serializers import RegisterSerializer, LoginSerializer, ForgotPasswordSerializer, ValidateTokenSerializer, UserSerializer
from django.contrib.auth.hashers import make_password, check_password
from rest_framework_simplejwt.tokens import AccessToken
from django.core.mail import send_mail
from django.conf import settings
import logging

# Set up logging
logger = logging.getLogger(__name__)

class RegisterView(APIView):
    def post(self, request):
        logger.debug(f"Registration request data: {request.data}")
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
          
            user_serializer = UserSerializer(data=serializer.validated_data)
            if user_serializer.is_valid():
                user = user_serializer.save()  # Password is hashed in UserSerializer
                logger.debug(f"User {user.username} registered with hash: {user.password}")
                return Response(
                    {'success': True, 'message': 'User registered'},
                    status=status.HTTP_200_OK
                )
            logger.debug(f"UserSerializer errors: {user_serializer.errors}")
            return Response(
                {'success': False, 'message': user_serializer.errors},
                status=status.HTTP_400_BAD_REQUEST
            )
        logger.debug(f"RegisterSerializer errors: {serializer.errors}")
        return Response(
            {'success': False, 'message': serializer.errors},
            status=status.HTTP_400_BAD_REQUEST
        )

class LoginView(APIView):
    def post(self, request):
        logger.debug(f"Login request data: {request.data}")
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            username = serializer.validated_data['username']
            password = serializer.validated_data['password']

            logger.debug(f"Login attempt for username: {username}")

            try:
                user = User.objects.get(username__iexact=username)  # Case-insensitive lookup
                logger.debug(f"User found: {user.username}, stored password hash: {user.password}")
            except User.DoesNotExist:
                logger.debug(f"User {username} not found")
                return Response(
                    {'success': False, 'message': 'Invalid credentials'},
                    status=status.HTTP_401_UNAUTHORIZED
                )

            if not check_password(password, user.password):
            
                logger.debug(f"Password check failed for {username}. Input password: {password}")
                return Response(
                    {'success': False, 'message': 'Invalid credentials'},
                    status=status.HTTP_401_UNAUTHORIZED
                )

            token = AccessToken.for_user(user)
            logger.debug(f"Login successful for {username}")
            return Response(
                {'message': 'login successfully','success': True, 'token': str(token)},
                status=status.HTTP_200_OK
            )
        logger.debug(f"LoginSerializer errors: {serializer.errors}")
        return Response(
            {'success': False, 'message': serializer.errors},
            status=status.HTTP_400_BAD_REQUEST
        )

class ForgotPasswordView(APIView):
    def post(self, request):
        serializer = ForgotPasswordSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']

            try:
                user = User.objects.get(email=email)
            except User.DoesNotExist:
                return Response(
                    {'success': False, 'message': 'Email not found'},
                    status=status.HTTP_404_NOT_FOUND
                )

            try:
                send_mail(
                    subject='Password Reset Request',
                    message='Click the link to reset your password: [Reset Link]',
                    from_email=settings.EMAIL_HOST_USER,
                    recipient_list=[email],
                    fail_silently=False,
                )
                return Response(
                    {'success': True, 'message': 'Password reset email sent'},
                    status=status.HTTP_200_OK
                )
            except Exception as e:
                return Response(
                    {'success': False, 'message': 'Failed to send email'},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        return Response(
            {'success': False, 'message': serializer.errors},
            status=status.HTTP_400_BAD_REQUEST
        )

class ValidateTokenView(APIView):
    def get(self, request):
        token = request.headers.get('Authorization', '').split(' ')[1] if 'Authorization' in request.headers else None

        if not token:
            return Response(
                {'success': False, 'message': 'No token provided'},
                status=status.HTTP_401_UNAUTHORIZED
            )

        try:
            access_token = AccessToken(token)
            user_id = access_token['user_id']
            user = User.objects.get(id=user_id)
            serializer = ValidateTokenSerializer({'username': user.username})
            return Response(
                {'success': True, 'user': serializer.data},
                status=status.HTTP_200_OK
            )
        except Exception as e:
            return Response(
                {'success': False, 'message': 'Invalid token'},
                status=status.HTTP_401_UNAUTHORIZED
            )