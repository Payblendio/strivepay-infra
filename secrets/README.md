# Staging env file for GitHub sync (no secrets committed)

Copy `secrets/staging.zeptomail.env` (generated locally) or build `secrets/staging.env` from
`consumer-api/.env`, then run:

```cmd
cd strivepay-infra
scripts\Set-StrivePayGitHubEnv.cmd staging
```

Or with an explicit file:

```cmd
scripts\Set-StrivePayGitHubEnv.cmd staging secrets\staging.env
```

Dry run:

```cmd
scripts\Set-StrivePayGitHubEnv.cmd staging --dry-run
```

## ZeptoMail note

Legacy PHP StrivePay stored ZeptoMail in **DB** (`settings.smtp_details`: `zeptomail_apikey`, `zeptomail_sendfrom`), not `.env`.
The new API uses env:

| Key | Purpose |
|---|---|
| `STRIVEPAY_EMAIL_PROVIDER=zeptomail` | Use HTTP API (like legacy) |
| `STRIVEPAY_ZEPTOMAIL_API_KEY` | Zoho Send Mail token (`Zoho-enczapikey …`) |
| `STRIVEPAY_ZEPTOMAIL_FROM` | e.g. `notify@strivepay.io` |
| `STRIVEPAY_ZEPTOMAIL_FROM_NAME` | `StrivePay` |

SMTP fallback (optional): `smtp.zeptomail.com:587`, user `emailapikey`, password = token.
