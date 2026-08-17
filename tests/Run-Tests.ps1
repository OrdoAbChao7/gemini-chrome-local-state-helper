$ErrorActionPreference='Stop'
function Get-Process { [CmdletBinding()] param([Parameter(Position=0)][string]$Name) if($Name -eq 'chrome'){ return @() }; return Microsoft.PowerShell.Management\Get-Process @PSBoundParameters }
$root=Split-Path -Parent $PSScriptRoot;$enable=Join-Path $root 'scripts\\Enable-GeminiChrome.ps1';$restore=Join-Path $root 'scripts\Restore-GeminiChrome.ps1';$fixture=Join-Path $PSScriptRoot 'fixtures.local-state.json';$temp=Join-Path ([IO.Path]::GetTempPath()) ('gemini-local-state-test-'+[guid]::NewGuid().ToString('N'));$userData=Join-Path $temp 'User Data';$backups=Join-Path $temp 'Backups';New-Item -ItemType Directory -Path $userData|Out-Null;$state=Join-Path $userData 'Local State';Copy-Item $fixture $state;$original=(Get-FileHash $state -Algorithm SHA256).Hash
try{
  $enabled=& $enable -UserDataDir $userData -BackupDirectory $backups -Region US -Confirm:$false
  if(-not $enabled.Verified){throw 'Enable script did not report verification.'};if(-not(Test-Path -LiteralPath $enabled.BackupPath)){throw 'Enable script did not create a backup.'}
  $json=Get-Content $state -Raw|ConvertFrom-Json;if($json.glic.launcher_enabled -ne $true){throw 'launcher_enabled was not set.'};if($json.variations_country -ne 'us'){throw 'variations_country was not set.'};if($json.profile.info_cache.Default.is_glic_eligible -ne $true){throw 'Default profile was not set.'};if($json.unrelated.must_remain -ne 'unchanged'){throw 'Unrelated key changed.'}
  $restored=& $restore -UserDataDir $userData -BackupDirectory $backups -BackupPath $enabled.BackupPath -Confirm:$false
  if(-not $restored.Restored){throw 'Restore script did not report success.'};$after=(Get-FileHash $state -Algorithm SHA256).Hash;if($after -ne $original){throw 'Restore hash differs from original fixture.'}
  Write-Output 'TEST_RESULT=PASS'
}finally{if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp -Recurse -Force}}
