import os

# post_fork runs before the wsgi app (which sets DJANGO_SETTINGS_MODULE) loads,
# so set it here at config-module level (master, pre-fork -> inherited by workers).
# Without it, OTel's Django instrumentation reads empty global_settings -> crash.
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "djaret.settings")


# Gunicorn is a pre-fork server. The OpenTelemetry SDK's BatchSpanProcessor runs
# a background export thread that is NOT fork-safe, so initializing OTel in the
# master (e.g. via `opentelemetry-instrument`) leaves workers uninstrumented /
# unable to export. Instead initialize per worker in post_fork.
#
# initialize() applies auto-instrumentation AND configures the SDK from the
# OTEL_* environment, so it honors OTEL_PYTHON_DISTRO=aws_distro, the exporter
# choice (console locally, OTLP->collector in Lambda), service name, etc.
def post_fork(server, worker):
    from opentelemetry.instrumentation.auto_instrumentation import initialize
    initialize()
