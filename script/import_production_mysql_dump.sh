#!/usr/bin/env bash
#
# Import a phpMyAdmin-style dump (e.g. ownoutdoors_production_mysql.sql) into sharetribe_development.
#
# The dump targets database ownoutdoors_production_mysql; this script rewrites it to MYSQL_DATABASE.
#
# IMPORTANT — server limits on 192.168.4.10 (or your host)
# --------------------------------------------------------
# Large INSERTs (e.g. browser_fingerprints) need BOTH:
#   - max_allowed_packet >= 1G (default 64M is too small)
#   - net_read_timeout / net_write_timeout high enough (default 30s often kills long imports)
#
# Run as MySQL root (or another account with SUPER) ON THE DATABASE SERVER, then restart mysqld
# if you changed my.cnf:
#
#   SET GLOBAL max_allowed_packet = 1073741824;
#   SET GLOBAL net_read_timeout = 600;
#   SET GLOBAL net_write_timeout = 600;
#
# Or in my.cnf under [mysqld]:
#   max_allowed_packet = 1G
#   net_read_timeout = 600
#   net_write_timeout = 600
#
# Fastest and most reliable: copy the PREPARED_SQL file to the server and run mysql locally:
#   mysql -u ... -p sharetribe_development < prepared.sql
#
set -euo pipefail

MYSQL_HOST="${MYSQL_HOST:-192.168.4.10}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-sharetribe_development}"
MYSQL_DATABASE="${MYSQL_DATABASE:-sharetribe_development}"
DUMP_FILE="${DUMP_FILE:-/home/agile/live_project/ownoutdoorsc/latest/db_backup/ownoutdoors_production_mysql.sql}"
PREPARED_SQL="${PREPARED_SQL:-/tmp/sharetribe_development_prepared.sql}"
SOURCE_DB_NAME="${SOURCE_DB_NAME:-ownoutdoors_production_mysql}"

if [[ -z "${MYSQL_PWD:-}" ]]; then
  echo "Set MYSQL_PWD to the database password before running." >&2
  exit 1
fi

if [[ ! -f "$DUMP_FILE" ]]; then
  echo "Dump not found: $DUMP_FILE" >&2
  exit 1
fi

echo "Preparing SQL (rewriting \`${SOURCE_DB_NAME}\` -> \`${MYSQL_DATABASE}\`, stripping CREATE DATABASE)..."
sed -e '/^CREATE DATABASE IF NOT EXISTS/d' \
  -e "s/\`${SOURCE_DB_NAME}\`/\`${MYSQL_DATABASE}\`/g" \
  "$DUMP_FILE" > "$PREPARED_SQL"

echo "Prepared file: $PREPARED_SQL ($(du -h "$PREPARED_SQL" | cut -f1))"

echo "Recreating database ${MYSQL_DATABASE} on ${MYSQL_HOST}..."
docker run --rm -e MYSQL_PWD mysql:8.0 mysql \
  -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" \
  -e "DROP DATABASE IF EXISTS \`${MYSQL_DATABASE}\`; CREATE DATABASE \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

echo "Importing (requires server max_allowed_packet + timeouts — see script header)..."
{
  echo "SET SESSION net_read_timeout=86400;"
  echo "SET SESSION net_write_timeout=86400;"
  cat "$PREPARED_SQL"
} | docker run --rm -i -e MYSQL_PWD mysql:8.0 mysql \
  --max-allowed-packet=1073741824 \
  --connect-timeout=60 \
  -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" \
  --default-character-set=utf8mb4 \
  "$MYSQL_DATABASE"

echo "Table count:"
docker run --rm -e MYSQL_PWD mysql:8.0 mysql \
  -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -N \
  -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${MYSQL_DATABASE}';"

echo "Done."
