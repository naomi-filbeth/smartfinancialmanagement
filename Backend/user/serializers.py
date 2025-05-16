from rest_framework import serializers
from .models import User
from django.contrib.auth.hashers import make_password

class UserSerializer(serializers.ModelSerializer):
    """
    Serializer for the User model.
    Used for creating and retrieving user data.
    """
    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'created_at']
        extra_kwargs = {
            'password': {'write_only': True},
            'created_at': {'read_only': True},
        }

    def validate(self, data):
        """
        Validate that username and email are unique.
        """
        username = data.get('username')
        email = data.get('email')

        if User.objects.filter(username=username).exists():
            raise serializers.ValidationError({'username': 'Username already exists'})
        
        if User.objects.filter(email=email).exists():
            raise serializers.ValidationError({'email': 'Email already exists'})

        return data

    def create(self, validated_data):
        """
        Hash the password before saving the user.
        """
        validated_data['password'] = make_password(validated_data['password'])
        return super().create(validated_data)

class RegisterSerializer(serializers.Serializer):
    """
    Serializer for user registration.
    Validates username, email, and password.
    """
    username = serializers.CharField(max_length=50, required=True)
    email = serializers.EmailField(required=True)
    password = serializers.CharField(max_length=255, required=True, write_only=True)

class LoginSerializer(serializers.Serializer):
    """
    Serializer for user login.
    Validates username and password.
    """
    username = serializers.CharField(max_length=50, required=True)
    password = serializers.CharField(max_length=255, required=True, write_only=True)

class ForgotPasswordSerializer(serializers.Serializer):
    """
    Serializer for forgot password requests.
    Validates email.
    """
    email = serializers.EmailField(required=True)

class ValidateTokenSerializer(serializers.Serializer):
    """
    Serializer for token validation response.
    Returns user data.
    """
    username = serializers.CharField(max_length=50)