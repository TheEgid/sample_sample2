FROM python:3.11-bookworm

WORKDIR /app

RUN apt-get update && apt-get install -y bash

RUN pip install --upgrade pip && \
    pip install --no-cache-dir sqlglot sqlglot[rs]

COPY convert.py .

RUN chmod +x convert.py
