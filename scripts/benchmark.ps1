# A two-arm pilot. Only -RunLive starts model requests on your signed-in account.
[CmdletBinding()]
param([switch]$RunLive, [ValidateRange(1,3)][int]$Repeats = 1, [string]$Model = 'sonnet', [ValidateSet('low','medium','high')][string]$Effort = 'low', [string]$OutputDirectory, [ValidateRange(30,600)][int]$TimeoutSeconds = 180)
$ErrorActionPreference = 'Stop'
$package = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'cli-session.ps1')
if (-not $RunLive) { Write-Host 'This pilot uses a signed-number bug, independent acceptance and identical A/B metrics. To run 2 model sessions: .\scripts\benchmark.ps1 -RunLive -Repeats 1 -OutputDirectory <fresh folder>. It uses your Claude plan; no quota savings are assumed.'; return }
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $env:TEMP ('prodev-benchmark-' + [guid]::NewGuid().ToString('N')) }
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
if (Test-Path -LiteralPath $OutputDirectory) { throw 'Use a fresh output folder. Benchmark runs do not overwrite existing results.' }
New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
$utf8 = New-Object Text.UTF8Encoding($false)
$pluginCopy = Join-Path $OutputDirectory 'plugin'
Copy-Item -LiteralPath (Join-Path $package 'plugins\prodev') -Destination $pluginCopy -Recurse
$installed = (& (Get-Command claude -CommandType Application).Source plugin list --json) | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'Could not enumerate plugins for per-process isolation.' }
$disabled = @{}
foreach ($item in $installed) { $disabled[$item.id] = $false }
$settingsFile = Join-Path $OutputDirectory 'isolation.settings.json'
[IO.File]::WriteAllText($settingsFile, (@{ enabledPlugins = $disabled; promptSuggestionEnabled = $false } | ConvertTo-Json -Depth 8), $utf8)
$shellExe = (Get-Command powershell.exe -CommandType Application).Source
$prompt = 'Fix parser.ps1 so Get-SignedTotal correctly sums signed integers, including whitespace and empty fields. Make the smallest correct change. Run powershell.exe -NoProfile -File ./check.ps1 to verify it. Do not change check.ps1. Work only in this fixture. Finish briefly.'
$base = @('--print','--input-format','stream-json','--output-format','stream-json','--verbose','--setting-sources','project','--settings',$settingsFile,'--strict-mcp-config','--model',$Model,'--effort',$Effort,'--prompt-suggestions','off','--permission-mode','acceptEdits','--tools','Read,Grep,Glob,Edit,Write,Bash','--allowedTools','Bash(powershell.exe -NoProfile -File ./check.ps1)','--max-budget-usd','1')
$rows = @()
for ($repeat = 1; $repeat -le $Repeats; $repeat++) {
    $order = if ($repeat % 2) { @('A','B') } else { @('B','A') }
    foreach ($arm in $order) {
        Write-Host "Starting repeat $repeat arm $arm (A: no plugins; B: Pro Dev)."
        $candidate = Join-Path $OutputDirectory ("run-$repeat-$arm")
        Copy-Item -LiteralPath (Join-Path $package 'benchmarks\signed-total') -Destination $candidate -Recurse
        & $shellExe -NoProfile -File (Join-Path $package 'benchmarks\acceptance.ps1') -Candidate $candidate | Out-Null
        if ($LASTEXITCODE -ne 1) { throw 'Fixture did not reproduce the bug before this arm.' }
        $argsForArm = @($base)
        if ($arm -eq 'B') { $argsForArm += @('--plugin-dir', $pluginCopy) }
        $preflight = Invoke-ClaudeSession -WorkingDirectory $candidate -Arguments $argsForArm -Prompts @('/help') -TimeoutSeconds 30
        $preflightEvents = @($preflight.stdout -split '\r?\n' | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
        $initialization = $preflightEvents | Where-Object { $_.type -eq 'system' -and $_.subtype -eq 'init' } | Select-Object -Last 1
        $preflightMetrics = Get-ClaudeMetrics -JsonLines $preflight.stdout
        $custom = @($initialization.plugins | Where-Object { $_.name -notmatch '^cc-plugin-(agents-md|telemetry|plugin-authoring)$' })
        $expectedVersion = (Get-Content -LiteralPath (Join-Path $pluginCopy '.claude-plugin\plugin.json') -Raw | ConvertFrom-Json).version
        $isolation = if ($arm -eq 'A') { $custom.Count -eq 0 } else { $custom.Count -eq 1 -and $custom[0].name -eq 'prodev' -and $custom[0].version -eq $expectedVersion }
        if (-not $initialization -or -not $isolation -or $preflight.exitCode -ne 0 -or $preflightMetrics.turns -ne 0) { throw 'Plugin isolation preflight failed. No task request was started for this arm.' }
        $session = Invoke-ClaudeSession -WorkingDirectory $candidate -Arguments $argsForArm -Prompts @($prompt) -TimeoutSeconds $TimeoutSeconds
        $metrics = Get-ClaudeMetrics -JsonLines $session.stdout
        & $shellExe -NoProfile -File (Join-Path $package 'benchmarks\acceptance.ps1') -Candidate $candidate | Out-Null
        $acceptance = $LASTEXITCODE -eq 0
        $init = @($session.stdout -split '\r?\n' | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json } | Where-Object { $_.type -eq 'system' -and $_.subtype -eq 'init' })
        $loaded = @($init | Select-Object -Last 1 | ForEach-Object { $_.plugins } | Where-Object { $_.name -notmatch '^cc-plugin-(agents-md|telemetry|plugin-authoring)$' })
        $isolation = if ($arm -eq 'A') { $loaded.Count -eq 0 } else { $loaded.Count -eq 1 -and $loaded[0].name -eq 'prodev' -and $loaded[0].version -eq $expectedVersion }
        $row = [ordered]@{ task = 'signed-total'; repeat = $repeat; arm = $arm; requestedModel = $Model; effort = $Effort; claudeVersion = (& (Get-Command claude -CommandType Application).Source --version); correctnessPass = $acceptance; isolationPass = $isolation; timedOut = $session.timedOut; exitCode = $session.exitCode; wallMs = $session.wallMs }
        foreach ($property in $metrics.PSObject.Properties) { $row[$property.Name] = $property.Value }
        $rows += [pscustomobject]$row
        # Deliberately retain summaries and changed fixtures, never raw streams,
        # prompts, tool bodies, session IDs, account identity or stderr.
        [IO.File]::WriteAllText((Join-Path $OutputDirectory 'results.json'), ($rows | ConvertTo-Json -Depth 8), $utf8)
        $rows | Export-Csv -LiteralPath (Join-Path $OutputDirectory 'results.csv') -NoTypeInformation -Encoding UTF8
        Write-Host ("Finished ${arm}: acceptance=$acceptance; isolation=$isolation; tool requests=" + $metrics.toolRequests + '; output tokens=' + $metrics.outputTokens)
    }
}
Write-Host 'Pilot finished. Inspect failures and token categories separately. One task/pair does not establish subscription savings or a general efficiency improvement.'
