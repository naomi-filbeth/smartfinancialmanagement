from rest_framework.views import exception_handler
from django.conf import settings

def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is not None:
        origin = context['request'].META.get('HTTP_ORIGIN')
        if origin in settings.CORS_ALLOWED_ORIGINS:
            response['Access-Control-Allow-Origin'] = origin
            response['Access-Control-Allow-Credentials'] = 'true'
            response['Access-Control-Allow-Methods'] = ', '.join(settings.CORS_ALLOW_METHODS)
            response['Access-Control-Allow-Headers'] = ', '.join(settings.CORS_ALLOW_HEADERS)
    return response