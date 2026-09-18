<#
.SYNOPSIS
  Dump Postgres from the Lightsail postgres container and upload to Object Storage.
  Requires: aws CLI, docker (for local dump via port-forward alternative), or
  run via GitHub Actions that execs through a one-shot sidecar pattern.

  Preferred path on Lightsail: use a one-shot deployment job container, or run
  pg_dump from a machine that can reach the private postgres hostname after
  temporarily exposing a tunnel. For hands-off CD, schedule this as a GitHub
  Actions workflow that:
    1. Starts a short-lived ECS/Lightsail-compatible dump job image, OR
    2. Uses aws lightsail to run a temporary container with network access.

  This script implements the durable path when DATABASE_URL is reachable
  (e.g. staging jump host, or CI with VPN). It uploads to Lightsail bucket.
#>
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("staging", "production")]
  [string]$Environment,

  [Parameter(Mandatory = $true)]
  [string]$DatabaseUrl,

  [string]$Region = "eu-west-2",

  [string]$Bucket = ""
)

$ErrorActionPreference = "Stop"
if (-not $Bucket) { $Bucket = "strivepay-db-dumps-$Environment" }

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$local = Join-Path $env:TEMP "strivepay-$Environment-$stamp.sql.gz"

Write-Host "Dumping database to $local ..."
# Expect DATABASE_URL like postgresql://user:pass@host:5432/db
& pg_dump $DatabaseUrl | & gzip > $local
if ($LASTEXITCODE -ne 0) { throw "pg_dump failed" }

$key = "postgres/$Environment/$stamp.sql.gz"
Write-Host "Uploading to lightsail://$Bucket/$key ..."

# Lightsail Object Storage is S3-compatible; use aws s3 with endpoint when configured,
# or lightsail push-object-to-bucket where available.
aws lightsail put-bucket-object `
  --region $Region `
  --bucket-name $Bucket `
  --key $key `
  --body $local 2>$null

if ($LASTEXITCODE -ne 0) {
  # Fallback: s3api-compatible upload via lightsail get-bucket-access-keys
  Write-Host "put-bucket-object unavailable; try aws s3 cp with Lightsail access keys."
  throw "Upload failed. Create access keys for $Bucket and use: aws s3 cp $local s3://$Bucket/$key --endpoint-url <lightsail-endpoint>"
}

Remove-Item $local -Force
Write-Host "Backup complete: $key"
