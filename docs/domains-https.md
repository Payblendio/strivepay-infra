# Domain + HTTPS attachment

Lightsail Container Services have **no static IP** for Cloudflare `A` records. Use **CNAME** to the service hostname.

## Staging Cloudflare DNS

Target: `strivepay-staging.jsa9vsb7w2q98.eu-west-2.cs.amazonlightsail.com`

| Type | Name | Content |
|---|---|---|
| CNAME | `api.staging` | `strivepay-staging.jsa9vsb7w2q98.eu-west-2.cs.amazonlightsail.com` |
| CNAME | `cockpit.staging` | same |
| CNAME | `staging` | same |

Hosts:

- API: `api.staging.strivepay.io`
- Admin (cockpit): `cockpit.staging.strivepay.io`
- Consumer web: `staging.strivepay.io`

## Lightsail certificate + attach

```powershell
aws lightsail create-certificate `
  --region eu-west-2 `
  --certificate-name strivepay-staging-cert `
  --domain-name api.staging.strivepay.io `
  --subject-alternative-names staging.strivepay.io cockpit.staging.strivepay.io

# Complete DNS validation CNAMEs shown in:
aws lightsail get-certificates --region eu-west-2 --certificate-name strivepay-staging-cert

aws lightsail update-container-service `
  --region eu-west-2 `
  --service-name strivepay-staging `
  --public-domain-names file://deployments/domains.staging.json
```

Proxy env must match: `API_HOST`, `APP_HOST` (= consumer), `ADMIN_HOST` (= cockpit).

## Production

Target: `strivepay-production.jsa9vsb7w2q98.eu-west-2.cs.amazonlightsail.com`

| Host | Purpose |
|---|---|
| `api.strivepay.io` | API |
| `cockpit.strivepay.io` | Admin |
| `strivepay.io` | Consumer web |

Same certificate + `domains.production.json` flow.
