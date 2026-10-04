# Release contract: only distributable source files are shipped, including dotfiles.
[CmdletBinding()]
param([string]$TestRoot)
$ErrorActionPreference = 'Stop'
$package = Split-Path -Parent $PSScriptRoot
if (-not $TestRoot) { $TestRoot = Join-Path $env:TEMP ('prodev-release-test-' + [guid]::NewGuid().ToString('N')) }
$TestRoot = [IO.Path]::GetFullPath($TestRoot)
$fixture = Join-Path $TestRoot 'source with spaces'
if (Test-Path -LiteralPath $fixture) { throw 'Use a fresh TestRoot; release tests do not overwrite a fixture.' }
New-Item -ItemType Directory -Force -Path $fixture | Out-Null
foreach ($name in @('.claude-plugin', 'plugins', 'scripts', 'tests', 'docs', '.github', 'README.md', 'README.tr.md', 'LICENSE', 'CHANGELOG.md', 'CONTRIBUTING.md', 'SECURITY.md', '.gitignore', '.gitattributes', '.editorconfig')) {
    $source = Join-Path $package $name
    if (Test-Path -LiteralPath $source) { Copy-Item -LiteralPath $source -Destination $fixture -Recurse }
}
$utf8 = New-Object Text.UTF8Encoding($false)
New-Item -ItemType Directory -Force -Path (Join-Path $fixture '.git') | Out-Null
[IO.File]::WriteAllText((Join-Path $fixture '.git\config'), 'PRIVATE_GIT_SENTINEL', $utf8)
[IO.File]::WriteAllText((Join-Path $fixture '.env'), 'PRIVATE_ENV_SENTINEL', $utf8)
[IO.File]::WriteAllText((Join-Path $fixture 'private-note.txt'), 'PRIVATE_NOTE_SENTINEL', $utf8)
function Assert($Condition, [string]$Message) {
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message"
}
$builder = Join-Path $fixture 'scripts\build-release.ps1'
& $builder
$dist = Join-Path $fixture 'dist'
$zipPath = Join-Path $dist 'claude-pro-dev-v0.1.0.zip'
Assert (Test-Path -LiteralPath $zipPath) 'default build produces a versioned ZIP in dist'
Assert (Test-Path -LiteralPath (Join-Path $dist 'install.ps1')) 'release includes a standalone installer asset'
Assert (Test-Path -LiteralPath (Join-Path $dist 'SHA256SUMS.txt')) 'release includes checksums for both assets'
Add-Type -AssemblyName System.IO.Compression
$stream = [IO.File]::OpenRead($zipPath)
$archive = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Read)
try {
    $names = @($archive.Entries | ForEach-Object { $_.FullName })
    Assert ($names -contains 'claude-pro-dev-v0.1.0/.claude-plugin/marketplace.json') 'marketplace dot-directory is included'
    Assert ($names -contains 'claude-pro-dev-v0.1.0/plugins/prodev/.claude-plugin/plugin.json') 'plugin dot-directory is included'
    Assert ($names -contains 'claude-pro-dev-v0.1.0/tests/install.Tests.ps1') 'source archive includes installation regression tests'
    Assert (@($names | Where-Object { $_ -match '/(?:\.git|dist)/|/\.env$|/private-note\.txt$' }).Count -eq 0) 'Git metadata, local secrets, unrelated root files and build artifacts are excluded'
    foreach ($entry in $archive.Entries) {
        $reader = New-Object IO.StreamReader($entry.Open())
        try { $content = $reader.ReadToEnd() } finally { $reader.Dispose() }
        Assert ($content -notmatch '^(PRIVATE_GIT_SENTINEL|PRIVATE_ENV_SENTINEL|PRIVATE_NOTE_SENTINEL)$') ('no private fixture content in ' + $entry.FullName)
    }
} finally { $archive.Dispose(); $stream.Dispose() }
$installer = [IO.File]::ReadAllText((Join-Path $dist 'install.ps1'))
$base64Match = [regex]::Match($installer, '\$EmbeddedPackageBase64 = ''([A-Za-z0-9+/=]+)''')
$digestMatch = [regex]::Match($installer, '\$EmbeddedPackageSha256 = ''([a-f0-9]{64})''')
Assert ($base64Match.Success -and $digestMatch.Success) 'installer has an embedded payload and digest'
$payloadBytes = [Convert]::FromBase64String($base64Match.Groups[1].Value)
$sha = [Security.Cryptography.SHA256]::Create()
try { $payloadDigest = [BitConverter]::ToString($sha.ComputeHash($payloadBytes)).Replace('-', '').ToLowerInvariant() } finally { $sha.Dispose() }
Assert ($payloadDigest -eq $digestMatch.Groups[1].Value) 'embedded payload passes its own checksum'
$memory = New-Object IO.MemoryStream(,$payloadBytes)
$payload = New-Object IO.Compression.ZipArchive($memory, [IO.Compression.ZipArchiveMode]::Read)
try {
    $payloadNames = @($payload.Entries | ForEach-Object { $_.FullName })
    Assert ($payloadNames -contains 'scripts/verify.ps1') 'standalone payload contains installation verification'
    Assert ($payloadNames -contains 'plugins/prodev/hooks/register.js') 'standalone payload contains the executable mod'
    Assert (@($payloadNames | Where-Object { $_ -match '(^|/)(\.git|dist)/|(^|/)\.env$|(^|/)install\.ps1$' }).Count -eq 0) 'payload excludes Git metadata, secrets and recursive installer embedding'
} finally { $payload.Dispose(); $memory.Dispose() }
foreach ($line in (Get-Content -LiteralPath (Join-Path $dist 'SHA256SUMS.txt'))) {
    Assert ($line -match '^([a-f0-9]{64})  (install\.ps1|claude-pro-dev-v0\.1\.0\.zip)$') 'checksum line describes an expected release asset'
    $expectedDigest = $Matches[1]
    $asset = Join-Path $dist $Matches[2]
    Assert ((Get-FileHash -LiteralPath $asset -Algorithm SHA256).Hash.ToLowerInvariant() -eq $expectedDigest) 'published checksum matches its asset'
}
$beforeZip = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash
$beforeInstaller = (Get-FileHash -LiteralPath (Join-Path $dist 'install.ps1') -Algorithm SHA256).Hash
[IO.File]::WriteAllText((Join-Path $fixture '.git\config'), 'DIFFERENT_PRIVATE_GIT_SENTINEL', $utf8)
& $builder
Assert ((Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash -eq $beforeZip) 'repeated builds are identical despite changed Git metadata'
Assert ((Get-FileHash -LiteralPath (Join-Path $dist 'install.ps1') -Algorithm SHA256).Hash -eq $beforeInstaller) 'standalone installer is reproducible'
$rejected = $false
try { & $builder -OutputDirectory $fixture } catch { $rejected = $true }
Assert $rejected 'writing release assets over the source root is refused'
Write-Host "Release fixture retained: $TestRoot"
