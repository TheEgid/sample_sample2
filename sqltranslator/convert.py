#!/usr/bin/env python3
import sys
from pathlib import Path
import sqlglot
import subprocess


def clean_sql_lines(sql_lines):
    cleaned = []
    skip_phrases = ["PRAGMA", "sqlite_sequence"]
    in_transaction = False

    for line in sql_lines:
        if any(skip in line for skip in skip_phrases):
            continue
        if line.strip().upper().startswith("BEGIN"):
            if in_transaction:
                continue
            in_transaction = True
        if line.strip().upper().startswith("COMMIT"):
            if not in_transaction:
                continue
            in_transaction = False
        cleaned.append(line)

    return cleaned


def validate_sql_with_sqlite_docker(sql_path, container_name="db_sqlite_container"):
    try:
        with open(sql_path, "r", encoding="utf-8") as f:
            sql = f.read()
        result = subprocess.run(
            ["docker", "exec", "-i", container_name, "sqlite3", ":memory:"],
            input=sql.encode(),
            check=True,
            capture_output=True,
            text=True,
        )
        print("✅ SQLite валидация успешна")
    except subprocess.CalledProcessError as e:
        print("❌ SQLite валидация не удалась:")
        print(e.stderr)
        sys.exit(1)


def validate_sql_with_postgres_docker(sql_path, container_name="postgres_container"):
    try:
        with open(sql_path, "r", encoding="utf-8") as f:
            sql = f.read()
        result = subprocess.run(
            ["docker", "exec", "-i", container_name, "psql", "--dbname=postgres", "--no-psqlrc"],
            input=sql.encode(),
            check=True,
            capture_output=True,
            text=True,
        )
        print("✅ PostgreSQL валидация успешна")
    except subprocess.CalledProcessError as e:
        print("❌ PostgreSQL валидация не удалась:")
        print(e.stderr)
        sys.exit(1)


def convert_sql(input_path, output_path, source_dialect, target_dialect, validate=False):
    with open(input_path, "r", encoding="utf-8") as f:
        raw_sql = f.read()

    sql_list = sqlglot.transpile(
        raw_sql,
        read=source_dialect,
        write=target_dialect,
        pretty=True,
    )

    if not sql_list:
        print("\u274C Результат конвертации пуст")
        sys.exit(1)

    full_sql = ";\n\n".join(sql_list) + ";"
    cleaned_sql_lines = clean_sql_lines(full_sql.splitlines())
    cleaned_sql = "\n".join(cleaned_sql_lines)

    with open(output_path, "w", encoding="utf-8") as f:
        f.write(cleaned_sql)

    print(f"\u2705 Конвертация завершена. Результат: {output_path}")

    if validate:
        if target_dialect == "sqlite":
            validate_sql_with_sqlite_docker(output_path)
        elif target_dialect == "postgres":
            validate_sql_with_postgres_docker(output_path)


def convert_sqlite_to_postgres(input_path: str, output_path: str, validate=False):
    convert_sql(input_path, output_path, "sqlite", "postgres", validate)


def convert_postgres_to_sqlite(input_path: str, output_path: str, validate=False):
    convert_sql(input_path, output_path, "postgres", "sqlite", validate)


if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Использование:")
        print("  to-pg <входной.sql> <выходной.sql> [--validate]")
        print("  to-sqlite <входной.sql> <выходной.sql> [--validate]")
        sys.exit(1)

    direction = sys.argv[1]
    input_path = Path(sys.argv[2])
    output_path = Path(sys.argv[3])
    validate = "--validate" in sys.argv

    if not input_path.exists():
        print(f"\u274C Входной файл не найден: {input_path}")
        sys.exit(1)

    output_path.parent.mkdir(parents=True, exist_ok=True)

    if direction == "to-pg":
        convert_sqlite_to_postgres(str(input_path), str(output_path), validate)
    elif direction == "to-sqlite":
        convert_postgres_to_sqlite(str(input_path), str(output_path), validate)
    else:
        print("\u274C Неизвестное направление: to-pg или to-sqlite")
        sys.exit(1)
