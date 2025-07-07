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


convert_to_postgres: backup_sqlite
	@echo "Проверяем содержимое исходного дампа:"
	@head -n 2 $(SQLITE_DUMP)
	@echo "Конвертируем дамп SQLite в PostgreSQL..."
	@docker run --rm -v $(BACKUP_DIR):/app/backup $(IMAGE_NAME) /usr/local/bin/python3 /app/convert.py to-pg /app/backup/backup.sql /app/backup/backup_postgres.sql
	@if [ -f "$(PG_DUMP)" ]; then \
		ls -lh $(PG_DUMP); \
		chmod $(shell stat -c %a $(SQLITE_DUMP)) $(PG_DUMP); \
		echo "🔒 Права доступа сохранены"; \
	else \
		echo "Ошибка: файл $(PG_DUMP) не найден!"; \
		exit 1; \
	fi
	@echo "Готово"


# convert_to_sqlite: backup_postgres
convert_to_sqlite:
	@echo "Проверяем содержимое исходного дампа PostgreSQL:"
	@head -n 2 $(PG_DUMP)
	@echo "Конвертируем дамп PostgreSQL в SQLite..."
	@docker run --rm -v $(BACKUP_DIR):/app/backup $(IMAGE_NAME) /usr/local/bin/python3 /app/convert.py to-sqlite /app/backup/backup_postgres.sql /app/backup/backup_sqlite.sql
	@if [ -f "$(SQLITE_DUMP)" ]; then \
		ls -lh $(SQLITE_DUMP); \
		chmod $(shell stat -c %a $(PG_DUMP)) $(SQLITE_DUMP); \
		echo "🔒 Права доступа сохранены"; \
	else \
		echo "Ошибка: файл $(SQLITE_DUMP) не найден!"; \
		exit 1; \
	fi
	@echo "Готово"
