"""
WSGI config for djangoarticleapp project.

It exposes the WSGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/5.1/howto/deployment/wsgi/
"""

import os
from prometheus_client import start_http_server, Counter

from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'djangoarticleapp.settings')

application = get_wsgi_application()

start_http_server(8001)
REQUEST_COUNT = Counter('django_request_count', 'Total HTTP requests', ['method','endpoint'])
