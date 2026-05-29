FROM public.ecr.aws/lambda/python:3.12

# Build deps for mysqlclient + unzip to extract the ADOT layer.
RUN dnf install -y gcc mariadb-connector-c-devel unzip && dnf clean all

# CloudWatch Application Signals: AWS Distro for OpenTelemetry (ADOT) Python layer.
# Container Lambdas can't attach layers, so extract layer.zip into /opt. In the
# handler-Lambda model the /opt/otel-instrument wrapper instruments the handler
# and flushes telemetry synchronously per invocation (no freeze/agent issues).
RUN curl -sL https://github.com/aws-observability/aws-otel-python-instrumentation/releases/latest/download/layer.zip -o /tmp/layer.zip \
    && mkdir -p /opt \
    && unzip -q /tmp/layer.zip -d /opt/ \
    && chmod -R 755 /opt/ \
    && rm /tmp/layer.zip

COPY requirements.txt ${LAMBDA_TASK_ROOT}/
RUN pip install -r ${LAMBDA_TASK_ROOT}/requirements.txt

COPY manage.py rds-global-bundle-ca.pem lambda_handler.py ${LAMBDA_TASK_ROOT}/
COPY djaret/ ${LAMBDA_TASK_ROOT}/djaret/
COPY djaret_app/ ${LAMBDA_TASK_ROOT}/djaret_app/

# AWS_LAMBDA_EXEC_WRAPPER activates the ADOT layer (Application Signals enabled by
# default). OTEL_PYTHON_DISABLED_INSTRUMENTATIONS=none enables Django + MySQL spans.
ENV DJANGO_SETTINGS_MODULE=djaret.settings \
    AWS_LAMBDA_EXEC_WRAPPER=/opt/otel-instrument \
    OTEL_SERVICE_NAME=djaret-backend \
    OTEL_PYTHON_DISABLED_INSTRUMENTATIONS=none

# Lambda handler: lambda_handler.py -> handler (apig-wsgi wrapping Django WSGI).
CMD ["lambda_handler.handler"]
