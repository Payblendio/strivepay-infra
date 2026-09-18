<#
.SYNOPSIS
  Push env keys to GitHub Environment secrets/variables for StrivePay repos.

.PARAMETER Environment
  staging | production

.PARAMETER EnvFile
  Optional KEY=value file. Ignored when -ManualOnly is set.

.PARAMETER Set
  One or more KEY=value overrides (win over the env file). Use this to update
  staging URLs without copying LAN values from consumer-api/.env.

.PARAMETER Keys
  If set, only these keys are pushed (after merges).

.PARAMETER ManualOnly
  Do not read any .env file; only -Set values (+ staging host defaults if missing).

.EXAMPLE
  # Full sync from secrets\staging.env
  .\Set-StrivePayGitHubEnv.ps1 -Environment staging

.EXAMPLE
  # Manual URL updates only (no .env)
  .\Set-StrivePayGitHubEnv.ps1 -Environment staging -ManualOnly -Set @(
    "STRIVEPAY_WEB_BASE_URL=https://staging.strivepay.io",
    "STRIVEPAY_SUPPORT_CUSTOMER_URL=https://staging.strivepay.io/dashboard/support",
    "STRIVEPAY_SUPPORT_ALLOWED_ORIGINS=https://staging.strivepay.io,https://cockpit.staging.strivepay.io",
    "STRIVEPAY_SAFEHAVEN_CALLBACK_URL=https://api.staging.strivepay.io/webhooks/ngn-bank"
  )
#>
param(
  [ValidateSet("staging", "production")]
  [string]$Environment = "staging",

  [string]$EnvFile = "",

  [string[]]$Set = @(),

  [string[]]$Keys = @(),

  [switch]$ManualOnly,

  [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent

function Add-EnvLine([hashtable]$Target, [string]$Line) {
  $line = $Line.Trim()
  if (-not $line -or $line.StartsWith("#")) { return }
  $eq = $line.IndexOf("=")
  if ($eq -lt 1) { return }
  $key = $line.Substring(0, $eq).Trim()
  $val = $line.Substring($eq + 1).Trim()
  if (($val.StartsWith("'") -and $val.EndsWith("'")) -or ($val.StartsWith('"') -and $val.EndsWith('"'))) {
    $val = $val.Substring(1, $val.Length - 2)
  }
  $Target[$key] = $val
}

$map = @{}

if (-not $ManualOnly) {
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
  if ($EnvFile -and (Test-Path $EnvFile)) {
    Write-Host "Reading $EnvFile"
    Get-Content $EnvFile | ForEach-Object { Add-EnvLine $map $_ }
  } elseif ($Set.Count -eq 0) {
    throw "No EnvFile found and no -Set values. Use -ManualOnly -Set KEY=value … or create secrets\$Environment.env"
  } else {
    Write-Host "No EnvFile; applying -Set only"
  }
} else {
  Write-Host "ManualOnly: skipping .env file"
}

foreach ($item in $Set) { Add-EnvLine $map $item }

Write-Host "Target GitHub environment: $Environment"

# Non-secret host/url keys → GitHub Variables
$variableKeys = [System.Collections.Generic.HashSet[string]]::new([string[]]@(
  "AWS_REGION", "LIGHTSAIL_SERVICE_NAME",
  "API_HOST", "APP_HOST", "ADMIN_HOST",
  "CONSUMER_API_URL", "ADMIN_API_URL", "NEXT_PUBLIC_APP_URL",
  "STRIVEPAY_ENVIRONMENT", "STRIVEPAY_EMAIL_PROVIDER",
  "STRIVEPAY_SMTP_HOST", "STRIVEPAY_SMTP_PORT", "STRIVEPAY_SMTP_FROM",
  "STRIVEPAY_SMTP_STARTTLS_ENABLED", "STRIVEPAY_SMTP_ENABLED",
  "STRIVEPAY_ZEPTOMAIL_FROM", "STRIVEPAY_ZEPTOMAIL_FROM_NAME",
  "STRIVEPAY_WEB_BASE_URL", "STRIVEPAY_SUPPORT_CUSTOMER_URL", "STRIVEPAY_SUPPORT_ALLOWED_ORIGINS",
  "STRIVEPAY_SAFEHAVEN_CALLBACK_URL",
  "STRIVEPAY_BAKKT_MODE", "STRIVEPAY_QUIDAX_MODE", "STRIVEPAY_DOT_ENABLED",
  "STRIVEPAY_FCM_PROJECT_ID", "STRIVEPAY_PUSH_ENABLED", "STRIVEPAY_SIMULATOR_ENABLED"
))

$apiSecretPrefixes = @("STRIVEPAY_", "POSTGRES_", "AWS_ROLE_ARN")
# Never sync LAN/dev paths from a laptop .env into staging
$skipLocal = @(
  "STRIVEPAY_POSTGRES_HOST_PORT", "STRIVEPAY_HTTP_PORT", "STRIVEPAY_HTTP_BIND",
  "STRIVEPAY_DB_URL", "STRIVEPAY_LOCAL_DB_PASSWORD", "STRIVEPAY_FCM_CREDENTIALS_PATH"
)

$repos = @{
  "Payblendio/strivepay-api"           = @{ secrets = $true }
  "Payblendio/strivepay-infra"         = @{ secrets = $true }
  "Payblendio/strivepay-consumer-web"  = @{ secrets = $false }
  "Payblendio/strivepay-admin-web"     = @{ secrets = $false }
}

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
    STRIVEPAY_WEB_BASE_URL = "https://staging.strivepay.io"
    STRIVEPAY_SUPPORT_CUSTOMER_URL = "https://staging.strivepay.io/dashboard/support"
    STRIVEPAY_SUPPORT_ALLOWED_ORIGINS = "https://staging.strivepay.io,https://cockpit.staging.strivepay.io"
    STRIVEPAY_SAFEHAVEN_CALLBACK_URL = "https://api.staging.strivepay.io/webhooks/ngn-bank"
  }
}

