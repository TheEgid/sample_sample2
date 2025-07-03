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

# Путь к дампу SQLite
SQLITE_DUMP=./backup/backup.sql
# Путь к конвертированному дампу для PostgreSQL
PG_DUMP=./backup/backup_postgres.sql


backup_sqllite:
	@echo "Создаём дамп базы SQLite с DROP TABLE и DROP INDEX..."
	@mkdir -p ./backup
	@chmod 777 ./backup
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


convert_to_postgres: backup_sqllite
	@echo "Конвертируем дамп SQLite в PostgreSQL..."
	@docker run --rm -v "$(pwd)/backup:/app/backup" sqltranslator_container \
		sqlt -f SQLite -t PostgreSQL /app/backup/backup.sql > ./backup/backup_postgres.sql
	@chmod 777 ./backup/backup_postgres.sql
	@echo "Конвертация завершена, файл: backup/backup_postgres.sql"
