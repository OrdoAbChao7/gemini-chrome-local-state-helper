<#
.SYNOPSIS
  Safely applies a minimal, reversible Gemini/Glic Local State configuration.
.DESCRIPTION
  This script never downloads code, edits the registry, changes Chrome policies,
  touches profiles, or sends data to the network. It requires Chrome to be fully
  closed, creates a timestamped full-file backup, changes only documented
  Local State keys, writes atomically, and parses the resulting JSON to verify it.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
  [ValidateSet('US','CA','GB','AU','NZ')]
  [string]$Region = 'US',
  [string]$UserDataDir = (Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data'),
  [string]$BackupDirectory = (Join-Path $env:USERPROFILE 'Documents\ChromeLocalStateBackups'),
  [switch]$SkipRegion,
  [switch]$CreatePermanentCountry,
  [switch]$DryRun
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-LocalStatePath {
  param([string]$Root)
  $path = Join-Path $Root 'Local State'
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Chrome Local State was not found: $path" }
  return $path
}
function Stop-IfChromeRunning {
  $running = @(Get-Process chrome -ErrorAction SilentlyContinue)
  if ($running.Count -gt 0) { throw "Chrome is running ($($running.Count) process(es)). Close every Chrome window and background process, then run again." }
}
function Read-JsonFile {
  param([string]$Path)
  try { return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json) }
  catch { throw "Local State is not valid JSON: $($_.Exception.Message)" }
}
function Has-Property {
  param($Object,[string]$Name)
  return ($null -ne $Object -and $null -ne $Object.PSObject.Properties[$Name])
}
function Set-KnownProperty {
  param($Object,[string]$Name,$Value,[System.Collections.ArrayList]$Changes,[string]$DisplayPath)
  if (Has-Property $Object $Name) {
    if ($Object.$Name -ne $Value) { $Object.$Name = $Value; [void]$Changes.Add("$DisplayPath=$Value") }
    return $true
  }
  return $false
}
function Write-JsonAtomically {
  param($State,[string]$Destination)
  $tmp = "$Destination.manus-pending-$PID"
  $encoding = [System.Text.UTF8Encoding]::new($false)
  try {
    $json = $State | ConvertTo-Json -Depth 100
    [System.IO.File]::WriteAllText($tmp, $json, $encoding)
    [void](Read-JsonFile $tmp)
    Move-Item -LiteralPath $tmp -Destination $Destination -Force
  } finally {
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
  }
}

Stop-IfChromeRunning
$statePath = Get-LocalStatePath $UserDataDir
$originalHash = (Get-FileHash -LiteralPath $statePath -Algorithm SHA256).Hash
$state = Read-JsonFile $statePath
$changes = [System.Collections.ArrayList]::new()

if (-not (Has-Property $state 'glic')) {
  if (-not $DryRun) { $state | Add-Member -NotePropertyName 'glic' -NotePropertyValue ([PSCustomObject]@{ launcher_enabled = $true }) }
  [void]$changes.Add('glic.launcher_enabled=True (created glic object)')
} elseif ($state.glic -is [System.Management.Automation.PSCustomObject]) {
  if (-not (Has-Property $state.glic 'launcher_enabled')) {
    if (-not $DryRun) { $state.glic | Add-Member -NotePropertyName 'launcher_enabled' -NotePropertyValue $true }
    [void]$changes.Add('glic.launcher_enabled=True (created key)')
  } else { [void](Set-KnownProperty $state.glic 'launcher_enabled' $true $changes 'glic.launcher_enabled') }
} else { throw 'Local State contains a non-object glic value; stopped without making changes.' }

if (Has-Property $state 'profile' -and Has-Property $state.profile 'info_cache') {
  foreach ($profile in $state.profile.info_cache.PSObject.Properties) {
    if (Has-Property $profile.Value 'is_glic_eligible') {
      [void](Set-KnownProperty $profile.Value 'is_glic_eligible' $true $changes "profile.info_cache.$($profile.Name).is_glic_eligible")
    }
  }
}

if (-not $SkipRegion) {
  foreach ($name in @('variations_country','variations_safe_seed_session_consistency_country')) {
    [void](Set-KnownProperty $state $name $Region.ToLowerInvariant() $changes $name)
  }
  if ($CreatePermanentCountry -and -not (Has-Property $state 'permanent_country')) {
    if (-not $DryRun) { $state | Add-Member -NotePropertyName 'permanent_country' -NotePropertyValue $Region.ToLowerInvariant() }
    [void]$changes.Add("permanent_country=$($Region.ToLowerInvariant()) (created key)")
  } elseif ($CreatePermanentCountry) { [void](Set-KnownProperty $state 'permanent_country' $Region.ToLowerInvariant() $changes 'permanent_country') }
}

$result = [ordered]@{
  StatePath = $statePath
  OriginalSha256 = $originalHash
  BackupPath = $null
  Region = if($SkipRegion){'unchanged'}else{$Region}
  Changes = @($changes)
  Verified = $false
  DryRun = [bool]$DryRun
}
if ($DryRun) { return [PSCustomObject]$result }

if (-not $PSCmdlet.ShouldProcess($statePath, 'Back up and write validated Gemini/Glic Local State changes')) { return [PSCustomObject]$result }
New-Item -ItemType Directory -Path $BackupDirectory -Force | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = Join-Path $BackupDirectory "Local State.$stamp.bak"
if (Test-Path -LiteralPath $backup) { throw "Backup path already exists: $backup" }
Copy-Item -LiteralPath $statePath -Destination $backup
$metadata = [ordered]@{ Timestamp=(Get-Date).ToString('o'); Source=$statePath; Backup=$backup; OriginalSha256=$originalHash; Changes=@($changes) }
$metadata | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath "$backup.metadata.json" -Encoding UTF8
Write-JsonAtomically $state $statePath

$verified = Read-JsonFile $statePath
if (-not (Has-Property $verified 'glic') -or $verified.glic.launcher_enabled -ne $true) { throw 'Post-write validation failed for glic.launcher_enabled. Restore the generated backup.' }
$result.BackupPath = $backup
$result.Verified = $true
return [PSCustomObject]$result
