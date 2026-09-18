# Sync GitHub Environment secrets / variables

## See what is set

```cmd
gh variable list -R Payblendio/strivepay-api -e staging
gh secret list -R Payblendio/strivepay-api -e staging
```

Secret **values** are never shown after save—only names.

## Full sync from a secrets file

```cmd
cd strivepay-infra
scripts\Set-StrivePayGitHubEnv.cmd staging
scripts\Set-StrivePayGitHubEnv.cmd staging --file secrets\staging.env
```

## Manual update (no laptop `.env`)

Edit `secrets\staging.urls.env` (or your own file), then:

```cmd
cd strivepay-infra
scripts\Set-StrivePayGitHubEnv.cmd staging --manual --file secrets\staging.urls.env
```

Or PowerShell `-Set` (no CMD URL parsing issues):

```powershell
cd strivepay-infra
.\scripts\Set-StrivePayGitHubEnv.ps1 -Environment staging -ManualOnly -Set @(
  "STRIVEPAY_WEB_BASE_URL=https://staging.strivepay.io",
  "STRIVEPAY_SUPPORT_CUSTOMER_URL=https://staging.strivepay.io/dashboard/support",
  "STRIVEPAY_SUPPORT_ALLOWED_ORIGINS=https://staging.strivepay.io,https://cockpit.staging.strivepay.io",
  "STRIVEPAY_SAFEHAVEN_CALLBACK_URL=https://api.staging.strivepay.io/webhooks/ngn-bank"
)
```

One key with `gh`:

```cmd
gh variable set STRIVEPAY_WEB_BASE_URL -R Payblendio/strivepay-api -e staging -b "https://staging.strivepay.io"
gh secret set STRIVEPAY_ADMIN_PASSWORD -R Payblendio/strivepay-api -e staging
```

## ZeptoMail

| Key | Purpose |
|---|---|
| `STRIVEPAY_EMAIL_PROVIDER=zeptomail` | HTTP API |
| `STRIVEPAY_ZEPTOMAIL_API_KEY` | Send Mail token |
| `STRIVEPAY_ZEPTOMAIL_FROM` | e.g. `notify@strivepay.io` |
