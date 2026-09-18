<#
.SYNOPSIS
  Bootstrap one Lightsail Container Service + dump bucket for an environment.
.PARAMETER Environment
  staging | production
.PARAMETER Region
  AWS region for Lightsail (default eu-west-2)
.PARAMETER Power
  Container service power: medium (staging default) or large (production default)
#>
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("staging", "production")]
  [string]$Environment,

  [string]$Region = "eu-west-2",

  [ValidateSet("medium", "large", "xlarge")]
  [string]$Power = $(if ($Environment -eq "production") { "large" } else { "medium" }),

  [int]$Scale = 1
)

$ErrorActionPreference = "Stop"
$service = "strivepay-$Environment"
$bucket = "strivepay-db-dumps-$Environment"

Write-Host "Creating Lightsail container service $service ($Power x$Scale) in $Region..."
# Some accounts reject large/xlarge on first create; start nano then scale up.
$existingJson = aws lightsail get-container-services --region $Region --service-name $service 2>$null
if ($LASTEXITCODE -eq 0 -and $existingJson -match $service) {
  Write-Host "Service $service already exists."
} else {
  aws lightsail create-container-service `
    --region $Region `
    --service-name $service `
    --power nano `
    --scale $Scale | Out-Host
  if ($Power -ne "nano") {
    Write-Host "Scaling $service to $Power..."
    aws lightsail update-container-service `
      --region $Region `
      --service-name $service `
      --power $Power `
      --scale $Scale | Out-Host
  }
}

Write-Host "Waiting for service $service to become READY..."
do {
  Start-Sleep -Seconds 15
  $state = aws lightsail get-container-services --region $Region --service-name $service `
    --query "containerServices[0].state" --output text
  Write-Host "  state=$state"
} while ($state -notin @("READY", "RUNNING"))

Write-Host "Ensuring Object Storage bucket $bucket for Postgres dumps..."
$buckets = aws lightsail get-buckets --region $Region --query "buckets[?name=='$bucket'].name" --output text 2>$null
if ($buckets -eq $bucket) {
  Write-Host "Bucket $bucket already exists."
} else {
  aws lightsail create-bucket --region $Region --bucket-name $bucket --bundle-id small_1_0 | Out-Host
}

Write-Host @"

Bootstrap complete for $Environment.
Next:
  1. Fill GitHub Environment secrets (see secrets/$Environment.checklist.md)
  2. Push images via GitHub Actions (develop -> staging, main -> production)
  3. Attach custom domains with:
       aws lightsail create-container-service-deployment ...
       aws lightsail update-container-service --public-domain-names ...
  Default public URL once deployed:
       https://$service.$Region.cs.amazonlightsail.com
"@
