# Read-only installation diagnostics. Does not start a model or modify settings.
[CmdletBinding()]
param([string]$ClaudeConfigDir, [switch]$Json)
$ErrorActionPreference = 'Stop'
$previousConfig = $env:CLAUDE_CONFIG_DIR
if (-not $ClaudeConfigDir) { $ClaudeConfigDir = if ($previousConfig) { $previousConfig } else { Join-Path $env:USERPROFILE '.claude' } }
$checks = New-Object Collections.Generic.List[object]
function Record([string]$Name, [string]$Status, [string]$Detail) { $checks.Add([pscustomobject]@{ name = $Name; status = $Status; detail = $Detail }) }
try {
    $env:CLAUDE_CONFIG_DIR = [IO.Path]::GetFullPath($ClaudeConfigDir)
    $package = Split-Path -Parent $PSScriptRoot
    $binary = (Get-Command claude -CommandType Application -ErrorAction SilentlyContinue).Source
    function Run-Claude([string[]]$Arguments) {
        if (-not $binary) { throw 'Claude executable unavailable.' }
        $output = @(& $binary @Arguments 2>&1)
        if ($LASTEXITCODE -ne 0) { throw 'Claude command did not complete.' }
        return ($output -join [Environment]::NewLine)
    }
    try {
        $version = Run-Claude -Arguments @('--version')
        if ($version -notmatch '(\d+\.\d+\.\d+)' -or [version]$Matches[1] -lt [version]'2.1.287') { throw 'Incompatible binary.' }
        Record 'claude-version' 'pass' ("Claude Code " + $Matches[1])
    } catch { Record 'claude-version' 'fail' 'Install Claude Code 2.1.287+ and make claude available in PATH.' }
    $expected = $null
    try {
        $manifest = Get-Content -LiteralPath (Join-Path $package 'plugins\prodev\.claude-plugin\plugin.json') -Raw -Encoding UTF8 | ConvertFrom-Json
        $expected = $manifest.version
        Run-Claude -Arguments @('plugin', 'validate', $package, '--strict') | Out-Null
        Run-Claude -Arguments @('plugin', 'validate', (Join-Path $package 'plugins\prodev'), '--strict') | Out-Null
        Record 'manifests' 'pass' ("Pro Dev " + $expected + '; static Mods validation passed.')
    } catch { Record 'manifests' 'fail' 'Package manifests or hooks did not validate. Reinstall the package.' }
    try {
        $installed = Run-Claude -Arguments @('plugin', 'list', '--json') | ConvertFrom-Json
        $item = @($installed | Where-Object { $_.id -eq 'prodev@claude-pro-dev-local' -and $_.scope -eq 'user' })
        if ($item.Count -ne 1 -or $item[0].enabled -ne $true -or $item[0].version -ne $expected) { throw 'Missing, disabled or mismatched plugin.' }
        Record 'plugin-enabled' 'pass' 'Expected version enabled in user scope.'
        $other = @($installed | Where-Object { $_.id -like 'prodev@*' -and $_.id -ne 'prodev@claude-pro-dev-local' -and $_.enabled -eq $true })
        if ($other.Count) { Record 'conflicts' 'warn' 'Another enabled prodev may have overlapping command names; inspect /plugin.' }
        else { Record 'conflicts' 'pass' 'No other enabled prodev found. Live doctor checks actual helper registration.' }
    } catch { Record 'plugin-enabled' 'fail' 'Expected user-scope Pro Dev is missing, disabled or has a different version. Run install.ps1 again.' }
    $settingsPath = Join-Path $env:CLAUDE_CONFIG_DIR 'settings.json'
    try {
        if (Test-Path -LiteralPath $settingsPath) {
            $settings = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($settings.disableAllHooks -eq $true) { throw 'Hooks disabled.' }
            Record 'settings' 'pass' 'User settings parse; disableAllHooks is not enabled. Project/managed overrides require a live session check.'
        } else { Record 'settings' 'warn' 'No user settings file exists yet.' }
    } catch { Record 'settings' 'fail' 'User settings are malformed or disableAllHooks is enabled. Inspect them locally; their contents are not printed.' }
    try {
        $auth = Run-Claude -Arguments @('auth', 'status') | ConvertFrom-Json
        if ($auth.loggedIn -eq $true) { Record 'login' 'pass' 'Claude reports signed in; no request was sent.' }
        else { Record 'login' 'warn' 'Sign in through Claude for interactive/model tests. Offline native tests still work.' }
    } catch { Record 'login' 'warn' 'Login status unavailable. No model request was sent.' }
} finally { $env:CLAUDE_CONFIG_DIR = $previousConfig }
$report = [pscustomobject]@{ schemaVersion = 1; ok = @($checks | Where-Object { $_.status -eq 'fail' }).Count -eq 0; checks = @($checks.ToArray()) }
if ($Json) { $report | ConvertTo-Json -Depth 6 }
else { foreach ($check in $checks) { Write-Host ($check.status.ToUpper() + ': ' + $check.name + ' - ' + $check.detail) }; Write-Host 'Next: new Claude session, /prodev-doctor, /prodev-checks. This is not a quota, safety or task-correctness certificate.' }
if (-not $report.ok) { exit 1 }
exit 0
