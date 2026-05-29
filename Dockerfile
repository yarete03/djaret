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
        unzip \
        wget \
    && rm -rf /var/lib/apt/lists/*

# CloudWatch Application Signals: AWS Distro for OpenTelemetry (ADOT) Python.
# Container images can't attach Lambda layers, so bake the layer.zip contents
# into /opt (ADOT distro + collector extension + /opt/otel-instrument wrapper).
RUN wget -q https://github.com/aws-observability/aws-otel-python-instrumentation/releases/latest/download/layer.zip -O /tmp/layer.zip \
    && mkdir -p /opt \
    && unzip -q /tmp/layer.zip -d /opt/ \
    && chmod -R 755 /opt/ \
    && rm /tmp/layer.zip

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY manage.py .
COPY rds-global-bundle-ca.pem .

COPY djaret/ ./djaret/
COPY djaret_app/ ./djaret_app/

ENV PORT=8000

# ADOT / Application Signals config. AWS_LAMBDA_EXEC_WRAPPER is ignored here
# (Lambda Web Adapter bypasses the managed runtime bootstrap that reads it),
# so the wrapper is invoked explicitly as the CMD prefix below instead.
ENV OTEL_PYTHON_DISTRO=aws_distro \
    OTEL_PYTHON_CONFIGURATOR=aws_configurator \
    OTEL_PYTHON_DISABLED_INSTRUMENTATIONS=none \
    OTEL_SERVICE_NAME=djaret-backend

CMD ["/opt/otel-instrument", "gunicorn", "djaret.wsgi:application", "--bind", "0.0.0.0:8000"]
