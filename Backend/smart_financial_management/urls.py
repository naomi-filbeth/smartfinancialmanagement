
from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include ('user.urls')),
    path('api/auth/financial', include('financial_management.urls')),
]
  