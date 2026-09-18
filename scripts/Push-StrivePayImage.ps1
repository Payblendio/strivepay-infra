<#
.SYNOPSIS
  Push a local Docker image to a Lightsail container service and return the Lightsail image name.
#>
param(
  [Parameter(Mandatory = $true)]
  [string]$ServiceName,

  [Parameter(Mandatory = $true)]
  [string]$ContainerName,

  [Parameter(Mandatory = $true)]
  [string]$LocalImage,

  [string]$Region = "eu-west-2"
)

$ErrorActionPreference = "Stop"

Write-Host "Pushing $LocalImage as $ContainerName to $ServiceName ($Region)..."
# aws lightsail push-container-image prints the image label to stderr/stdout
$output = aws lightsail push-container-image `
  --region $Region `
  --service-name $ServiceName `
  --label $ContainerName `
  --image $LocalImage 2>&1 | Out-String

Write-Host $output

if ($output -match 'Refer to this image as "(:[^"]+)"') {
  $ref = $Matches[1]
  Write-Host "Lightsail image: $ref"
  # strip leading colon for our Build script which re-adds it via template
  $label = $ref.TrimStart(':')
  Write-Output $label
  return
}

if ($output -match '([a-z0-9-]+\.[a-z0-9-]+\.\d+)') {
  Write-Output $Matches[1]
  return
}

throw "Could not parse Lightsail image reference from push output"
