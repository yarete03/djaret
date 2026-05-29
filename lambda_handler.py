"""AWS Lambda entrypoint: adapts API Gateway proxy events to the Django WSGI app.

Instrumentation is NOT initialized here — the ADOT layer's exec wrapper
(AWS_LAMBDA_EXEC_WRAPPER=/opt/otel-instrument) auto-instruments and flushes
CloudWatch Application Signals telemetry per invocation, lazy-importing this
handler (so no circular-import problem).
"""
import os

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "djaret.settings")

from apig_wsgi import make_lambda_handler
from djaret.wsgi import application

handler = make_lambda_handler(application)
