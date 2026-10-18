#!/usr/bin/env bash
set -euo pipefail

dump_file="${1:?usage: restore-local-db.sh DUMP_FILE}"
cd /opt/strivepay
docker compose up -d postgres
for attempt in $(seq 1 30); do
  if docker compose exec -T postgres pg_isready -U strivepay -d strivepay_consumer >/dev/null 2>&1; then
    break
  fi
  if [ "$attempt" -eq 30 ]; then
    echo "PostgreSQL did not become ready" >&2
    exit 1
  fi
  sleep 2
done
docker compose exec -T postgres dropdb --if-exists -U strivepay strivepay_consumer
docker compose exec -T postgres createdb -U strivepay strivepay_consumer
docker compose exec -T postgres pg_restore -U strivepay -d strivepay_consumer --no-owner --no-acl --exit-on-error < "$dump_file"
docker compose exec -T postgres psql -U strivepay -d strivepay_consumer -Atc \
  "select 'tables=' || count(*) from pg_catalog.pg_tables where schemaname not in ('pg_catalog','information_schema');"

