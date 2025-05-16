from django.db import models

class User(models.Model):
    username = models.CharField(max_length=50, unique=True)
    email = models.EmailField(unique=True)
    password = models.CharField(max_length=255)  # Store hashed password
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.username
    
class Meta:
        db_table = 'auth_user'  # Match the table name used in previous MySQL schema
        verbose_name = 'User'
        verbose_name_plural = 'Users'