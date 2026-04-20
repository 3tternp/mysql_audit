#!/usr/bin/env bash
set -euo pipefail

HOST="127.0.0.1"
PORT="3306"
USER="root"
PASSWORD=""
OUTDIR="./output"

usage() {
  cat <<USAGE
Usage:
  $0 --host <host> --port <port> --user <user> --password <password> [--outdir <dir>]

Example:
  $0 --host 127.0.0.1 --port 3306 --user root --password 'Secret123' --outdir ./output
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --user) USER="$2"; shift 2 ;;
    --password) PASSWORD="$2"; shift 2 ;;
    --outdir) OUTDIR="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

if [[ -z "$PASSWORD" ]]; then
  echo "Error: --password is required"
  exit 1
fi

mkdir -p "$OUTDIR"

MYSQL_CMD=(mysql -h"$HOST" -P"$PORT" -u"$USER" -p"$PASSWORD" --batch --raw --skip-column-names)

echo "[*] Enabling MySQL general log to TABLE..."
"${MYSQL_CMD[@]}" -e "SET GLOBAL log_output = 'TABLE'; SET GLOBAL general_log = 'ON';"

echo "[*] Exporting executed SQL statements..."
"${MYSQL_CMD[@]}" -e "
SELECT
  event_time,
  user_host,
  thread_id,
  command_type,
  REPLACE(REPLACE(argument, '\n', ' '), '\r', ' ') AS executed_sql
FROM mysql.general_log
WHERE command_type = 'Query'
ORDER BY event_time DESC;
" > "$OUTDIR/all_queries.tsv"

echo "[*] Exporting query counts by user..."
"${MYSQL_CMD[@]}" -e "
SELECT
  SUBSTRING_INDEX(user_host, '[', 1) AS username,
  COUNT(*) AS total_queries
FROM mysql.general_log
WHERE command_type = 'Query'
GROUP BY username
ORDER BY total_queries DESC;
" > "$OUTDIR/query_count_by_user.tsv"

echo "[*] Exporting access logs..."
"${MYSQL_CMD[@]}" -e "
SELECT
  event_time,
  user_host,
  command_type,
  REPLACE(REPLACE(argument, '\n', ' '), '\r', ' ') AS details
FROM mysql.general_log
WHERE command_type IN ('Connect', 'Quit')
ORDER BY event_time DESC;
" > "$OUTDIR/access_logs.tsv"

echo "[+] Export complete: $OUTDIR"
echo "    - all_queries.tsv"
echo "    - query_count_by_user.tsv"
echo "    - access_logs.tsv"
