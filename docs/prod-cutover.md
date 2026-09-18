# Production cutover checklist

## Pre-cutover

1. Staging certified (`Test-StrivePayPromotion` green against HTTPS staging API).
2. Production Lightsail service `strivepay-production` READY (same layout as staging).
3. GitHub Environment **production** secrets filled (`secrets/production.checklist.md`).
4. Branch protection on `main` for `strivepay-api`, `strivepay-consumer-web`, `strivepay-admin-web`:
   - Require PR reviews
   - Require status checks
   - Restrict who can push
5. Production Environment in GitHub: required reviewers before deploy jobs run.

## Cutover

1. Deploy production via `main` (or infra `full-deploy` with seed images).
2. Attach custom domains / certificate:

```powershell
aws lightsail create-container-service-deployment ... # already running
aws lightsail update-container-service `
  --region eu-west-2 `
  --service-name strivepay-production `
  --public-domain-names file://deployments/domains.production.json
```

3. Point DNS CNAMEs:
   - `api.strivepay.io` → Lightsail production service URL
   - `strivepay.io` → same (consumer)
   - `cockpit.strivepay.io` → same (admin)
4. Confirm HTTPS and Host-based routing via Caddy (`API_HOST` / `APP_HOST` / `ADMIN_HOST`).
5. Disable simulator: `STRIVEPAY_SIMULATOR_ENABLED=false` (already in template).
6. Confirm daily dump workflow + restore drill (`docs/postgres-backup-restore.md`).
7. Optional: CloudWatch/Lightsail alarms on container service health.

## Rollback

- Re-point DNS to previous origin, or redeploy prior Lightsail deployment version from container images still registered on the service.
