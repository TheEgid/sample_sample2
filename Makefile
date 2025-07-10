include ./main-applic/.env
export

COMPOSE_BAKE=true

LANG=ru_RU.UTF-8


all: run clean


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


SQLITE_DATABASE := ./main-applic/prisma/database-sql-lite.db
POSTGRES_CONTAINER := db_postgres_container
IMPORT_LOAD_TEMPLATE=import.load.tpl
IMPORT_LOAD=import.load

IMPORT_UNLOAD_TEMPLATE=import.unload.tpl
IMPORT_UNLOAD=import.unload


import_to_postgres:
	@if [ ! -f "$(SQLITE_DATABASE)" ]; then \
		echo "❌ Файл SQLite базы $(SQLITE_DATABASE) не найден!"; \
		exit 1; \
	fi
	@if [ ! -s "$(SQLITE_DATABASE)" ]; then \
		echo "❌ Файл SQLite базы $(SQLITE_DATABASE) пустой!"; \
		exit 1; \
	fi
	@if ! docker ps --filter "name=$(POSTGRES_CONTAINER)" --filter "status=running" | grep -q $(POSTGRES_CONTAINER); then \
		echo "❌ Контейнер $(POSTGRES_CONTAINER) не запущен!"; \
		exit 1; \
	fi
	@echo "📦 Копируем SQLite базу в контейнер $(POSTGRES_CONTAINER)..."
	@docker cp $(SQLITE_DATABASE) $(POSTGRES_CONTAINER):/app/database-sql-lite.db
	@echo "🚀 Формируем конфиг pgloader с подстановкой переменных окружения (запуск от root)..."
	@docker exec -u root $(POSTGRES_CONTAINER) /bin/bash -c 'NODE_PATH=$$(npm root -g) node /render_template.js import.load.tpl'
	@echo "🚀 Запускаем pgloader внутри контейнера $(POSTGRES_CONTAINER)..."
	@docker exec -i $(POSTGRES_CONTAINER) pgloader /import.load || (echo "❌ Ошибка pgloader!"; exit 1)
	@docker exec -it $(POSTGRES_CONTAINER) dos2unix /import.load
	@echo "🧹 Удаляем SQLite-базу внутри контейнера..."
	@docker exec -u root $(POSTGRES_CONTAINER) rm -f /app/database-sql-lite.db /import.load
	@echo "✅ Готово!"


import_to_sqlite:
	@if ! docker ps --filter "name=$(POSTGRES_CONTAINER)" --filter "status=running" | grep -q $(POSTGRES_CONTAINER); then \
		echo "❌ Контейнер $(POSTGRES_CONTAINER) не запущен!"; \
		exit 1; \
	fi
	@echo "🚀 Копируем шаблон конфигурации import.unload.tpl в контейнер $(POSTGRES_CONTAINER)..."
	@docker cp postgres-db/$(IMPORT_UNLOAD_TEMPLATE) $(POSTGRES_CONTAINER):/$(IMPORT_UNLOAD_TEMPLATE)
	@echo "🚀 Формируем конфиг pgloader с подстановкой переменных окружения (запуск от root)..."
	@docker exec -u root $(POSTGRES_CONTAINER) /bin/bash -c 'NODE_PATH=$$(npm root -g) node /render_template.js import.unload.tpl > /import.load'
	@docker exec -u root $(POSTGRES_CONTAINER) dos2unix /import.load
	@echo "🚀 Запускаем pgloader внутри контейнера $(POSTGRES_CONTAINER)..."
	@docker exec -i $(POSTGRES_CONTAINER) pgloader /import.load || (echo "❌ Ошибка pgloader!"; exit 1)
	@echo "📦 Копируем SQLite базу из контейнера на хост..."
	@docker cp $(POSTGRES_CONTAINER):/app/database-sql-lite.db $(SQLITE_DATABASE)
	@echo "✅ Готово! База сконвертирована в SQLite: $(SQLITE_DATABASE)"


check_sqlite_schema:
	@if [ ! -f "$(SQLITE_DATABASE)" ]; then \
		echo "❌ Файл $(SQLITE_DATABASE) не найден! Сначала выполните make import_to_sqlite"; \
		exit 1; \
	fi
	@echo "📋 Таблицы в SQLite:"
	@sqlite3 $(SQLITE_DATABASE) '.tables'
	@echo ""
	@echo "🧩 Схема таблицы user:"
	@sqlite3 $(SQLITE_DATABASE) 'PRAGMA table_info("user");'


BACKUP_DIR := $(shell pwd)/backup
BACKUP_FILE_CONTAINER := /app/backup/postgres_backup_$(shell date +%F_%H-%M-%S).dump


#...................................................................................................................................................................


backup_postgres:
	@if ! docker ps --filter "name=$(POSTGRES_CONTAINER)" --filter "status=running" | grep -q $(POSTGRES_CONTAINER); then \
		echo "❌ Контейнер $(POSTGRES_CONTAINER) не запущен!"; \
		exit 1; \
	fi
	@echo "🚀 Формируем строку подключения из .env..."
	@PG_USER=$(MY_DB_USER_DEV); \
	PG_PASS=$(MY_DB_PASSWORD_DEV); \
	PG_DB=$(MY_DB_NAME_DEV); \
	echo "Создаём папку для бэкапов в контейнере..."; \
	docker exec $(POSTGRES_CONTAINER) mkdir -p /app/backup; \
	echo "🚀 Запускаем pg_dump внутри контейнера..."; \
	docker exec -e PGPASSWORD=$$PG_PASS $(POSTGRES_CONTAINER) pg_dump -U $$PG_USER -F c -b -v -f $(BACKUP_FILE_CONTAINER) $$PG_DB; \
	echo "✅ Бэкап сохранён в $(BACKUP_FILE_CONTAINER) внутри контейнера $(POSTGRES_CONTAINER)"; \
	echo "Создаём папку для бэкапов на хосте: $(BACKUP_DIR)"; \
	mkdir -p $(BACKUP_DIR); \
	echo "📦 Копируем бэкап на хост..."; \
	docker cp $(POSTGRES_CONTAINER):$(BACKUP_FILE_CONTAINER) $(BACKUP_DIR)/; \
	echo "✅ Бэкап скопирован в $(BACKUP_DIR)/"; \


insert_user_postgres:
	@if ! docker ps --filter "name=$(POSTGRES_CONTAINER)" --filter "status=running" | grep -q $(POSTGRES_CONTAINER); then \
		echo "❌ Контейнер $(POSTGRES_CONTAINER) не запущен!"; \
		exit 1; \
	fi
	@echo "🚀 Добавляем пользователя в PostgreSQL..."
	@docker exec -e PGPASSWORD=$(MY_DB_PASSWORD_DEV) $(POSTGRES_CONTAINER) psql -U $(MY_DB_USER_DEV) -d $(MY_DB_NAME_DEV) -c \
	"INSERT INTO \"user\" (email, name) VALUES ('testuser@example.com', 'CLI User ТРИ');"
	@echo "✅ Пользователь добавлен."
