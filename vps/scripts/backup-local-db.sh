#!/usr/bin/env bash
set -euo pipefail

backup_dir=/opt/strivepay/backups
stamp=$(date -u +%Y%m%d-%H%M%S)
destination="$backup_dir/strivepay-staging-$stamp.dump"
install -d -m 0750 "$backup_dir"
cd /opt/strivepay
docker compose exec -T postgres pg_dump \
  -U strivepay \
  -d strivepay_consumer \
  --format=custom \
  --no-owner \
  --no-acl > "$destination"
chmod 0600 "$destination"
sha256sum "$destination" > "$destination.sha256"
find "$backup_dir" -maxdepth 1 -type f -name 'strivepay-staging-*.dump*' -mtime +14 -delete
printf 'Created %s\n' "$destination"

