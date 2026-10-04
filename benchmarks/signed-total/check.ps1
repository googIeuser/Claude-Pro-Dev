$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'parser.ps1')
if ((Get-SignedTotal '-12, 3, 4') -ne -5) { Write-Error 'Negative numbers lose their sign.'; exit 1 }
if ((Get-SignedTotal '2, 3') -ne 5) { Write-Error 'Positive sum is incorrect.'; exit 1 }
Write-Host 'Visible checks passed.'
