FROM postgres:17.4-bookworm

USER root

RUN apt-get update && apt-get install -y \
    pgloader \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

COPY ./docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh

RUN sed -i 's/\r$$//' /docker-entrypoint.sh

RUN mkdir -p /app && chmod 777 /app

ENV TZ 'Europe/Moscow'

USER postgres

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["postgres"]
