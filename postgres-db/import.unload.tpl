LOAD DATABASE
     FROM postgresql://{{ POSTGRES_USER }}:{{ POSTGRES_PASSWORD }}@localhost:5432/{{ POSTGRES_DB }}
     INTO sqlite:///app/database-sql-lite.db

WITH include drop, create tables, create indexes, reset sequences
