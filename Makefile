include ./main-applic/.env
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


up:
	@sudo dnf --refresh update && sudo dnf upgrade

SQLITE_DUMP := $(shell pwd)/backup/backup.sql
PG_DUMP := $(shell pwd)/backup/backup_postgres.sql
BACKUP_DIR := $(shell pwd)/backup
# //имя через - docker images | grep sqltranslator
IMAGE_NAME := sample_sample2-sqltranslator


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


SQLITE_DATABASE := ./main-applic/prisma/database-sql-lite.db
POSTGRES_CONTAINER := db_postgres_container
IMPORT_LOAD_TEMPLATE := import.load.tpl
IMPORT_LOAD :=import.load

import_to_postgres:
	@if [ ! -f $(SQLITE_DATABASE) ]; then \
		echo "❌ Файл SQLite базы $(SQLITE_DATABASE) не найден!"; \
		exit 1; \
	fi
	@if ! docker ps --filter "name=$(POSTGRES_CONTAINER)" --filter "status=running" | grep -q $(POSTGRES_CONTAINER); then \
		echo "❌ Контейнер $(POSTGRES_CONTAINER) не запущен!"; \
		exit 1; \
	fi
	@echo "📦 Копируем SQLite базу и шаблон конфигурации в контейнер $(POSTGRES_CONTAINER)..."
	@docker cp $(SQLITE_DATABASE) $(POSTGRES_CONTAINER):/app/database-sql-lite.db
	@docker cp $(IMPORT_LOAD_TEMPLATE) $(POSTGRES_CONTAINER):/app/import.load.tpl
	@echo "🚀 Формируем конфиг pgloader с подстановкой переменных окружения (запуск от root)..."
	@docker exec -u root $(POSTGRES_CONTAINER) /bin/sh -c 'export NEXT_PUBLIC_DB_USER_DEV="$(NEXT_PUBLIC_DB_USER_DEV)" && export NEXT_PUBLIC_DB_PASSWORD_DEV="$(NEXT_PUBLIC_DB_PASSWORD_DEV)" && export NEXT_PUBLIC_DB_NAME_DEV="$(NEXT_PUBLIC_DB_NAME_DEV)" && envsubst < /app/import.load.tpl > /app/import.load'
	@echo "🚀 Запускаем pgloader внутри контейнера $(POSTGRES_CONTAINER)..."
	@docker exec -i $(POSTGRES_CONTAINER) pgloader /app/import.load
	@echo "✅ Готово!"
