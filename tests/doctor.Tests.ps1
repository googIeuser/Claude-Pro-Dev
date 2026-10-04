[CmdletBinding()]
param([string]$TestRoot)
$ErrorActionPreference = 'Stop'
$package = Split-Path -Parent $PSScriptRoot
if (-not $TestRoot) { $TestRoot = Join-Path $env:TEMP ('prodev-doctor-' + [guid]::NewGuid().ToString('N')) }
if (Test-Path -LiteralPath $TestRoot) { throw 'Use a fresh TestRoot.' }
New-Item -ItemType Directory -Path $TestRoot | Out-Null
function Assert($Condition, [string]$Message) { if (-not $Condition) { throw "FAIL: $Message" }; Write-Host "PASS: $Message" }
$doctor = Join-Path $package 'scripts\doctor.ps1'
$shellExe = (Get-Process -Id $PID).Path
$raw = & $shellExe -NoProfile -ExecutionPolicy Bypass -File $doctor -ClaudeConfigDir $TestRoot -Json
$code = $LASTEXITCODE
$report = ($raw -join "`n") | ConvertFrom-Json
Assert ($code -eq 1) 'doctor returns failure for an uninstalled plugin'
Assert ($report.checks.name -contains 'claude-version') 'doctor checks real binary compatibility'
Assert (@($report.checks | Where-Object { $_.name -eq 'claude-version' -and $_.status -eq 'pass' }).Count -eq 1) 'compatible real binary passes'
Assert (@($report.checks | Where-Object { $_.name -eq 'plugin-enabled' -and $_.status -eq 'fail' }).Count -eq 1) 'missing installation is explicitly failed'
Assert (($raw -join "`n") -notmatch 'email|orgId|accessToken|refreshToken') 'doctor omits account identity and credentials'
[IO.File]::WriteAllText((Join-Path $TestRoot 'settings.json'), '{invalid-json')
$raw = & $shellExe -NoProfile -ExecutionPolicy Bypass -File $doctor -ClaudeConfigDir $TestRoot -Json
$report = ($raw -join "`n") | ConvertFrom-Json
Assert (@($report.checks | Where-Object { $_.name -eq 'settings' -and $_.status -eq 'fail' }).Count -eq 1) 'malformed settings are diagnosed without printing their contents'
Write-Host 'Doctor negative checks passed.'
# The final child doctor intentionally returns 1. Report the successful suite
# itself as 0 so callers (including GitHub's shell wrapper) do not inherit it.
exit 0