if (-not $ManualOnly -and $defaults.ContainsKey($Environment)) {
  foreach ($k in $defaults[$Environment].Keys) {
    if (-not $map.ContainsKey($k) -or [string]::IsNullOrWhiteSpace($map[$k])) {
      $map[$k] = $defaults[$Environment][$k]
    }
  }
} elseif ($ManualOnly -and $defaults.ContainsKey($Environment) -and $Keys.Count -eq 0 -and $Set.Count -gt 0) {
  # When manually setting a few keys, do not force-fill the whole default map unless requested
}

# Optional: with ManualOnly and -ApplyDefaults, fill host defaults
# (kept simple: if ManualOnly and map empty of hosts, caller passes -Set)

if ($Keys.Count -gt 0) {
  $filtered = @{}
  foreach ($k in $Keys) {
    if ($map.ContainsKey($k)) { $filtered[$k] = $map[$k] }
    else { Write-Warning "Key not found in map: $k" }
  }
  $map = $filtered
}

if ($map.Count -eq 0) { throw "Nothing to push. Pass -Set KEY=value or an EnvFile." }

function Set-GhSecret([string]$Repo, [string]$Name, [string]$Value) {
  if ($DryRun) { Write-Host "  SECRET $Repo $Name"; return }
  $Value | gh secret set $Name -R $Repo -e $Environment
}

function Set-GhVariable([string]$Repo, [string]$Name, [string]$Value) {
  if ($DryRun) { Write-Host "  VAR $Repo $Name=$Value"; return }
  gh variable set $Name -R $Repo -e $Environment -b $Value | Out-Null
}

function Push-OneKey([string]$Repo, [bool]$AllowSecrets, [string]$Key, [string]$Value) {
  if ($skipLocal -contains $Key) {
    # Still allow if explicitly in -Set / -Keys (manual intent)
    if ($Set.Count -eq 0 -and $Keys.Count -eq 0) { return }
  }
  if ($variableKeys.Contains($Key) -or $Key -in @("AWS_REGION", "LIGHTSAIL_SERVICE_NAME", "API_HOST", "APP_HOST", "ADMIN_HOST", "CONSUMER_API_URL", "ADMIN_API_URL")) {
    Set-GhVariable $Repo $Key $Value
    return
  }
  if (-not $AllowSecrets) { return }
  $isApi = $false
  foreach ($p in $apiSecretPrefixes) {
    if ($Key -eq $p -or $Key.StartsWith($p)) { $isApi = $true; break }
  }
  if ($Key -eq "AWS_ROLE_ARN" -or $isApi) { Set-GhSecret $Repo $Key $Value }
}

foreach ($repo in $repos.Keys) {
  Write-Host "=== $repo ==="
  $allowSecrets = [bool]$repos[$repo].secrets

  foreach ($key in @($map.Keys)) {
    Push-OneKey $repo $allowSecrets $key $map[$key]
  }

  if ($repo -eq "Payblendio/strivepay-consumer-web" -and $map.ContainsKey("APP_HOST")) {
    Set-GhVariable $repo "NEXT_PUBLIC_APP_URL" ("https://" + $map["APP_HOST"])
  }
  if ($repo -eq "Payblendio/strivepay-admin-web" -and $map.ContainsKey("ADMIN_HOST")) {
    Set-GhVariable $repo "NEXT_PUBLIC_APP_URL" ("https://" + $map["ADMIN_HOST"])
  }
}

Write-Host "Done. Review:"
Write-Host "  gh variable list -R Payblendio/strivepay-api -e $Environment"
Write-Host "  gh secret list -R Payblendio/strivepay-api -e $Environment"
