"""AWS Lambda entrypoint: adapts API Gateway proxy events to the Django WSGI app,
with CloudWatch Application Signals (ADOT) instrumentation initialized in-process.

The ADOT layer's exec wrapper (/opt/otel-instrument) breaks on container images
(it sets the handler via _HANDLER env, but the container Runtime Interface Client
reads the handler from argv). So we skip the wrapper and initialize OpenTelemetry
programmatically here, then force-flush per invocation (Lambda freezes between
invokes, so the background export thread can't be relied on).
"""
import os

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "djaret.settings")

# Apply ADOT auto-instrumentation + configure the SDK (aws_distro/aws_configurator
# read from env). On Lambda the configurator wires X-Ray traces + App Signals EMF.
from opentelemetry.instrumentation.auto_instrumentation import initialize

initialize()

from opentelemetry import trace
from apig_wsgi import make_lambda_handler
from djaret.wsgi import application

_wsgi_handler = make_lambda_handler(application)


def handler(event, context):
    try:
        return _wsgi_handler(event, context)
    finally:
        provider = trace.get_tracer_provider()
        force_flush = getattr(provider, "force_flush", None)
        if force_flush is not None:
            try:
                # Bounded so a slow/unreachable exporter can never block the
                # response for the full Lambda timeout (caused a 504 once).
                force_flush(timeout_millis=3000)
            except Exception:
                pass
