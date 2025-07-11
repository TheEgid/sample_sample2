#!/usr/bin/env python3

import os
import subprocess
import sys

def main():
    pg_conn = os.environ.get("PG_CONN")
    sqlite_file = "/_backup_database-sql-lite.db"

    if not pg_conn:
        raise ValueError("Не задана переменная окружения PG_CONN")

    cmd = [
        "db-to-sqlite",
        pg_conn,
        sqlite_file,
        "--all",  # экспорт всех таблиц
        "-p"      # показать прогресс
    ]

    try:
        subprocess.run(cmd, check=True)
        print("Миграция завершена успешно.")
    except subprocess.CalledProcessError as e:
        print(f"Ошибка при миграции: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
