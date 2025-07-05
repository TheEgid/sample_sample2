#!/usr/bin/env python3

import sys
from pathlib import Path
import sqlglot

def convert_sqlite_to_postgres(input_path: str, output_path: str):
    with open(input_path, 'r', encoding='utf-8') as f:
        sqlite_sql = f.read()

    # Конвертируем SQL из SQLite в PostgreSQL
    # sqlglot.transpile возвращает список запросов, берем первый (если несколько - можно доработать)
    postgres_sql_list = sqlglot.transpile(sqlite_sql, read='sqlite', write='postgres')

    postgres_sql = ";\n".join(postgres_sql_list) + ";"

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(postgres_sql)

    print(f"Конвертация завершена. Результат записан в {output_path}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Использование: python convert.py <путь_к_sqlite_дампу.sql> <путь_к_postgres_выходу.sql>")
        sys.exit(1)

    input_sqlite = Path(sys.argv[1])
    output_postgres = Path(sys.argv[2])

    # Проверяем, что входной файл существует и является файлом
    if not input_sqlite.exists() or not input_sqlite.is_file():
        print(f"Ошибка: входной файл '{input_sqlite}' не найден или не является файлом")
        sys.exit(1)

    # Проверяем, что директория для выходного файла существует
    if not output_postgres.parent.exists():
        print(f"Ошибка: директория для выходного файла '{output_postgres.parent}' не существует")
        sys.exit(1)

    convert_sqlite_to_postgres(str(input_sqlite), str(output_postgres))


# python convert.py ./backup/backup.sql ./backup/backup_postgres.sql
