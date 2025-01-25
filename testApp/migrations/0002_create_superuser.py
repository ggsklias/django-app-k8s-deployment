# Generated by Django 5.1.4 on 2025-01-06 14:00

from django.db import migrations
from django.utils import timezone


def create_superuser(apps, schema_editor):
    from django.contrib.auth import get_user_model

    User = get_user_model()

    if User.objects.exists():
        return
    
    superuser = User.objects.create_superuser(
        username="megivh",
        email="megivh@example.com",
        password="lagsl137",
        last_login=timezone.now()
    )
    superuser.save()

class Migration(migrations.Migration):

    dependencies = [
        ('testApp', '0001_initial'),
    ]

    operations = [
        migrations.RunPython(create_superuser)
    ]



    