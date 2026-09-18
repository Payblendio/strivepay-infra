# strivepay-infra

Lightsail Container Service bootstrap, deployment templates, edge proxy, IAM/OIDC notes, and Postgres dump/restore for StrivePay.

## Layout

| Path | Purpose |
|---|---|
| `deployments/containers.template.json` | Five app containers + Caddy proxy + Postgres |
| `proxy/` | Host-based reverse proxy (api / app / admin) |
| `scripts/New-StrivePayLightsailEnv.ps1` | Create container service + dump bucket |
| `scripts/Push-StrivePayImage.ps1` | `aws lightsail push-container-image` helper |
| `scripts/Build-StrivePayDeployment.ps1` | Render deployment JSON from secrets + image tags |
| `scripts/Deploy-StrivePayLightsail.ps1` | `create-container-service-deployment` |
| `scripts/Backup-StrivePayPostgres.ps1` | `pg_dump` → Object Storage |
| `docs/postgres-backup-restore.md` | Restore runbook |
| `iam/github-oidc.md` | GitHub Actions → Lightsail IAM |
| `secrets/*.checklist.md` | Environment secret inventories |

## One service per environment

- Staging: `strivepay-staging` (`develop`)
- Production: `strivepay-production` (`main`)

Containers: `proxy`, `api`, `worker`, `consumer-web`, `admin-web`, `postgres`.

Public HTTP terminates on `proxy` only. Postgres is never exposed.

## Bootstrap

```powershell
.\scripts\New-StrivePayLightsailEnv.ps1 -Environment staging -Region eu-west-2
.\scripts\New-StrivePayLightsailEnv.ps1 -Environment production -Region eu-west-2 -Power large
```

Then configure GitHub Environments + OIDC (`iam/github-oidc.md`) and deploy via app repo Actions.

## Custom domains

After first successful deployment, map certificates/domains:

```powershell
aws lightsail update-container-service `
  --region eu-west-2 `
  --service-name strivepay-staging `
  --public-domain-names file://domains.staging.json
```

Point DNS CNAMEs for `api|app|admin.staging.strivepay.io` at the Lightsail service URL.
