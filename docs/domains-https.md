# Domain + HTTPS attachment

## Staging

After the container service is READY and first deployment succeeded:

```powershell
aws lightsail create-certificate `
  --region eu-west-2 `
  --certificate-name strivepay-staging-cert `
  --domain-name api.staging.strivepay.io `
  --subject-alternative-names app.staging.strivepay.io admin.staging.strivepay.io

# Complete DNS validation CNAMEs shown in:
aws lightsail get-certificates --region eu-west-2 --certificate-name strivepay-staging-cert

aws lightsail update-container-service `
  --region eu-west-2 `
  --service-name strivepay-staging `
  --public-domain-names file://deployments/domains.staging.json
```

Point DNS CNAMEs for the three hosts at the Lightsail service URL
(`strivepay-staging.<id>.eu-west-2.cs.amazonlightsail.com`).

## Production

Same flow with `strivepay-production-cert` and `domains.production.json`.

Lightsail terminates TLS at the service edge; Caddy routes by `Host` header to api / consumer-web / admin-web.
