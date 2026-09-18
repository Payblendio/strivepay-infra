# Staging secrets checklist (`SANDBOX`)

Set these on GitHub Environment **`staging`** for:
- `Payblendio/strivepay-api`
- `Payblendio/strivepay-consumer-web`
- `Payblendio/strivepay-admin-web`

Also mirror into the Lightsail deployment via Actions (env → deployment JSON).

## Shared / AWS

| Secret | Notes |
|---|---|
| `AWS_ROLE_ARN` | OIDC role for Lightsail push/deploy |
| `AWS_REGION` | `eu-west-2` |
| `LIGHTSAIL_SERVICE_NAME` | `strivepay-staging` |

## Database

| Secret | Notes |
|---|---|
| `POSTGRES_PASSWORD` | Strong password for postgres container + api/worker |
| `STRIVEPAY_DB_URL` | `jdbc:postgresql://postgres:5432/strivepay_consumer` (fixed; optional override) |

## API / worker (`STRIVEPAY_*`)

| Secret | Notes |
|---|---|
| `STRIVEPAY_DATA_ENCRYPTION_KEY` | 32-byte key (base64/hex per app convention) |
| `STRIVEPAY_ADMIN_EMAIL` | Bootstrap admin |
| `STRIVEPAY_ADMIN_PASSWORD` | Bootstrap admin |
| `STRIVEPAY_SMTP_HOST` | |
| `STRIVEPAY_SMTP_PORT` | |
| `STRIVEPAY_SMTP_USERNAME` | |
| `STRIVEPAY_SMTP_PASSWORD` | |
| `STRIVEPAY_SMTP_FROM` | |
| `STRIVEPAY_BAKKT_BASE_URL` | Sandbox Bakkt URL |
| `STRIVEPAY_BAKKT_API_KEY` | |
| `STRIVEPAY_BAKKT_WEBHOOK_SECRET` | |
| `STRIVEPAY_QUIDAX_API_KEY` | Sandbox |
| `STRIVEPAY_QUIDAX_WEBHOOK_SECRET` | |
| `STRIVEPAY_FCM_PROJECT_ID` | |
| `STRIVEPAY_FCM_CREDENTIALS_JSON` | Service account JSON (mount/inject at deploy) |

## Hosts (variables, not secrets)

| Variable | Example |
|---|---|
| `API_HOST` | `api.staging.strivepay.io` |
| `APP_HOST` | `staging.strivepay.io` (consumer web) |
| `ADMIN_HOST` | `cockpit.staging.strivepay.io` |

## Webs

| Secret / var | Notes |
|---|---|
| `CONSUMER_API_URL` | `https://api.staging.strivepay.io` |
| `NEXT_PUBLIC_APP_URL` (consumer) | `https://staging.strivepay.io` |
| `ADMIN_API_URL` | `https://api.staging.strivepay.io` |
| `NEXT_PUBLIC_APP_URL` (admin) | `https://cockpit.staging.strivepay.io` |

Environment: `STRIVEPAY_ENVIRONMENT=SANDBOX`, simulator off, Bakkt/Quidax sandbox modes.
