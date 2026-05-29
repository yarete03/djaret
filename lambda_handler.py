"""AWS Lambda entrypoint: adapts API Gateway proxy events to the Django WSGI app.

Handler-Lambda model (replaces Lambda Web Adapter + gunicorn) so the CloudWatch
Application Signals ADOT layer wrapper (/opt/otel-instrument) can instrument and
flush telemetry synchronously per invocation — no freeze/agent problems.
"""
import os

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "djaret.settings")

from apig_wsgi import make_lambda_handler
from djaret.wsgi import application

# apig-wsgi auto-detects API Gateway payload format v1/v2 and ALB events.
handler = make_lambda_handler(application)
