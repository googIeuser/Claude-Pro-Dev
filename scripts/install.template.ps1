# Claude Pro Dev 0.2.0 - self-contained installer, Windows PowerShell 5.1+.
# Built from this template by scripts/build-release.ps1.
[CmdletBinding()]
param(
    [string]$SourcePath,
    [string]$ClaudeConfigDir,
    [switch]$UseEmbedded
)
$ErrorActionPreference = 'Stop'
$EmbeddedPackageBase64 = '__PRODEV_PAYLOAD__'
$EmbeddedPackageSha256 = '__PRODEV_SHA256__'
$previousConfig = $env:CLAUDE_CONFIG_DIR
if (-not $ClaudeConfigDir) {
    $ClaudeConfigDir = if ($previousConfig) { $previousConfig } else { Join-Path $env:USERPROFILE '.claude' }
}
$ClaudeConfigDir = [IO.Path]::GetFullPath($ClaudeConfigDir)
$ownedRoot = Join-Path $ClaudeConfigDir 'prodev'
$target = Join-Path $ownedRoot 'package'
$stamp = [guid]::NewGuid().ToString('N')
$stage = Join-Path $ownedRoot ('stage-' + $stamp)
$backup = Join-Path $ownedRoot ('backups\' + $stamp)
$snapshots = @()
$movedPreviousPackage = $false
$placedNewPackage = $false
$snapshotReady = $false
$disabledPlugins = @()

function Assert-OwnedPath([string]$Path) {
    $absolute = [IO.Path]::GetFullPath($Path)
    $prefix = [IO.Path]::GetFullPath($ownedRoot).TrimEnd('\') + '\'
    if (-not $absolute.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'Refusing a path outside the Pro Dev installation folder.' }
    $ancestor = $absolute
    while ($ancestor -and $ancestor.Length -ge $ownedRoot.Length) {
        if ((Test-Path -LiteralPath $ancestor) -and ((Get-Item -LiteralPath $ancestor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw 'Refusing to traverse a linked Pro Dev folder.'
        }
        $ancestor = [IO.Path]::GetDirectoryName($ancestor)
    }
}
function Invoke-Claude([string[]]$Arguments) {
    $output = @(& $claudeExecutable @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Claude command failed ($LASTEXITCODE): $($output -join [Environment]::NewLine)" }
    return ($output -join [Environment]::NewLine)
}

try {
    $claudeExecutable = (Get-Command claude -CommandType Application -ErrorAction Stop).Source
    $versionOutput = Invoke-Claude -Arguments @('--version')
    if ($versionOutput -notmatch '(\d+\.\d+\.\d+)') { throw 'Could not determine the Claude Code version.' }
    if ([version]$Matches[1] -lt [version]'2.1.287') { throw 'Claude Code 2.1.287 or later is required. Update Claude Code and retry.' }
    # Refuse malformed configuration before running any mutating Claude command.
    foreach ($relative in @('settings.json', '.claude.json', 'plugins\known_marketplaces.json', 'plugins\installed_plugins.json')) {
        $file = Join-Path $ClaudeConfigDir $relative
        if (Test-Path -LiteralPath $file) {
            $parsed = Get-Content -LiteralPath $file -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($null -eq $parsed -or $parsed -is [array] -or $parsed -is [string] -or $parsed -is [ValueType]) { throw "Configuration must be a JSON object: $relative" }
            if ($relative -eq 'settings.json' -and $parsed.disableAllHooks -eq $true) { throw 'disableAllHooks is enabled. Enable hooks before installing a mod.' }
        }
    }
    if ((Test-Path -LiteralPath $ownedRoot) -and ((Get-Item -LiteralPath $ownedRoot -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Pro Dev install root must not be a linked folder.' }
    Assert-OwnedPath $stage
    Assert-OwnedPath $target
    Assert-OwnedPath $backup
    New-Item -ItemType Directory -Force -Path $stage, $backup | Out-Null
    $env:CLAUDE_CONFIG_DIR = $ClaudeConfigDir
    foreach ($relative in @('settings.json', '.claude.json', 'plugins\known_marketplaces.json', 'plugins\installed_plugins.json')) {
        $file = Join-Path $ClaudeConfigDir $relative
        $saved = Join-Path $backup $relative
        $exists = Test-Path -LiteralPath $file
        if ($exists) {
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $saved) | Out-Null
            Copy-Item -LiteralPath $file -Destination $saved
        }
        $snapshots += [pscustomobject]@{ File = $file; Saved = $saved; Existed = $exists }
    }
    $snapshotReady = $true
    if (-not $UseEmbedded -and -not $SourcePath -and $PSScriptRoot -and (Test-Path -LiteralPath (Join-Path $PSScriptRoot '.claude-plugin\marketplace.json'))) { $SourcePath = $PSScriptRoot }
    if ($SourcePath -and -not $UseEmbedded) {
        $SourcePath = (Resolve-Path -LiteralPath $SourcePath).ProviderPath
        if (-not (Test-Path -LiteralPath (Join-Path $SourcePath '.claude-plugin\marketplace.json'))) { throw 'SourcePath is not a Pro Dev package.' }
        foreach ($name in @('.claude-plugin', 'plugins', 'scripts', 'docs', 'benchmarks', 'README.md', 'README.tr.md', 'LICENSE')) {
            $from = Join-Path $SourcePath $name
            if (Test-Path -LiteralPath $from) { Copy-Item -LiteralPath $from -Destination $stage -Recurse }
        }
    } else {
        $bytes = [Convert]::FromBase64String($EmbeddedPackageBase64)
        $sha = [Security.Cryptography.SHA256]::Create()
        try { $digest = [BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-', '').ToLowerInvariant() } finally { $sha.Dispose() }
        if ($digest -ne $EmbeddedPackageSha256) { throw 'Embedded payload checksum mismatch.' }
        Add-Type -AssemblyName System.IO.Compression
        $stream = New-Object IO.MemoryStream(,$bytes)
        $zip = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Read)
        try {
            foreach ($entry in $zip.Entries) {
                $destination = [IO.Path]::GetFullPath((Join-Path $stage $entry.FullName.Replace('/', '\')))
                if (-not $destination.StartsWith($stage.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe payload archive path.' }
                if (-not $entry.Name) { New-Item -ItemType Directory -Force -Path $destination | Out-Null; continue }
                New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
                $inputStream = $entry.Open()
                $outputStream = [IO.File]::Open($destination, [IO.FileMode]::CreateNew)
                try { $inputStream.CopyTo($outputStream) } finally { $outputStream.Dispose(); $inputStream.Dispose() }
            }
        } finally { $zip.Dispose(); $stream.Dispose() }
    }
    $manifest = Get-Content -LiteralPath (Join-Path $stage '.claude-plugin\marketplace.json') -Raw | ConvertFrom-Json
    if ($manifest.name -ne 'claude-pro-dev-local') { throw 'Unexpected marketplace name.' }
    $plugin = Get-Content -LiteralPath (Join-Path $stage 'plugins\prodev\.claude-plugin\plugin.json') -Raw | ConvertFrom-Json
    if ($plugin.name -ne 'prodev' -or $plugin.version -ne '0.2.0') { throw 'Unexpected plugin identity or version.' }
    Invoke-Claude -Arguments @('plugin', 'validate', $stage, '--strict') | Out-Null
    Invoke-Claude -Arguments @('plugin', 'validate', (Join-Path $stage 'plugins\prodev'), '--strict') | Out-Null
    # Capture JSON arrays directly: @(... | ConvertFrom-Json) nests them in PS 5.1.
    $marketplaces = Invoke-Claude -Arguments @('plugin', 'marketplace', 'list', '--json') | ConvertFrom-Json
    $existing = @($marketplaces | Where-Object { $_.name -eq 'claude-pro-dev-local' })
    if ($existing.Count -gt 0 -and [IO.Path]::GetFullPath($existing[0].path) -ne $target) { throw 'A different claude-pro-dev-local marketplace exists. Resolve that name conflict first.' }
    $installedPlugins = Invoke-Claude -Arguments @('plugin', 'list', '--json') | ConvertFrom-Json
    $conflictingPlugins = @($installedPlugins | Where-Object {
        $_.scope -eq 'user' -and $_.enabled -eq $true -and
        $_.id -like 'prodev@*' -and $_.id -ne 'prodev@claude-pro-dev-local'
    })
    if (Test-Path -LiteralPath $target) {
        $oldPackage = Join-Path $backup 'previous-package'
        Assert-OwnedPath $oldPackage
        Move-Item -LiteralPath $target -Destination $oldPackage
        $movedPreviousPackage = $true
    }
    Assert-OwnedPath $stage
    Assert-OwnedPath $target
    Move-Item -LiteralPath $stage -Destination $target
    $placedNewPackage = $true
    Invoke-Claude -Arguments @('plugin', 'marketplace', 'add', $target, '--json') | Out-Null
    Invoke-Claude -Arguments @('plugin', 'install', 'prodev@claude-pro-dev-local', '--scope', 'user', '--json') | Out-Null
    foreach ($conflictingPlugin in $conflictingPlugins) {
        # Same-name mods register the same /prodev command. Preserve their files
        # and reversible settings; the snapshots restore enabled state on failure.
        Invoke-Claude -Arguments @('plugin', 'disable', $conflictingPlugin.id, '--scope', 'user', '--json') | Out-Null
        $disabledPlugins += $conflictingPlugin.id
    }
    $installedAfter = Invoke-Claude -Arguments @('plugin', 'list', '--json') | ConvertFrom-Json
    $targetPlugin = @($installedAfter | Where-Object { $_.id -eq 'prodev@claude-pro-dev-local' -and $_.scope -eq 'user' })
    if ($targetPlugin.Count -ne 1) { throw 'Claude did not register prodev@claude-pro-dev-local in user scope.' }
    # install is idempotent and can retain the old cache/version for an existing
    # ID. Explicitly update that ID when upgrading, before verifying its version.
    if ($targetPlugin[0].version -ne $plugin.version) {
        Invoke-Claude -Arguments @('plugin', 'update', 'prodev@claude-pro-dev-local', '--scope', 'user', '--json') | Out-Null
        $installedAfter = Invoke-Claude -Arguments @('plugin', 'list', '--json') | ConvertFrom-Json
        $targetPlugin = @($installedAfter | Where-Object { $_.id -eq 'prodev@claude-pro-dev-local' -and $_.scope -eq 'user' })
        if ($targetPlugin.Count -ne 1) { throw 'Claude did not retain the expected installation after updating.' }
    }
    # enable returns an error when the plugin is already enabled.
    if ($targetPlugin[0].enabled -ne $true) {
        Invoke-Claude -Arguments @('plugin', 'enable', 'prodev@claude-pro-dev-local', '--scope', 'user', '--json') | Out-Null
    }
    & (Join-Path $target 'scripts\verify.ps1') -ClaudeConfigDir $ClaudeConfigDir
    Write-Host "Claude Pro Dev 0.2.0 installed. Package: $target"
    Write-Host "Backups: $backup"
    foreach ($disabledPlugin in $disabledPlugins) { Write-Host "Disabled overlapping plugin (files retained): $disabledPlugin" }
    Write-Host 'Start Claude Code, or run /reload-plugins. Check /plugin, /prodev-doctor and /prodev.'
} catch {
    $failure = $_
    if ($snapshotReady) {
        foreach ($snapshot in $snapshots) {
            if ($snapshot.Existed) { Copy-Item -LiteralPath $snapshot.Saved -Destination $snapshot.File -Force }
            elseif (Test-Path -LiteralPath $snapshot.File) { Remove-Item -LiteralPath $snapshot.File -Force }
        }
        if ($placedNewPackage -and (Test-Path -LiteralPath $target)) {
            $failedPackage = Join-Path $backup 'failed-package'
            Assert-OwnedPath $target
            Assert-OwnedPath $failedPackage
            Move-Item -LiteralPath $target -Destination $failedPackage
        }
        if ($movedPreviousPackage) {
            $oldPackage = Join-Path $backup 'previous-package'
            Assert-OwnedPath $oldPackage
            Assert-OwnedPath $target
            Move-Item -LiteralPath $oldPackage -Destination $target
        }
    }
    throw $failure
} finally { $env:CLAUDE_CONFIG_DIR = $previousConfig }
