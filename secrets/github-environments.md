# GitHub Environment bootstrap

## Role ARN

```
arn:aws:iam::529288965480:role/strivepay-github-lightsail
```

## Per-repo Environments

Create Environments `staging` and `production` on:

- Payblendio/strivepay-api
- Payblendio/strivepay-consumer-web
- Payblendio/strivepay-admin-web
- Payblendio/strivepay-infra

### Shared secrets (both envs)

| Secret | Value |
|---|---|
| `AWS_ROLE_ARN` | `arn:aws:iam::529288965480:role/strivepay-github-lightsail` |

### Shared variables

| Variable | Staging | Production |
|---|---|---|
| `AWS_REGION` | `eu-west-2` | `eu-west-2` |
| `LIGHTSAIL_SERVICE_NAME` | `strivepay-staging` | `strivepay-production` |
| `API_HOST` | `api.staging.strivepay.io` | `api.strivepay.io` |
| `APP_HOST` | `app.staging.strivepay.io` | `app.strivepay.io` |
| `ADMIN_HOST` | `admin.staging.strivepay.io` | `admin.strivepay.io` |
| `CONSUMER_API_URL` | `https://api.staging.strivepay.io` | `https://api.strivepay.io` |
| `ADMIN_API_URL` | `https://api.staging.strivepay.io` | `https://api.strivepay.io` |
| `NEXT_PUBLIC_APP_URL` | app/admin host as appropriate | same |

### App secrets

See `secrets/staging.checklist.md` and `secrets/production.checklist.md`.

### Production protection

Require reviewers on Environment `production`. Protect branch `main`.

## gh CLI example

```bash
gh secret set AWS_ROLE_ARN -R Payblendio/strivepay-api -e staging -b "arn:aws:iam::529288965480:role/strivepay-github-lightsail"
gh variable set AWS_REGION -R Payblendio/strivepay-api -e staging -b "eu-west-2"
gh variable set LIGHTSAIL_SERVICE_NAME -R Payblendio/strivepay-api -e staging -b "strivepay-staging"
```
