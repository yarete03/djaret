FROM public.ecr.aws/lambda/python:3.12

# Build deps for mysqlclient + unzip to extract the ADOT layer.
RUN dnf install -y gcc mariadb-connector-c-devel unzip && dnf clean all

# CloudWatch Application Signals — AWS's native Lambda path: the ADOT layer.
# Container Lambdas can't attach layers, so bake layer.zip into /opt. The
# /opt/otel-instrument exec wrapper (AWS_LAMBDA_EXEC_WRAPPER below) instruments
# the handler and runs the App Signals Lambda EMF mode — metrics emit as EMF to
# CloudWatch Logs (no agent, no egress), traces to X-Ray (via the VPC endpoint).
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

# AWS_LAMBDA_EXEC_WRAPPER activates the ADOT layer (App Signals on by default).
# DISABLED_INSTRUMENTATIONS=none enables Django + MySQL spans (the wrapper's
# default list otherwise disables them); the wrapper still appends aws-lambda.
# The instrumentation + per-invoke flush is handled by the layer's otel_wrapper,
# which lazy-imports our handler (no circular import) — so lambda_handler.py does
# NOT call initialize() itself.
ENV DJANGO_SETTINGS_MODULE=djaret.settings \
    AWS_LAMBDA_EXEC_WRAPPER=/opt/otel-instrument \
    OTEL_SERVICE_NAME=djaret-backend-pro \
    OTEL_PYTHON_DISABLED_INSTRUMENTATIONS=none

CMD ["lambda_handler.handler"]
