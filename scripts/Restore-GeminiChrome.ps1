<#
.SYNOPSIS
  Restores a Local State backup created by Enable-GeminiChrome.ps1.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
  [string]$UserDataDir = (Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data'),
  [string]$BackupDirectory = (Join-Path $env:USERPROFILE 'Documents\ChromeLocalStateBackups'),
  [string]$BackupPath,
  [switch]$Latest,
  [switch]$NoPreRestoreBackup,
  [switch]$DryRun
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function Stop-IfChromeRunning { $running=@(Get-Process chrome -ErrorAction SilentlyContinue);if($running.Count -gt 0){throw "Chrome is running ($($running.Count) process(es)). Close it before restoring."} }
function Read-JsonFile([string]$Path){try{return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8|ConvertFrom-Json)}catch{throw "Backup is not valid JSON: $($_.Exception.Message)"}}
function Write-BytesAtomically([string]$Source,[string]$Destination){$tmp="$Destination.manus-restore-pending-$PID";try{if(Test-Path -LiteralPath $tmp){throw "Temporary restore path already exists: $tmp"};Copy-Item -LiteralPath $Source -Destination $tmp;[void](Read-JsonFile $tmp);Move-Item -LiteralPath $tmp -Destination $Destination -Force}finally{if(Test-Path -LiteralPath $tmp){Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue}}}
Stop-IfChromeRunning
$statePath=Join-Path $UserDataDir 'Local State';if(-not(Test-Path -LiteralPath $statePath)){throw "Local State was not found: $statePath"}
if($Latest){$BackupPath=(Get-ChildItem -LiteralPath $BackupDirectory -Filter 'Local State.*.bak' -File -ErrorAction Stop|Sort-Object LastWriteTime -Descending|Select-Object -First 1).FullName}
if([string]::IsNullOrWhiteSpace($BackupPath)){throw 'Provide -BackupPath or -Latest.'}
if(-not(Test-Path -LiteralPath $BackupPath -PathType Leaf)){throw "Backup not found: $BackupPath"}
[void](Read-JsonFile $BackupPath)
$result=[ordered]@{StatePath=$statePath;BackupPath=$BackupPath;PreRestoreBackup=$null;Restored=$false;DryRun=[bool]$DryRun}
if($DryRun){return [PSCustomObject]$result}
if(-not $PSCmdlet.ShouldProcess($statePath,'Restore Local State backup')){return [PSCustomObject]$result}
if(-not $NoPreRestoreBackup){New-Item -ItemType Directory -Path $BackupDirectory -Force|Out-Null;$stamp=Get-Date -Format 'yyyyMMdd-HHmmss';$pre=Join-Path $BackupDirectory "Local State.pre-restore.$stamp.bak";if(Test-Path -LiteralPath $pre){throw "Pre-restore backup already exists: $pre"};Copy-Item -LiteralPath $statePath -Destination $pre;$result.PreRestoreBackup=$pre}
Write-BytesAtomically $BackupPath $statePath
$sourceHash=(Get-FileHash -LiteralPath $BackupPath -Algorithm SHA256).Hash;$destHash=(Get-FileHash -LiteralPath $statePath -Algorithm SHA256).Hash;if($sourceHash -ne $destHash){throw 'Restore hash verification failed. The pre-restore backup is preserved.'}
$result.Restored=$true;return [PSCustomObject]$result
