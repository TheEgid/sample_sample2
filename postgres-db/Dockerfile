FROM postgres:17.4-bookworm

USER root

RUN apt-get update && apt-get install -y pgloader && rm -rf /var/lib/apt/lists/*

COPY ./docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh

RUN sed -i 's/\r$//' /docker-entrypoint.sh

ENV TZ 'Europe/Moscow'

USER postgres

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["postgres"]
