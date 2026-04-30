FROM apache/superset:latest

USER root

RUN apt-get update && apt-get install -y \
    pkg-config \
    default-libmysqlclient-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN /app/.venv/bin/python -m ensurepip --upgrade || true
RUN /app/.venv/bin/python -m pip install psycopg2-binary pymysql mysqlclient sqlalchemy-trino trino

USER superset