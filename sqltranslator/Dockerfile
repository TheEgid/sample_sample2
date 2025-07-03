FROM perl:latest

RUN curl -L http://cpanmin.us | perl - App::cpanminus

RUN cpanm --notest DBI
RUN cpanm --notest SQL::Translator

WORKDIR /app/backup

# # ENTRYPOINT ["sqlt"]
