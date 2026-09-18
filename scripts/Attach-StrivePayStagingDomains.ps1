<#
.SYNOPSIS
  Wait for strivepay-staging-cert ISSUED, then attach custom domains to Lightsail.
#>
param(
  [string]$Region = "eu-west-2",
  [string]$ServiceName = "strivepay-staging",
  [string]$CertificateName = "strivepay-staging-cert",
  [string]$DomainsFile = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
if (-not $DomainsFile) {
  $DomainsFile = Join-Path $root "deployments\domains.staging.json"
}

Write-Host "Waiting for certificate $CertificateName to become ISSUED..."
for ($i = 0; $i -lt 60; $i++) {
  $certs = aws lightsail get-certificates --region $Region --certificate-name $CertificateName --include-certificate-details --output json | ConvertFrom-Json
  $detail = $certs.certificates[0].certificateDetail
  $status = $detail.status
  Write-Host ("{0:HH:mm:ss} status={1}" -f (Get-Date), $status)
  foreach ($r in $detail.domainValidationRecords) {
    Write-Host ("  {0}: {1}" -f $r.domainName, $r.validationStatus)
  }
  if ($status -eq "ISSUED") { break }
  if ($status -match "FAILED|EXPIRED|REVOKED") { throw "Certificate $status" }
  Start-Sleep -Seconds 20
}

if ($status -ne "ISSUED") { throw "Timed out waiting for certificate ISSUED" }

Write-Host "Attaching domains from $DomainsFile ..."
aws lightsail update-container-service `
  --region $Region `
  --service-name $ServiceName `
  --public-domain-names "file://$($DomainsFile -replace '\\','/')"

Write-Host "Done. Verify with: curl.exe -sI https://api.staging.strivepay.io/"
