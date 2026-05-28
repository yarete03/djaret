FROM public.ecr.aws/docker/library/python:3.12-slim

# Install Lambda Web Adapter
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.9.1 \
    /lambda-adapter /opt/extensions/lambda-adapter

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

ENV PORT=8000

CMD ["gunicorn", "djaret.wsgi:application", "--bind", "0.0.0.0:8000"]
