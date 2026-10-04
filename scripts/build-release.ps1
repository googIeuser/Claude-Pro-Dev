# No npm, Node, Python, bundler or network required.
[CmdletBinding()]
param([string]$OutputDirectory)
$ErrorActionPreference = 'Stop'
$package = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$defaultDist = Join-Path $package 'dist'
if (-not $OutputDirectory) { $OutputDirectory = $defaultDist }
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory).TrimEnd('\')
$insideSource = $OutputDirectory.StartsWith($package.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)
if ($OutputDirectory -eq $package -or ($insideSource -and $OutputDirectory -ne $defaultDist)) { throw 'Use the package dist folder or an output directory outside the source tree.' }
$pluginManifest = Get-Content -LiteralPath (Join-Path $package 'plugins\prodev\.claude-plugin\plugin.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$version = $pluginManifest.version
if ($pluginManifest.name -ne 'prodev' -or $version -notmatch '^\d+\.\d+\.\d+$') { throw 'A prodev manifest with a numeric semantic version is required.' }
$releaseName = 'claude-pro-dev-v' + $version
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
Add-Type -AssemblyName System.IO.Compression
$utf8 = New-Object Text.UTF8Encoding($false)
function Get-ReleaseFiles([string[]]$Names) {
    foreach ($name in $Names) {
        $path = Join-Path $package $name
        if (-not (Test-Path -LiteralPath $path)) { continue }
        if ((Get-Item -LiteralPath $path -Force).PSIsContainer) {
            Get-ChildItem -LiteralPath $path -Recurse -File -Force
        } else { Get-Item -LiteralPath $path -Force }
    }
}
$buffer = New-Object IO.MemoryStream
$archive = New-Object IO.Compression.ZipArchive($buffer, [IO.Compression.ZipArchiveMode]::Create, $true)
try {
    $files = @(Get-ReleaseFiles -Names @('.claude-plugin', 'plugins', 'docs', 'scripts\verify.ps1', 'README.md', 'README.tr.md', 'LICENSE'))
    foreach ($file in ($files | Sort-Object FullName)) {
        $relative = $file.FullName.Substring($package.Length + 1).Replace('\', '/')
        $entry = $archive.CreateEntry($relative, [IO.Compression.CompressionLevel]::Optimal)
        $entry.LastWriteTime = [DateTimeOffset]'2026-10-04T00:00:00Z'
        $writer = $entry.Open()
        try { $data = [IO.File]::ReadAllBytes($file.FullName); $writer.Write($data, 0, $data.Length) } finally { $writer.Dispose() }
    }
} finally { $archive.Dispose() }
$payload = $buffer.ToArray()
$buffer.Dispose()
$sha = [Security.Cryptography.SHA256]::Create()
try { $digest = [BitConverter]::ToString($sha.ComputeHash($payload)).Replace('-', '').ToLowerInvariant() } finally { $sha.Dispose() }
$template = [IO.File]::ReadAllText((Join-Path $package 'scripts\install.template.ps1'))
$installer = $template.Replace('__PRODEV_PAYLOAD__', [Convert]::ToBase64String($payload)).Replace('__PRODEV_SHA256__', $digest)
[IO.File]::WriteAllText((Join-Path $package 'install.ps1'), $installer, $utf8)
[IO.File]::WriteAllText((Join-Path $OutputDirectory 'install.ps1'), $installer, $utf8)
# Only explicit source paths are distributed. Never walk the repository root:
# .git, dist, local credentials and unrelated root files must stay outside ZIPs.
$sourceFiles = @(Get-ReleaseFiles -Names @('.claude-plugin', 'plugins', 'scripts', 'tests', 'docs', '.github', 'README.md', 'README.tr.md', 'LICENSE', 'CHANGELOG.md', 'CONTRIBUTING.md', 'SECURITY.md', '.gitignore', '.gitattributes', '.editorconfig', 'install.ps1'))
$zipPath = Join-Path $OutputDirectory ($releaseName + '.zip')
$zipStream = [IO.File]::Open($zipPath, [IO.FileMode]::Create)
$release = New-Object IO.Compression.ZipArchive($zipStream, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in ($sourceFiles | Sort-Object FullName)) {
        $relative = $file.FullName.Substring($package.Length + 1).Replace('\', '/')
        $entry = $release.CreateEntry($releaseName + '/' + $relative, [IO.Compression.CompressionLevel]::Optimal)
        $entry.LastWriteTime = [DateTimeOffset]'2026-10-04T00:00:00Z'
        $writer = $entry.Open()
        try { $data = [IO.File]::ReadAllBytes($file.FullName); $writer.Write($data, 0, $data.Length) } finally { $writer.Dispose() }
    }
} finally { $release.Dispose(); $zipStream.Dispose() }
$hashLines = @()
foreach ($file in @((Join-Path $OutputDirectory 'install.ps1'), $zipPath)) { $hashLines += (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant() + '  ' + (Split-Path -Leaf $file) }
[IO.File]::WriteAllText((Join-Path $OutputDirectory 'SHA256SUMS.txt'), ($hashLines -join "`n") + "`n", $utf8)
Write-Host "Built self-contained install.ps1 and $zipPath"
