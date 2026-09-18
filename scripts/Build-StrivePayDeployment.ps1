<#
.SYNOPSIS
  Build a Lightsail container-service deployment JSON from the template + image tags.
.PARAMETER Environment
  staging | production
.PARAMETER ImageTags
  Hashtable of container name -> Lightsail image label (e.g. @{ api = "strivepay-staging.api.1" })
.PARAMETER Secrets
  Hashtable of secret placeholder replacements (POSTGRES_PASSWORD_VALUE, etc.)
.PARAMETER OutFile
  Path to write the rendered deployment JSON
#>
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("staging", "production")]
  [string]$Environment,

  [Parameter(Mandatory = $true)]
  [hashtable]$ImageTags,

  [Parameter(Mandatory = $true)]
  [hashtable]$Secrets,

  [string]$OutFile = "deployment.$Environment.json",

  [string]$TemplatePath = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not $TemplatePath) {
  $TemplatePath = Join-Path $PSScriptRoot "..\deployments\containers.template.json"
}
$TemplatePath = (Resolve-Path $TemplatePath).Path

$hostDefaults = @{
  staging = @{
    API_HOST   = "api.staging.strivepay.io"
    APP_HOST   = "staging.strivepay.io"
    ADMIN_HOST = "cockpit.staging.strivepay.io"
    STRIVEPAY_ENVIRONMENT = "SANDBOX"
    BAKKT_MODE = "SANDBOX"
    QUIDAX_MODE = "SANDBOX"
    DOT_ENABLED = "false"
    SMTP_STARTTLS = "true"
  }
  production = @{
    API_HOST   = "api.strivepay.io"
    APP_HOST   = "strivepay.io"
    ADMIN_HOST = "cockpit.strivepay.io"
    STRIVEPAY_ENVIRONMENT = "PRODUCTION"
    BAKKT_MODE = "LIVE"
    QUIDAX_MODE = "LIVE"
    DOT_ENABLED = "true"
    SMTP_STARTTLS = "true"
  }
}

$cfg = $hostDefaults[$Environment]
$json = Get-Content -Raw -Path $TemplatePath

foreach ($name in $ImageTags.Keys) {
  $tag = [string]$ImageTags[$name]
  $json = $json.Replace(":$name.IMAGE_TAG", ":$tag")
}

# Keep any container whose image tag was not supplied: leave placeholder and fail later if still present
$json = $json.Replace("API_HOST_VALUE", $cfg.API_HOST)
$json = $json.Replace("APP_HOST_VALUE", $cfg.APP_HOST)
$json = $json.Replace("ADMIN_HOST_VALUE", $cfg.ADMIN_HOST)
$json = $json.Replace("STRIVEPAY_ENVIRONMENT_VALUE", $cfg.STRIVEPAY_ENVIRONMENT)
$json = $json.Replace("BAKKT_MODE_VALUE", $cfg.BAKKT_MODE)
$json = $json.Replace("QUIDAX_MODE_VALUE", $cfg.QUIDAX_MODE)
$json = $json.Replace("DOT_ENABLED_VALUE", $cfg.DOT_ENABLED)
$json = $json.Replace("SMTP_STARTTLS_VALUE", $cfg.SMTP_STARTTLS)

foreach ($key in $Secrets.Keys) {
  $json = $json.Replace($key, [string]$Secrets[$key])
}

if ($json -match "IMAGE_TAG|_VALUE") {
  $leftover = [regex]::Matches($json, "[A-Z0-9_]*IMAGE_TAG|[A-Z0-9_]+_VALUE") | ForEach-Object { $_.Value } | Select-Object -Unique
  throw "Unresolved placeholders in deployment JSON: $($leftover -join ', ')"
}

# Normalize Lightsail image refs: values are already "service.container.version" without leading colon in push output;
# template used ":name.IMAGE_TAG" so after replace we get ":service.container.N" which Lightsail expects.
Set-Content -Path $OutFile -Value $json -Encoding utf8NoBOM
Write-Host "Wrote $OutFile"
return $OutFile
