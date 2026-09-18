<#
.SYNOPSIS
  Push env file keys to GitHub Environment secrets/variables for all StrivePay repos.

.EXAMPLE
  # From CMD:
  scripts\Set-StrivePayGitHubEnv.cmd staging

  # Or PowerShell:
  .\scripts\Set-StrivePayGitHubEnv.ps1 -Environment staging -EnvFile .\secrets\staging.env
#>
param(
  [ValidateSet("staging", "production")]
  [string]$Environment = "staging",

  [string]$EnvFile = "",

  [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent

if (-not $EnvFile) {
  $candidates = @(
    (Join-Path $root "secrets\$Environment.env"),
    (Join-Path $root "secrets\staging.zeptomail.env"),
    (Join-Path (Split-Path $root -Parent) "consumer-api\.env")
  )
  foreach ($c in $candidates) {
    if (Test-Path $c) { $EnvFile = $c; break }
  }
}
if (-not $EnvFile -or -not (Test-Path $EnvFile)) {
  throw "Env file not found. Create strivepay-infra\secrets\$Environment.env (KEY=value lines)."
}

Write-Host "Reading $EnvFile"
Write-Host "Target GitHub environment: $Environment"

$map = @{}
Get-Content $EnvFile | ForEach-Object {
  $line = $_.Trim()
  if (-not $line -or $line.StartsWith("#")) { return }
  $eq = $line.IndexOf("=")
  if ($eq -lt 1) { return }
  $key = $line.Substring(0, $eq).Trim()
  $val = $line.Substring($eq + 1).Trim()
  if (($val.StartsWith("'") -and $val.EndsWith("'")) -or ($val.StartsWith('"') -and $val.EndsWith('"'))) {
    $val = $val.Substring(1, $val.Length - 2)
  }
  $map[$key] = $val
}

# Non-secret host/url keys → GitHub Variables; everything else → Secrets
$variableKeys = [System.Collections.Generic.HashSet[string]]::new([string[]]@(
  "AWS_REGION", "LIGHTSAIL_SERVICE_NAME",
  "API_HOST", "APP_HOST", "ADMIN_HOST",
  "CONSUMER_API_URL", "ADMIN_API_URL", "NEXT_PUBLIC_APP_URL",
  "STRIVEPAY_ENVIRONMENT", "STRIVEPAY_EMAIL_PROVIDER",
  "STRIVEPAY_SMTP_HOST", "STRIVEPAY_SMTP_PORT", "STRIVEPAY_SMTP_FROM",
  "STRIVEPAY_SMTP_STARTTLS_ENABLED", "STRIVEPAY_SMTP_ENABLED",
  "STRIVEPAY_ZEPTOMAIL_FROM", "STRIVEPAY_ZEPTOMAIL_FROM_NAME",
  "STRIVEPAY_WEB_BASE_URL", "STRIVEPAY_SUPPORT_CUSTOMER_URL", "STRIVEPAY_SUPPORT_ALLOWED_ORIGINS",
  "STRIVEPAY_BAKKT_MODE", "STRIVEPAY_QUIDAX_MODE", "STRIVEPAY_DOT_ENABLED",
  "STRIVEPAY_FCM_PROJECT_ID", "STRIVEPAY_PUSH_ENABLED"
))

$apiSecretPrefixes = @("STRIVEPAY_", "POSTGRES_", "AWS_ROLE_ARN")
$skipLocal = @(
  "STRIVEPAY_POSTGRES_HOST_PORT", "STRIVEPAY_HTTP_PORT", "STRIVEPAY_HTTP_BIND",
  "STRIVEPAY_DB_URL", "STRIVEPAY_LOCAL_DB_PASSWORD", "STRIVEPAY_FCM_CREDENTIALS_PATH",
  "STRIVEPAY_SAFEHAVEN_CALLBACK_URL"
)

$repos = @{
  "Payblendio/strivepay-api" = @{ secrets = $true; webs = $false }
  "Payblendio/strivepay-infra" = @{ secrets = $true; webs = $false }
  "Payblendio/strivepay-consumer-web" = @{ secrets = $false; webs = $true }
  "Payblendio/strivepay-admin-web" = @{ secrets = $false; webs = $true }
}

# Staging host defaults if missing
$defaults = @{
  staging = @{
    API_HOST = "api.staging.strivepay.io"
    APP_HOST = "staging.strivepay.io"
    ADMIN_HOST = "cockpit.staging.strivepay.io"
    CONSUMER_API_URL = "https://api.staging.strivepay.io"
    ADMIN_API_URL = "https://api.staging.strivepay.io"
    AWS_REGION = "eu-west-2"
    LIGHTSAIL_SERVICE_NAME = "strivepay-staging"
    STRIVEPAY_EMAIL_PROVIDER = "zeptomail"
    STRIVEPAY_ENVIRONMENT = "SANDBOX"
  }
}
if ($defaults.ContainsKey($Environment)) {
  foreach ($k in $defaults[$Environment].Keys) {
    if (-not $map.ContainsKey($k) -or [string]::IsNullOrWhiteSpace($map[$k])) {
      $map[$k] = $defaults[$Environment][$k]
    }
  }
}

function Set-GhSecret([string]$Repo, [string]$Name, [string]$Value) {
  if ($DryRun) { Write-Host "  SECRET $Repo $Name"; return }
  $Value | gh secret set $Name -R $Repo -e $Environment
}

function Set-GhVariable([string]$Repo, [string]$Name, [string]$Value) {
  if ($DryRun) { Write-Host "  VAR $Repo $Name=$Value"; return }
  gh variable set $Name -R $Repo -e $Environment -b $Value | Out-Null
}

foreach ($repo in $repos.Keys) {
  Write-Host "=== $repo ==="
  $meta = $repos[$repo]

  foreach ($k in @("AWS_REGION", "LIGHTSAIL_SERVICE_NAME", "API_HOST", "APP_HOST", "ADMIN_HOST", "CONSUMER_API_URL", "ADMIN_API_URL")) {
    if ($map.ContainsKey($k)) { Set-GhVariable $repo $k $map[$k] }
  }

  if ($repo -eq "Payblendio/strivepay-consumer-web" -and $map.ContainsKey("APP_HOST")) {
    Set-GhVariable $repo "NEXT_PUBLIC_APP_URL" ("https://" + $map["APP_HOST"])
    if ($map.ContainsKey("CONSUMER_API_URL")) { Set-GhVariable $repo "CONSUMER_API_URL" $map["CONSUMER_API_URL"] }
  }
  if ($repo -eq "Payblendio/strivepay-admin-web" -and $map.ContainsKey("ADMIN_HOST")) {
    Set-GhVariable $repo "NEXT_PUBLIC_APP_URL" ("https://" + $map["ADMIN_HOST"])
    if ($map.ContainsKey("ADMIN_API_URL")) { Set-GhVariable $repo "ADMIN_API_URL" $map["ADMIN_API_URL"] }
  }

  if (-not $meta.secrets) { continue }

  if ($map.ContainsKey("AWS_ROLE_ARN")) { Set-GhSecret $repo "AWS_ROLE_ARN" $map["AWS_ROLE_ARN"] }

  foreach ($key in $map.Keys) {
    if ($skipLocal -contains $key) { continue }
    if ($variableKeys.Contains($key)) {
      Set-GhVariable $repo $key $map[$key]
      continue
    }
    $isApi = $false
    foreach ($p in $apiSecretPrefixes) {
      if ($key -eq $p -or $key.StartsWith($p)) { $isApi = $true; break }
    }
    if ($isApi) { Set-GhSecret $repo $key $map[$key] }
  }
}

Write-Host "Done. Review: gh secret list -R Payblendio/strivepay-api -e $Environment"
