# GitHub's PowerShell wrapper exits with the last native status. Expected
# negative checks must leave a successful suite with status zero.
[CmdletBinding()]
param([string]$TestRoot)
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'doctor.Tests.ps1') -TestRoot $TestRoot
if ($LASTEXITCODE -ne 0) { throw 'Doctor suite passed assertions but leaked a nonzero native exit code to the CI caller.' }
Write-Host 'PASS: successful negative-test suite returns zero to the CI caller'
