[CmdletBinding()]
param([string]$ClaudeConfigDir, [switch]$SkipTests)
$ErrorActionPreference = 'Stop'
$previousConfig = $env:CLAUDE_CONFIG_DIR
if (-not $ClaudeConfigDir) { $ClaudeConfigDir = if ($previousConfig) { $previousConfig } else { Join-Path $env:USERPROFILE '.claude' } }
try {
    $env:CLAUDE_CONFIG_DIR = [IO.Path]::GetFullPath($ClaudeConfigDir)
    $package = Join-Path $env:CLAUDE_CONFIG_DIR 'prodev\package'
    $claudeExecutable = (Get-Command claude -CommandType Application -ErrorAction Stop).Source
    function Run-Claude([string[]]$Arguments) {
        $output = @(& $claudeExecutable @Arguments 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "Verification command failed: $($output -join [Environment]::NewLine)" }
        return ($output -join [Environment]::NewLine)
    }
    $version = Run-Claude -Arguments @('--version')
    if ($version -notmatch '(\d+\.\d+\.\d+)' -or [version]$Matches[1] -lt [version]'2.1.287') { throw 'Claude Code 2.1.287+ required.' }
    $pluginPath = Join-Path $package 'plugins\prodev'
    Run-Claude -Arguments @('plugin', 'validate', $package, '--strict') | Out-Null
    Run-Claude -Arguments @('plugin', 'validate', $pluginPath, '--strict') | Out-Null
    # In Windows PowerShell 5.1 ConvertFrom-Json writes an array as ONE pipeline
    # item. Capture it first so Where-Object enumerates the individual plugins.
    $installed = Run-Claude -Arguments @('plugin', 'list', '--json') | ConvertFrom-Json
    $item = @($installed | Where-Object { $_.id -eq 'prodev@claude-pro-dev-local' -and $_.scope -eq 'user' })
    if ($item.Count -ne 1 -or $item[0].enabled -ne $true -or $item[0].version -ne '0.1.0') { throw 'Pro Dev 0.1.0 must be installed and enabled in user scope.' }
    $settings = Get-Content -LiteralPath (Join-Path $env:CLAUDE_CONFIG_DIR 'settings.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($settings.disableAllHooks -eq $true) { throw 'disableAllHooks prevents this mod from loading.' }
    if (-not $SkipTests) { Run-Claude -Arguments @('plugin', 'test', $pluginPath) | Out-Null }
    $testStatus = if ($SkipTests) { 'skipped' } else { 'passed' }
    Write-Host "Verified: $version; plugin enabled; manifests valid; tests $testStatus."
    Write-Host 'Interactive check: /plugin shows prodev active; /prodev shows usage. Live UI requires a logged-in, trusted session.'
} finally { $env:CLAUDE_CONFIG_DIR = $previousConfig }
