<#
.SYNOPSIS
  Create a Lightsail container service deployment from a rendered JSON file.
#>
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("staging", "production")]
  [string]$Environment,

  [Parameter(Mandatory = $true)]
  [string]$DeploymentFile,

  [string]$Region = "eu-west-2"
)

$ErrorActionPreference = "Stop"
$service = "strivepay-$Environment"
$DeploymentFile = (Resolve-Path $DeploymentFile).Path

$payload = Get-Content -Raw -Path $DeploymentFile | ConvertFrom-Json
if (-not $payload.serviceName) {
  $obj = Get-Content -Raw -Path $DeploymentFile | ConvertFrom-Json
  $wrapped = @{
    serviceName    = $service
    containers     = $obj.containers
    publicEndpoint = $obj.publicEndpoint
  }
  $tmp = Join-Path $env:TEMP "lightsail-deploy-$service.json"
  ($wrapped | ConvertTo-Json -Depth 20) | Set-Content -Path $tmp -Encoding utf8
  $DeploymentFile = $tmp
}

# AWS CLI on Windows wants file:// with forward slashes
$uri = "file://" + ($DeploymentFile -replace '\\', '/')

Write-Host "Deploying $DeploymentFile to $service ($Region)..."
aws lightsail create-container-service-deployment `
  --region $Region `
  --cli-input-json $uri | Out-Host

Write-Host "Waiting for deployment..."
do {
  Start-Sleep -Seconds 20
  $state = aws lightsail get-container-services --region $Region --service-name $service `
    --query "containerServices[0].state" --output text
  $detail = aws lightsail get-container-services --region $Region --service-name $service `
    --query "containerServices[0].currentDeployment.state" --output text 2>$null
  Write-Host "  service=$state deployment=$detail"
} while ($state -eq "DEPLOYING" -or $detail -eq "ACTIVATING")

Write-Host "Deployment finished. state=$state"
$url = aws lightsail get-container-services --region $Region --service-name $service `
  --query "containerServices[0].url" --output text
Write-Host "Public URL: https://$url"
