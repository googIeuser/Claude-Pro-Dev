# Live native CLI/Mods smoke test. Commands must return without a model turn.
[CmdletBinding()]
param([string]$OutputDirectory)
$ErrorActionPreference = 'Stop'
$package = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'cli-session.ps1')
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $env:TEMP ('prodev-live-smoke-' + [guid]::NewGuid().ToString('N')) }
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
if (Test-Path -LiteralPath $OutputDirectory) { throw 'Use a fresh output folder.' }
New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
$utf8 = New-Object Text.UTF8Encoding($false)
$pluginCopy = Join-Path $OutputDirectory 'plugin'
Copy-Item -LiteralPath (Join-Path $package 'plugins\prodev') -Destination $pluginCopy -Recurse
$installed = (& (Get-Command claude -CommandType Application).Source plugin list --json) | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'Plugin enumeration failed.' }
$disabled = @{}; foreach ($item in $installed) { $disabled[$item.id] = $false }
$settingsFile = Join-Path $OutputDirectory 'isolation.settings.json'
[IO.File]::WriteAllText($settingsFile, (@{ enabledPlugins = $disabled } | ConvertTo-Json -Depth 8), $utf8)
$fixture = Join-Path $OutputDirectory 'fixture'
New-Item -ItemType Directory -Path $fixture | Out-Null
[IO.File]::WriteAllText((Join-Path $fixture 'pass.ps1'), "Write-Output 'API_KEY=synthetic-private-value'`nexit 0`n", $utf8)
[IO.File]::WriteAllText((Join-Path $fixture 'fail.ps1'), "Write-Output 'ERROR: intentional fixture failure'`nexit 7`n", $utf8)
$profile = @{ version = 1; checks = @(@{ name = 'unit'; argv = @('powershell.exe','-NoProfile','-File','./pass.ps1') }, @{ name = 'negative'; argv = @('powershell.exe','-NoProfile','-File','./fail.ps1') }) }
[IO.File]::WriteAllText((Join-Path $fixture '.prodev.json'), ($profile | ConvertTo-Json -Depth 8), $utf8)
$prompts = @('/prodev-doctor','/prodev-queue add Inspect parser','/prodev-queue list','/prodev-queue draft 1','/prodev-next','/prodev-flow mermaid','/prodev-filter off','/prodev-filter on','/prodev-guard off','/prodev-guard on','/prodev-checks profile','/prodev-checks run unit','/prodev-checks run negative','/prodev-checks','/prodev-report','/prodev')
$arguments = @('--print','--input-format','stream-json','--output-format','stream-json','--verbose','--setting-sources','project','--settings',$settingsFile,'--strict-mcp-config','--plugin-dir',$pluginCopy,'--prompt-suggestions','off')
$run = Invoke-ClaudeSession -WorkingDirectory $fixture -Arguments $arguments -Prompts $prompts -TimeoutSeconds 60
$events = @($run.stdout -split '\r?\n' | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
$results = @($events | Where-Object { $_.type -eq 'result' })
if ($run.exitCode -ne 0 -or $run.timedOut -or $results.Count -ne $prompts.Count) { throw 'Live CLI smoke did not return every helper result.' }
if (@($results | Where-Object { $_.num_turns -ne 0 -or $_.duration_api_ms -ne 0 }).Count) { throw 'A local helper unexpectedly started a model request.' }
$texts = @($results | ForEach-Object { $_.result })
function Assert($Condition, [string]$Message) { if (-not $Condition) { throw "FAIL: $Message" }; Write-Host "PASS: $Message" }
Assert ($texts[0] -match 'helpers registered: 9' -and $texts[0] -notmatch 'registration failed') 'all nine helpers register in the real host'
Assert ($texts[2] -match '#1 Inspect parser') 'queue persists within one live CLI process'
Assert ($texts[3] -match 'No editable prompt') 'headless draft honestly reports no editable composer'
Assert ($texts[5] -match 'flowchart TD') 'Mermaid export works locally'
Assert ($texts[11] -match 'unit: PASS.*exit 0' -and $texts[11] -notmatch 'synthetic-private-value') 'a real Windows process returns exit-zero receipt and redacted output'
Assert ($texts[12] -match 'negative: FAIL.*exit 7') 'a real failing process produces a failure receipt'
Assert ($texts[13] -match 'stale') 'the earlier receipt becomes stale after another program runs'
$report = ($texts[14] -replace '^prodev: ', '') | ConvertFrom-Json
Assert ($report.receipts.Count -eq 2 -and $report.receipts[1].exitCode -eq 7) 'live session report carries actual receipts'
$summary = [ordered]@{ claudeVersion = (& (Get-Command claude -CommandType Application).Source --version); helperResults = $results.Count; modelTurns = 0; apiDurationMs = 0; checks = @(@{ name = 'unit'; status = 'pass'; exitCode = 0 }, @{ name = 'negative'; status = 'fail'; exitCode = 7 }); queue = 'add/list; headless draft reports unavailable'; commandConflicts = 0 }
[IO.File]::WriteAllText((Join-Path $OutputDirectory 'live-smoke.json'), ($summary | ConvertTo-Json -Depth 8), $utf8)
Write-Host 'Live CLI smoke passed; no model request. This does not replace terminal/Desktop screen testing.'
