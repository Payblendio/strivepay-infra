# Staging verification

After first full deploy to `strivepay-staging`:

```powershell
# Service URL (before custom domains)
$url = aws lightsail get-container-services --region eu-west-2 --service-name strivepay-staging --query "containerServices[0].url" --output text
curl -fsS "https://$url/" 

# With custom domains + Host routing
$env:STRIVEPAY_API_BASE = "https://api.staging.strivepay.io"
# From consumer-api tools:
.\scripts\Test-StrivePayPromotion.ps1 -BaseUrl $env:STRIVEPAY_API_BASE
```

Checks:

- [ ] Proxy returns 200 on `/`
- [ ] API health via `https://api.staging.strivepay.io/...`
- [ ] Consumer login at `https://staging.strivepay.io`
- [ ] Admin login at `https://cockpit.staging.strivepay.io`
- [ ] Flyway applied (api logs / schema_version)
- [ ] Postgres not publicly reachable
