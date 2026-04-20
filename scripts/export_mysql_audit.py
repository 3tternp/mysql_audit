#!/usr/bin/env python3
"""Export MySQL user activity from mysql.general_log.

This script enables MySQL general logging to TABLE and exports:
- all executed queries to CSV and JSON
- query count by user to CSV
- access logs (Connect / Quit) to CSV
"""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Iterable, Sequence

import mysql.connector
from mysql.connector.connection import MySQLConnection


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Export MySQL audit activity")
    parser.add_argument("--host", default="127.0.0.1", help="MySQL host")
    parser.add_argument("--port", type=int, default=3306, help="MySQL port")
    parser.add_argument("--user", required=True, help="MySQL username")
    parser.add_argument("--password", required=True, help="MySQL password")
    parser.add_argument("--database", default="mysql", help="Default database")
    parser.add_argument("--outdir", default="./output", help="Output directory")
    return parser.parse_args()


def connect(args: argparse.Namespace) -> MySQLConnection:
    return mysql.connector.connect(
        host=args.host,
        port=args.port,
        user=args.user,
        password=args.password,
        database=args.database,
    )


def run_query(conn: MySQLConnection, query: str) -> tuple[list[str], list[tuple]]:
    cursor = conn.cursor()
    cursor.execute(query)
    rows = cursor.fetchall()
    headers = [desc[0] for desc in cursor.description] if cursor.description else []
    cursor.close()
    return headers, rows


def write_csv(filepath: Path, headers: Sequence[str], rows: Iterable[Sequence]) -> None:
    with filepath.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        if headers:
            writer.writerow(headers)
        for row in rows:
            writer.writerow(row)


def write_json(filepath: Path, headers: Sequence[str], rows: Iterable[Sequence]) -> None:
    data = [dict(zip(headers, row)) for row in rows]
    with filepath.open("w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2, default=str)


def main() -> None:
    args = parse_args()
    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    conn = connect(args)
    try:
        with conn.cursor() as cursor:
            cursor.execute("SET GLOBAL log_output = 'TABLE'")
            cursor.execute("SET GLOBAL general_log = 'ON'")
        conn.commit()

        queries_sql = """
        SELECT
            event_time,
            user_host,
            thread_id,
            command_type,
            REPLACE(REPLACE(argument, '\n', ' '), '\r', ' ') AS executed_sql
        FROM mysql.general_log
        WHERE command_type = 'Query'
        ORDER BY event_time DESC
        """

        counts_sql = """
        SELECT
            SUBSTRING_INDEX(user_host, '[', 1) AS username,
            COUNT(*) AS total_queries
        FROM mysql.general_log
        WHERE command_type = 'Query'
        GROUP BY username
        ORDER BY total_queries DESC
        """

        access_sql = """
        SELECT
            event_time,
            user_host,
            command_type,
            REPLACE(REPLACE(argument, '\n', ' '), '\r', ' ') AS details
        FROM mysql.general_log
        WHERE command_type IN ('Connect', 'Quit')
        ORDER BY event_time DESC
        """

        q_headers, q_rows = run_query(conn, queries_sql)
        c_headers, c_rows = run_query(conn, counts_sql)
        a_headers, a_rows = run_query(conn, access_sql)

        write_csv(outdir / "all_queries.csv", q_headers, q_rows)
        write_csv(outdir / "query_count_by_user.csv", c_headers, c_rows)
        write_csv(outdir / "access_logs.csv", a_headers, a_rows)
        write_json(outdir / "all_queries.json", q_headers, q_rows)

        print(f"[+] Export complete: {outdir}")
        print("    - all_queries.csv")
        print("    - query_count_by_user.csv")
        print("    - access_logs.csv")
        print("    - all_queries.json")

    finally:
        conn.close()


if __name__ == "__main__":
    main()
