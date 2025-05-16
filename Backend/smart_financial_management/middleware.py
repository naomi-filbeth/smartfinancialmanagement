from django.conf import settings
from django.http import HttpResponse

class EnforceCorsMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)
        return self.process_response(request, response)

    def process_response(self, request, response):
        origin = request.META.get('HTTP_ORIGIN')
        if origin in settings.CORS_ALLOWED_ORIGINS:
            response['Access-Control-Allow-Origin'] = origin
            response['Access-Control-Allow-Credentials'] = 'true'
            response['Access-Control-Allow-Methods'] = ', '.join(settings.CORS_ALLOW_METHODS)
            response['Access-Control-Allow-Headers'] = ', '.join(settings.CORS_ALLOW_HEADERS)
        return response