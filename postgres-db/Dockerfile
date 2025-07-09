FROM postgres:17.4-bookworm

USER root

RUN apt-get update && apt-get install -y pgloader nodejs npm \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g nunjucks

COPY ./render_template.js /render_template.js
RUN chmod +x /render_template.js
RUN sed -i 's/\r$//' /render_template.js

COPY ./import.load.tpl /import.load.tpl
RUN sed -i 's/\r$//' /import.load.tpl

COPY ./import.load.tpl /import.reload.tpl
RUN sed -i 's/\r$//' /import.reload.tpl

COPY ./set_pg_logs.sh /docker-entrypoint-initdb.d/set_pg_logs.sh
RUN chmod +x /docker-entrypoint-initdb.d/set_pg_logs.sh
RUN sed -i 's/\r$//' /docker-entrypoint-initdb.d/set_pg_logs.sh

COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
RUN sed -i 's/\r$//' /docker-entrypoint.sh

RUN mkdir -p /app && chown -R postgres:postgres /app

ENV TZ='Europe/Moscow'

# USER postgres

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["postgres"]

# docker logs -f --tail 10 db_postgres_container
