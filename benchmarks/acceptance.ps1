param([Parameter(Mandatory = $true)][string]$Candidate)
$ErrorActionPreference = 'Stop'
. (Join-Path $Candidate 'parser.ps1')
foreach ($case in @(@('-12, 3, 4', -5), @('-2,-3', -5), @('0, 2, -2', 0), @(' 10, , -4 ', 6), @('', 0), @('2,3', 5))) {
    $actual = Get-SignedTotal $case[0]
    if ($actual -ne $case[1]) { Write-Host 'Independent acceptance failed.'; exit 1 }
}
Write-Host 'Independent acceptance: 6 cases passed.'
exit 0
