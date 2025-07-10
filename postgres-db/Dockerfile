FROM postgres:17.4-bookworm

USER root

RUN apt-get update && apt-get install -y pgloader nodejs npm \
    && npm install -g nunjucks \
    && rm -rf /var/lib/apt/lists/*

# Копируем все файлы одним слоем
COPY \
    ./render_template.js \
    ./import.load.tpl \
    ./import.unload.tpl \
    ./set_pg_logs.sh \
    ./docker-entrypoint.sh \
    /

RUN chmod +x /render_template.js /docker-entrypoint.sh /set_pg_logs.sh && \
    sed -i 's/\r$//' /render_template.js /import.load.tpl /import.unload.tpl /set_pg_logs.sh /docker-entrypoint.sh

RUN mkdir -p /docker-entrypoint-initdb.d && mv /set_pg_logs.sh /docker-entrypoint-initdb.d/

RUN mkdir -p /app && chown -R postgres:postgres /app

WORKDIR /app
ENV TZ='Europe/Moscow'

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["postgres"]

# docker logs -f --tail 10 db_postgres_container
