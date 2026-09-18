# Production secrets checklist (`PRODUCTION`)

Set these on GitHub Environment **`production`** (required reviewers on `main`).

Same keys as staging, with live values:

| Secret | Production notes |
|---|---|
| `LIGHTSAIL_SERVICE_NAME` | `strivepay-production` |
| `POSTGRES_PASSWORD` | Unique; never reuse staging |
| `STRIVEPAY_DATA_ENCRYPTION_KEY` | Unique production key |
| `STRIVEPAY_BAKKT_*` | Live Bakkt credentials |
| `STRIVEPAY_QUIDAX_*` | Live Quidax credentials |
| `STRIVEPAY_DOT_ENABLED` | `true` |
| Hosts | `api.strivepay.io`, `strivepay.io` (consumer), `cockpit.strivepay.io` |

Environment: `STRIVEPAY_ENVIRONMENT=PRODUCTION`, simulator off.

Protect `main` on each app repo; only Actions with `environment: production` may deploy.
