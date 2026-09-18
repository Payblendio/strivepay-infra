# Sync GitHub Environment secrets / variables

## See what is set

```cmd
gh variable list -R Payblendio/strivepay-api -e staging
gh secret list -R Payblendio/strivepay-api -e staging
```

Secret **values** are never shown after save—only names.

## Full sync from a file

```cmd
cd strivepay-infra
scripts\Set-StrivePayGitHubEnv.cmd staging
scripts\Set-StrivePayGitHubEnv.cmd staging --file secrets\staging.env
```

## Manual update (no `.env`)

Use this for staging public URLs so LAN IPs from `consumer-api/.env` are not copied:

```cmd
cd strivepay-infra
scripts\Set-StrivePayGitHubEnv.cmd staging --manual ^
  STRIVEPAY_WEB_BASE_URL=https://staging.strivepay.io ^
  STRIVEPAY_SUPPORT_CUSTOMER_URL=https://staging.strivepay.io/dashboard/support ^
  STRIVEPAY_SUPPORT_ALLOWED_ORIGINS=https://staging.strivepay.io,https://cockpit.staging.strivepay.io ^
  STRIVEPAY_SAFEHAVEN_CALLBACK_URL=https://api.staging.strivepay.io/webhooks/ngn-bank
```

Or one key with `gh` directly:

```cmd
gh variable set STRIVEPAY_WEB_BASE_URL -R Payblendio/strivepay-api -e staging -b "https://staging.strivepay.io"
gh secret set STRIVEPAY_ADMIN_PASSWORD -R Payblendio/strivepay-api -e staging
```

(`gh secret set` without `-b` prompts for the value.)

## Dry run

```cmd
scripts\Set-StrivePayGitHubEnv.cmd staging --manual --dry-run STRIVEPAY_WEB_BASE_URL=https://staging.strivepay.io
```

## ZeptoMail

Legacy PHP stored ZeptoMail in **DB**, not `.env`. Staging uses:

| Key | Purpose |
|---|---|
| `STRIVEPAY_EMAIL_PROVIDER=zeptomail` | HTTP API |
| `STRIVEPAY_ZEPTOMAIL_API_KEY` | Send Mail token |
| `STRIVEPAY_ZEPTOMAIL_FROM` | e.g. `notify@strivepay.io` |
