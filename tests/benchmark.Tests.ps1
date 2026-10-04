[CmdletBinding()]
param([string]$TestRoot)
$ErrorActionPreference = 'Stop'
$package = Split-Path -Parent $PSScriptRoot
if (-not $TestRoot) { $TestRoot = Join-Path $env:TEMP ('prodev-benchmark-tests-' + [guid]::NewGuid().ToString('N')) }
if (Test-Path -LiteralPath $TestRoot) { throw 'Use a fresh TestRoot.' }
Copy-Item -LiteralPath (Join-Path $package 'benchmarks\signed-total') -Destination $TestRoot -Recurse
$shellExe = (Get-Process -Id $PID).Path
& $shellExe -NoProfile -File (Join-Path $package 'benchmarks\acceptance.ps1') -Candidate $TestRoot | Out-Null
if ($LASTEXITCODE -ne 1) { throw 'Acceptance must reject the original bug.' }
Write-Host 'PASS: independent acceptance rejects the original bug'
$parser = Join-Path $TestRoot 'parser.ps1'
[IO.File]::WriteAllText($parser, [IO.File]::ReadAllText($parser).Replace(".TrimStart('-')", ''), (New-Object Text.UTF8Encoding($false)))
& $shellExe -NoProfile -File (Join-Path $package 'benchmarks\acceptance.ps1') -Candidate $TestRoot | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Acceptance must accept correctly signed values.' }
Write-Host 'PASS: independent acceptance accepts six correct cases'
