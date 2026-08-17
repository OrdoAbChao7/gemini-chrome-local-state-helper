[CmdletBinding()]
param([string]$UserDataDir = (Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data'))
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$path=Join-Path $UserDataDir 'Local State';if(-not(Test-Path -LiteralPath $path -PathType Leaf)){throw "Local State was not found: $path"}
try{$state=Get-Content -LiteralPath $path -Raw -Encoding UTF8|ConvertFrom-Json}catch{throw "Local State is not valid JSON: $($_.Exception.Message)"}
$profiles=@();if($null -ne $state.profile -and $null -ne $state.profile.info_cache){foreach($p in $state.profile.info_cache.PSObject.Properties){if($null -ne $p.Value.PSObject.Properties['is_glic_eligible']){$profiles+=[PSCustomObject]@{Profile=$p.Name;GlicEligible=[bool]$p.Value.is_glic_eligible}}}}
[PSCustomObject]@{StatePath=$path;ChromeRunning=(@(Get-Process chrome -ErrorAction SilentlyContinue).Count -gt 0);GlicObjectExists=($null -ne $state.PSObject.Properties['glic']);LauncherEnabled=if($null -ne $state.PSObject.Properties['glic'] -and $null -ne $state.glic.PSObject.Properties['launcher_enabled']){[bool]$state.glic.launcher_enabled}else{$null};VariationsCountry=if($null -ne $state.PSObject.Properties['variations_country']){$state.variations_country}else{$null};ConsistencyCountry=if($null -ne $state.PSObject.Properties['variations_safe_seed_session_consistency_country']){$state.variations_safe_seed_session_consistency_country}else{$null};PermanentCountry=if($null -ne $state.PSObject.Properties['permanent_country']){$state.permanent_country}else{$null};Profiles=$profiles}
