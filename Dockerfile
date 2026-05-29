FROM public.ecr.aws/docker/library/python:3.12-slim

# Install Lambda Web Adapter
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.9.1 \
    /lambda-adapter /opt/extensions/lambda-adapter

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        pkg-config \
        default-libmysqlclient-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install -r requirements.txt
# Install the instrumentation libraries matching installed packages (Django, dbapi/MySQL).
RUN opentelemetry-bootstrap -a install

COPY manage.py .
COPY rds-global-bundle-ca.pem .
COPY gunicorn.conf.py .

COPY djaret/ ./djaret/
COPY djaret_app/ ./djaret_app/

ENV PORT=8000

# ADOT collector-less export: the aws_distro SigV4-signs OTLP straight to the
# CloudWatch X-Ray OTLP endpoint (no collector). OTel is initialized per gunicorn
# worker in gunicorn.conf.py (post_fork) because the pre-fork model breaks the SDK
# export thread. initialize() reads these env vars in each worker.
# Requires X-Ray Transaction Search enabled + xray:PutTraceSegments on the role.
ENV DJANGO_SETTINGS_MODULE=djaret.settings \
    OTEL_PYTHON_DISTRO=aws_distro \
    OTEL_PYTHON_CONFIGURATOR=aws_configurator \
    OTEL_PYTHON_DISABLED_INSTRUMENTATIONS=none \
    OTEL_SERVICE_NAME=djaret-backend \
    OTEL_AWS_APPLICATION_SIGNALS_ENABLED=false \
    OTEL_TRACES_EXPORTER=otlp \
    OTEL_METRICS_EXPORTER=none \
    OTEL_LOGS_EXPORTER=none \
    OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf \
    OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=https://xray.eu-west-1.amazonaws.com/v1/traces

CMD ["gunicorn", "-c", "gunicorn.conf.py", "djaret.wsgi:application", "--bind", "0.0.0.0:8000"]
