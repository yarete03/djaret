FROM public.ecr.aws/lambda/python:3.12

# Build deps for mysqlclient.
RUN dnf install -y gcc mariadb-connector-c-devel && dnf clean all

COPY requirements.txt ${LAMBDA_TASK_ROOT}/
RUN pip install -r ${LAMBDA_TASK_ROOT}/requirements.txt
# Install instrumentation libraries matching installed packages (Django, dbapi/MySQL).
RUN opentelemetry-bootstrap -a install

COPY manage.py rds-global-bundle-ca.pem lambda_handler.py ${LAMBDA_TASK_ROOT}/
COPY djaret/ ${LAMBDA_TASK_ROOT}/djaret/
COPY djaret_app/ ${LAMBDA_TASK_ROOT}/djaret_app/

# OTel initialized in-process in lambda_handler.py (the layer's /opt/otel-instrument
# exec wrapper breaks container RIC). This Lambda is in a VPC (for RDS) with no
# internet egress, so SDK traces reach X-Ray via an X-Ray VPC interface endpoint
# (private DNS resolves xray.<region>.amazonaws.com to it). SigV4-signed, collector-
# less. App Signals metrics exporter stays OFF (would need a localhost agent we don't
# run); App Signals service map / RED come from the Lambda platform's X-Ray Active
# tracing. force_flush in lambda_handler is bounded (3s) so a slow export can't 504.
ENV DJANGO_SETTINGS_MODULE=djaret.settings \
    OTEL_PYTHON_DISTRO=aws_distro \
    OTEL_PYTHON_CONFIGURATOR=aws_configurator \
    OTEL_PYTHON_DISABLED_INSTRUMENTATIONS=aws-lambda \
    OTEL_SERVICE_NAME=djaret-backend \
    OTEL_AWS_APPLICATION_SIGNALS_ENABLED=false \
    OTEL_TRACES_EXPORTER=otlp \
    OTEL_METRICS_EXPORTER=none \
    OTEL_LOGS_EXPORTER=none \
    OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf \
    OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=https://xray.eu-west-1.amazonaws.com/v1/traces \
    OTEL_TRACES_SAMPLER=always_on

CMD ["lambda_handler.handler"]
