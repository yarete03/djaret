# ---------- builder: compile deps, fetch ADOT layer ----------
FROM public.ecr.aws/lambda/python:3.12 AS builder

# gcc + headers only needed to BUILD mysqlclient; unzip only to extract the
# layer. None of this ships to the runtime image (see slim runtime stage below).
RUN dnf install -y gcc mariadb-connector-c-devel unzip && dnf clean all

# CloudWatch Application Signals — AWS's native Lambda path: the ADOT layer.
# Container Lambdas can't attach layers, so bake layer.zip into /opt.
RUN curl -sL https://github.com/aws-observability/aws-otel-python-instrumentation/releases/latest/download/layer.zip -o /tmp/layer.zip \
    && mkdir -p /opt \
    && unzip -q /tmp/layer.zip -d /opt/ \
    && chmod -R 755 /opt/ \
    && rm /tmp/layer.zip

COPY requirements.txt /tmp/requirements.txt
RUN pip install --upgrade pip && pip install -r /tmp/requirements.txt

# ---------- runtime: slim, no compiler/headers ----------
FROM public.ecr.aws/lambda/python:3.12

# Runtime shared lib for mysqlclient's C extension (libmariadb) — no compiler,
# no headers. Keeps the runtime image small =>
# faster image pull on first-ever cold start and scale-out to new workers.
RUN dnf install -y mariadb-connector-c shadow-utils && dnf clean all \
    && /usr/sbin/useradd --uid 1000 --create-home --shell /sbin/nologin djaret

# Bring over the ADOT layer and the installed site-packages from the builder.
COPY --from=builder /opt /opt
RUN rm -rf /var/lang/lib/python3.12/site-packages
COPY --from=builder /var/lang/lib/python3.12/site-packages /var/lang/lib/python3.12/site-packages

COPY manage.py rds-global-bundle-ca.pem lambda_handler.py ${LAMBDA_TASK_ROOT}/
COPY djaret/ ${LAMBDA_TASK_ROOT}/djaret/
COPY djaret_app/ ${LAMBDA_TASK_ROOT}/djaret_app/

# Pre-compile bytecode at build time so cold init doesn't pay .py -> .pyc
# compilation on first import (Django + deps).
RUN python -m compileall -q /var/lang/lib/python3.12/site-packages ${LAMBDA_TASK_ROOT}

ENV DJANGO_SETTINGS_MODULE=djaret.settings \
    AWS_LAMBDA_EXEC_WRAPPER=/opt/otel-instrument \
    OTEL_SERVICE_NAME=djaret-lambda-backend-pro \
    OTEL_PYTHON_DISABLED_INSTRUMENTATIONS=aiohttp-client,aiokafka,aiopg,aio-pika,asyncpg,aws_crewai,aws_langchain,aws_llama-index,aws_mcp,aws_openai_agents,boto,boto3,cassandra,celery,confluent_kafka,elasticsearch,falcon,fastapi,flask,grpc_aio_client,grpc_aio_server,grpc_client,grpc_server,httpx,jinja2,kafka,mysql,openai_agents,pika,psycopg2,pymemcache,pymongo,pymysql,pyramid,redis,remoulade,requests,sqlalchemy,sqlite3,starlette,tornado,tortoiseorm \
    OTEL_PYTHON_LOG_CORRELATION=true \
    OTEL_TRACES_SAMPLER=always_on

USER djaret

CMD ["lambda_handler.handler"]
