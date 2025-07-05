include ./fullstack/.env
export

COMPOSE_BAKE=true

LANG=ru_RU.UTF-8


all: run clean # restore test clean run


run:
	@docker compose build
	@docker compose up -d
	@docker ps


runner:
	@docker compose up


stop:
	@docker compose down


clean:
	@docker system prune -f
	@docker system prune -f --volumes


# logs:
# 	@sudo htpasswd -b .htpasswd $(ADMIN_USER) $(ADMIN_PASSW)
# 	@goaccess ./log/nginx/access.log -o ./log/report/report.html --log-format COMBINED --html-report-title "Статистика"


up:
	@sudo dnf --refresh update && sudo dnf upgrade

SQLITE_DUMP := $(shell pwd)/backup/backup.sql
PG_DUMP := $(shell pwd)/backup/backup_postgres.sql
BACKUP_DIR := $(shell pwd)/backup
IMAGE_NAME := sqltranslator_container


restore_sqllite:
	@if [ ! -f $(SQLITE_DUMP) ]; then \
		echo "Файл дампа $(SQLITE_DUMP) не найден!"; \
		exit 1; \
	fi
	@echo "Останавливаем контейнер db_sqlite_container..."
	@docker stop db_sqlite_container || echo "Контейнер уже остановлен или не запущен."
	@echo "Удаляем файл базы из локальной папки ./main-applic/prisma..."
	@rm -f ./main-applic/prisma/database-sql-lite.db || echo "Файл базы не найден"
	@echo "Запускаем контейнер db_sqlite_container..."
	@docker start db_sqlite_container
	@sleep 5
	@if ! docker ps --filter "name=db_sqlite_container" --filter "status=running" | grep -q db_sqlite_container; then \
		echo "Контейнер db_sqlite_container не запущен!"; \
		exit 1; \
	fi
	@echo "Восстанавливаем базу из дампа..."
	@if sed '/BEGIN TRANSACTION;/d;/COMMIT;/d' $(SQLITE_DUMP) | docker exec -i db_sqlite_container sqlite3 /database/database-sql-lite.db; then \
		echo "Восстановление базы завершено успешно! $$(date +%F--%H-%M)"; \
	else \
		echo "Ошибка при восстановлении базы!"; \
		exit 1; \
	fi


backup_sqllite:
	@echo "Создаём дамп базы SQLite с DROP TABLE и DROP INDEX..."
	@mkdir -p $(BACKUP_DIR)
	@chmod 777 $(BACKUP_DIR)
	@if docker exec -i db_sqlite_container sh -c '\
		echo "BEGIN TRANSACTION;"; \
		sqlite3 /database/database-sql-lite.db "SELECT '\''DROP TABLE IF EXISTS '\'' || name || '\'';'\'' FROM sqlite_master WHERE type='\''table'\'' AND name NOT LIKE '\''sqlite_%'\'';"; \
		sqlite3 /database/database-sql-lite.db "SELECT '\''DROP INDEX IF EXISTS '\'' || name || '\'';'\'' FROM sqlite_master WHERE type='\''index'\'';"; \
		sqlite3 /database/database-sql-lite.db ".dump"; \
		echo "COMMIT;"; \
	' > $(SQLITE_DUMP); then \
		chmod 777 $(SQLITE_DUMP); \
		echo "Дамп успешно создан! $$(date +%F--%H-%M)"; \
	else \
		echo "Ошибка при создании дампа базы!"; \
		exit 1; \
	fi


convert_to_postgres: backup_sqllite
	@echo "Проверяем содержимое исходного дампа:"
	@head -n 2 $(SQLITE_DUMP)
	@echo "Проверяем версию sqlglot в контейнере..."
	@docker run --rm $(IMAGE_NAME) bash -c "/usr/local/bin/python3 -c 'import sqlglot; print(sqlglot.__version__)'"
	@echo "Конвертируем дамп SQLite в PostgreSQL..."
	@docker run --rm -v $(BACKUP_DIR):/app/backup $(IMAGE_NAME) /usr/local/bin/python3 /app/convert.py /app/backup/backup.sql /app/backup/backup_postgres.sql
	@if [ -f "$(PG_DUMP)" ]; then \
		ls -lh $(PG_DUMP); \
	else \
		echo "Ошибка: файл $(PG_DUMP) не найден!"; \
		exit 1; \
	fi
	@echo "Готово"
