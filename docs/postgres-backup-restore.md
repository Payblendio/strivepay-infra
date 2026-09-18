# StrivePay Lightsail — restore Postgres from Object Storage dump

## Prerequisites

- Lightsail Object Storage bucket: `strivepay-db-dumps-{staging|production}`
- Dump object key like `postgres/staging/20260101-120000.sql.gz`
- Access to the environment’s private `postgres` container (same Container Service network)
  or a temporary public port for restore-only windows

## Restore steps

1. Download the dump:

```powershell
aws lightsail download-bucket-object `
  --region eu-west-2 `
  --bucket-name strivepay-db-dumps-staging `
  --key postgres/staging/YYYYMMDD-HHMMSS.sql.gz `
  --path .\restore.sql.gz
```

If `download-bucket-object` is unavailable, use S3-compatible access keys from
`aws lightsail create-bucket-access-key` and:

```powershell
aws s3 cp s3://strivepay-db-dumps-staging/postgres/staging/YYYYMMDD-HHMMSS.sql.gz .\restore.sql.gz `
  --endpoint-url https://s3.eu-west-2.amazonaws.com
```

2. Decompress and restore into the running `postgres` container network:

```powershell
gzip -d restore.sql.gz
# From a host that can reach jdbc host `postgres` on the service network,
# or via a one-shot restore container on the same Lightsail service:
psql "postgresql://strivepay:PASSWORD@postgres:5432/strivepay_consumer" -f restore.sql
```

3. Restart `api` and `worker` (create a new container service deployment with the
   same images) so Flyway/connection pools reconnect cleanly.

4. Run a smoke check (`GET /actuator/health` or `Test-StrivePayPromotion`).

## Notes

- Lightsail Containers do **not** attach durable block volumes. Treat dumps as the
  primary durability story until you migrate to managed Postgres.
- Keep at least 7 daily dumps; prune older objects from the bucket.
- Never restore production dumps into staging without scrubbing PII / rotating secrets.
