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

# CloudWatch Application Signals via ADOT. OTel is initialized in-process in
# lambda_handler.py (the layer's /opt/otel-instrument exec wrapper breaks on
# container images), so no AWS_LAMBDA_EXEC_WRAPPER. The aws_configurator detects
# the Lambda environment and wires X-Ray traces + App Signals EMF metrics.
ENV DJANGO_SETTINGS_MODULE=djaret.settings \
    OTEL_PYTHON_DISTRO=aws_distro \
    OTEL_PYTHON_CONFIGURATOR=aws_configurator \
    OTEL_AWS_APPLICATION_SIGNALS_ENABLED=true \
    OTEL_PYTHON_DISABLED_INSTRUMENTATIONS=aws-lambda \
    OTEL_SERVICE_NAME=djaret-backend

CMD ["lambda_handler.handler"]
