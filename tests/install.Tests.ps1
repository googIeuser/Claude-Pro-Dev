# Requires no Pester. Run with Windows PowerShell 5.1 or PowerShell 7.
[CmdletBinding()]
param([string]$TestRoot)
$ErrorActionPreference = 'Stop'
$package = Split-Path -Parent $PSScriptRoot
if (-not $TestRoot) { $TestRoot = Join-Path $env:TEMP ('prodev-test-' + [guid]::NewGuid().ToString('N')) }
$TestRoot = [IO.Path]::GetFullPath($TestRoot)
$config = Join-Path $TestRoot 'config with spaces'
New-Item -ItemType Directory -Force -Path $config | Out-Null
function Assert($Condition, [string]$Message) { if (-not $Condition) { throw "FAIL: $Message" }; Write-Host "PASS: $Message" }
$installer = Join-Path $package 'install.ps1'
Assert (Test-Path -LiteralPath $installer) 'one-command installer exists'
$utf8 = New-Object Text.UTF8Encoding($false)
$settingsPath = Join-Path $config 'settings.json'
$original = '{"model":"sonnet","permissions":{"deny":["Bash(whoami)"]},"enabledPlugins":{"keep@demo":false}}'
[IO.File]::WriteAllText($settingsPath, $original, $utf8)
# Exercise a populated configuration, including an older prodev from another
# marketplace. Windows PowerShell 5.1 returns JSON arrays as one pipeline item.
$fixtureRoot = Join-Path $TestRoot 'legacy-marketplace'
foreach ($directory in @('.claude-plugin', 'plugins\prodev\.claude-plugin', 'plugins\companion\.claude-plugin')) {
    New-Item -ItemType Directory -Force -Path (Join-Path $fixtureRoot $directory) | Out-Null
}
[IO.File]::WriteAllText((Join-Path $fixtureRoot '.claude-plugin\marketplace.json'), '{"name":"prodev-fixture-legacy","owner":{"name":"Test fixture"},"metadata":{"description":"Regression fixture"},"plugins":[{"name":"prodev","source":"./plugins/prodev"},{"name":"companion","source":"./plugins/companion"}]}', $utf8)
[IO.File]::WriteAllText((Join-Path $fixtureRoot 'plugins\prodev\.claude-plugin\plugin.json'), '{"name":"prodev","version":"1.0.1","description":"Previously installed prodev fixture","author":{"name":"Test fixture"}}', $utf8)
[IO.File]::WriteAllText((Join-Path $fixtureRoot 'plugins\companion\.claude-plugin\plugin.json'), '{"name":"companion","version":"1.3.0","description":"Unrelated fixture","author":{"name":"Test fixture"}}', $utf8)
$beforeFixtureEnv = $env:CLAUDE_CONFIG_DIR
try {
    $env:CLAUDE_CONFIG_DIR = $config
    $fixtureClaude = (Get-Command claude -CommandType Application -ErrorAction Stop).Source
    foreach ($arguments in @(
        @('plugin', 'marketplace', 'add', $fixtureRoot, '--json'),
        @('plugin', 'install', 'prodev@prodev-fixture-legacy', '--scope', 'user', '--json'),
        @('plugin', 'install', 'companion@prodev-fixture-legacy', '--scope', 'user', '--json')
    )) {
        $output = @(& $fixtureClaude @arguments 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "Fixture setup failed: $($output -join [Environment]::NewLine)" }
    }
} finally { $env:CLAUDE_CONFIG_DIR = $beforeFixtureEnv }
& $installer -SourcePath $package -ClaudeConfigDir $config
Assert (Test-Path -LiteralPath (Join-Path $config 'prodev\package\plugins\prodev\hooks\register.js')) 'installed files survive moving original source'
$settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
Assert ($settings.model -eq 'sonnet') 'existing model is preserved'
Assert ($settings.permissions.deny[0] -eq 'Bash(whoami)') 'existing permission rules are preserved'
Assert ($settings.enabledPlugins.'keep@demo' -eq $false) 'unrelated plugin setting is preserved'
Assert ($settings.enabledPlugins.'prodev@claude-pro-dev-local' -eq $true) 'prodev is enabled through Claude CLI'
Assert ($settings.enabledPlugins.'prodev@prodev-fixture-legacy' -eq $false) 'older prodev is disabled to prevent a command-name collision'
Assert ($settings.enabledPlugins.'companion@prodev-fixture-legacy' -eq $true) 'unrelated installed plugin stays enabled'
& $installer -SourcePath $package -ClaudeConfigDir $config
& (Join-Path $package 'scripts\verify.ps1') -ClaudeConfigDir $config
Assert ($true) 'a second install and verification succeed'
$marketplaceDataPath = Join-Path $config 'plugins\known_marketplaces.json'
$catalog = Get-Content -LiteralPath $marketplaceDataPath -Raw | ConvertFrom-Json
Assert ($catalog.'claude-pro-dev-local'.source.path -eq (Join-Path $config 'prodev\package')) 'marketplace points to durable installed source'
$previousEnv = $env:CLAUDE_CONFIG_DIR
$embeddedConfig = Join-Path $TestRoot 'embedded-config'
& ([scriptblock]::Create([IO.File]::ReadAllText($installer))) -ClaudeConfigDir $embeddedConfig -UseEmbedded
Assert (Test-Path -LiteralPath (Join-Path $embeddedConfig 'prodev\package\plugins\prodev\hooks\register.js')) 'standalone pipeline script installs its embedded payload'
Assert ($env:CLAUDE_CONFIG_DIR -eq $previousEnv) 'installer restores the parent process environment'
# Force a failure AFTER the CLI has modified installation metadata.
$badSource = Join-Path $TestRoot 'rollback-source'
Copy-Item -LiteralPath $package -Destination $badSource -Recurse
[IO.File]::WriteAllText((Join-Path $badSource 'scripts\verify.ps1'), "throw 'injected verification failure'", $utf8)
$beforeRollbackEnv = $env:CLAUDE_CONFIG_DIR
try {
    $env:CLAUDE_CONFIG_DIR = $config
    $output = @(& $fixtureClaude plugin enable 'prodev@prodev-fixture-legacy' --scope user --json 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Rollback fixture setup failed: $($output -join [Environment]::NewLine)" }
} finally { $env:CLAUDE_CONFIG_DIR = $beforeRollbackEnv }
$beforeFailure = [IO.File]::ReadAllText($settingsPath)
$beforeMarketplace = [IO.File]::ReadAllText($marketplaceDataPath)
$failed = $false
try { & $installer -SourcePath $badSource -ClaudeConfigDir $config } catch { $failed = $true }
Assert $failed 'failed post-install verification is reported'
Assert ([IO.File]::ReadAllText($settingsPath) -eq $beforeFailure) 'settings are restored after a mid-install failure'
Assert ([IO.File]::ReadAllText($marketplaceDataPath) -eq $beforeMarketplace) 'marketplace metadata is restored after failure'
Assert ((Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json).enabledPlugins.'prodev@prodev-fixture-legacy' -eq $true) 'previous prodev enabled state is restored after failure'
Assert (([IO.File]::ReadAllText((Join-Path $config 'prodev\package\scripts\verify.ps1'))) -notmatch 'injected verification failure') 'previous installed package is restored'
$badConfig = Join-Path $TestRoot 'bad-config'
New-Item -ItemType Directory -Force -Path $badConfig | Out-Null
[IO.File]::WriteAllText((Join-Path $badConfig 'settings.json'), '{broken', $utf8)
$rejected = $false
try { & $installer -SourcePath $package -ClaudeConfigDir $badConfig } catch { $rejected = $true }
Assert $rejected 'invalid settings JSON stops installation'
Assert ((Get-Content -LiteralPath (Join-Path $badConfig 'settings.json') -Raw) -eq '{broken') 'invalid settings file is not overwritten'
Write-Host "Sandbox retained for inspection: $TestRoot"
