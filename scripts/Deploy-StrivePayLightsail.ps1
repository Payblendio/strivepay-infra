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

$containersPath = Join-Path $env:TEMP "lightsail-$service-containers.json"
$endpointPath = Join-Path $env:TEMP "lightsail-$service-endpoint.json"

python -c @"
import json, sys
d = json.load(open(r'$DeploymentFile'))
containers = d.get('containers') or d
endpoint = d.get('publicEndpoint')
if not endpoint:
    raise SystemExit('publicEndpoint missing')
json.dump(containers, open(r'$containersPath', 'w'))
json.dump(endpoint, open(r'$endpointPath', 'w'))
print('split ok')
"@

Write-Host "Deploying $DeploymentFile to $service ($Region)..."
aws lightsail create-container-service-deployment `
  --region $Region `
  --service-name $service `
  --containers "file://$containersPath" `
  --public-endpoint "file://$endpointPath" | Out-Host

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
