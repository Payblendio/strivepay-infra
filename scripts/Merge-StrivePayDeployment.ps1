<#
.SYNOPSIS
  Fetch the current Lightsail deployment and overwrite selected container images.
  Used by GitHub Actions so api/web deploys keep postgres and sibling containers.
#>
param(
  [Parameter(Mandatory = $true)]
  [string]$ServiceName,

  [Parameter(Mandatory = $true)]
  [hashtable]$ImageUpdates,

  [Parameter(Mandatory = $true)]
  [string]$OutFile,

  [string]$Region = "eu-west-2",

  [hashtable]$EnvironmentOverrides = @{}
)

$ErrorActionPreference = "Stop"

$raw = aws lightsail get-container-services --region $Region --service-name $ServiceName | ConvertFrom-Json
$svc = $raw.containerServices[0]
if (-not $svc) { throw "Service $ServiceName not found" }

$dep = $svc.currentDeployment
if (-not $dep -or -not $dep.containers) {
  throw "No currentDeployment on $ServiceName. Run an initial full deploy from containers.template.json first."
}

$containers = @{}
foreach ($prop in $dep.containers.PSObject.Properties) {
  $name = $prop.Name
  $c = $prop.Value
  $entry = @{
    image = [string]$c.image
  }
  if ($c.ports) {
    $ports = @{}
    foreach ($p in $c.ports.PSObject.Properties) { $ports[$p.Name] = [string]$p.Value }
    $entry.ports = $ports
  }
  if ($c.environment) {
    $envMap = @{}
    foreach ($e in $c.environment.PSObject.Properties) { $envMap[$e.Name] = [string]$e.Value }
    $entry.environment = $envMap
  }
  if ($ImageUpdates.ContainsKey($name)) {
    $img = [string]$ImageUpdates[$name]
    if (-not $img.StartsWith(":")) { $img = ":$img" }
    $entry.image = $img
  }
  if ($EnvironmentOverrides.ContainsKey($name)) {
    if (-not $entry.environment) { $entry.environment = @{} }
    foreach ($ek in $EnvironmentOverrides[$name].Keys) {
      $entry.environment[$ek] = [string]$EnvironmentOverrides[$name][$ek]
    }
  }
  $containers[$name] = $entry
}

$pe = $dep.publicEndpoint
$publicEndpoint = @{
  containerName = [string]$pe.containerName
  containerPort = [int]$pe.containerPort
}
if ($pe.healthCheck) {
  $publicEndpoint.healthCheck = @{
    healthyThreshold   = [int]$pe.healthCheck.healthyThreshold
    unhealthyThreshold = [int]$pe.healthCheck.unhealthyThreshold
    timeoutSeconds     = [int]$pe.healthCheck.timeoutSeconds
    intervalSeconds    = [int]$pe.healthCheck.intervalSeconds
    path               = [string]$pe.healthCheck.path
    successCodes       = [string]$pe.healthCheck.successCodes
  }
}

$result = [ordered]@{
  serviceName    = $ServiceName
  containers     = $containers
  publicEndpoint = $publicEndpoint
}

$dir = Split-Path -Parent $OutFile
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
$json = $result | ConvertTo-Json -Depth 20
[System.IO.File]::WriteAllText($OutFile, $json)
Write-Host "Wrote merged deployment $OutFile"
