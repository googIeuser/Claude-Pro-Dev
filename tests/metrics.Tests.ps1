[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\cli-session.ps1')
function Assert($Condition, [string]$Message) { if (-not $Condition) { throw "FAIL: $Message" }; Write-Host "PASS: $Message" }
$events = @(
    @{ type = 'assistant'; message = @{ content = @(@{ type = 'tool_use'; id = '1'; name = 'Read'; input = @{ file_path = 'PRIVATE_PATH' } }) } },
    @{ type = 'assistant'; message = @{ content = @(@{ type = 'tool_use'; id = '1'; name = 'Read'; input = @{ file_path = 'PRIVATE_PATH' } }) } },
    @{ type = 'assistant'; message = @{ content = @(@{ type = 'tool_use'; id = '2'; name = 'Read'; input = @{ file_path = 'PRIVATE_PATH' } }) } },
    @{ type = 'assistant'; message = @{ content = @(@{ type = 'tool_use'; id = '3'; name = 'Edit'; input = @{ file_path = 'PRIVATE_PATH' } }) } },
    @{ type = 'assistant'; message = @{ content = @(@{ type = 'tool_use'; id = '4'; name = 'Read'; input = @{ file_path = 'PRIVATE_PATH' } }) } },
    @{ type = 'user'; message = @{ content = @(@{ type = 'tool_result'; tool_use_id = '3'; is_error = $true; content = 'PRIVATE_OUTPUT' }) } },
    @{ type = 'result'; is_error = $false; num_turns = 4; duration_ms = 88; total_cost_usd = 0.02; result = 'PRIVATE_ANSWER'; usage = @{ input_tokens = 10; output_tokens = 20; cache_read_input_tokens = 70; cache_creation_input_tokens = 30 }; permission_denials = @(); subagent_stats = @{ spawned = 0 } }
)
$lines = ($events | ForEach-Object { $_ | ConvertTo-Json -Depth 12 -Compress }) -join "`n"
$metrics = Get-ClaudeMetrics -JsonLines $lines
Assert ($metrics.toolRequests -eq 4) 'duplicate tool IDs are counted once'
Assert ($metrics.repeatedReads -eq 1) 'identical reads repeat until a write invalidates them'
Assert ($metrics.toolErrors -eq 1) 'tool errors are distinct from final model success'
Assert ($metrics.inputTokens -eq 10 -and $metrics.cacheReadTokens -eq 70 -and $metrics.cacheWriteTokens -eq 30) 'separate usage categories come from the final result exactly once'
Assert (($metrics | ConvertTo-Json -Depth 8) -notmatch 'PRIVATE') 'summary contains no prompt, path, output or answer bodies'
$missing = Get-ClaudeMetrics -JsonLines '{"type":"system","subtype":"init"}'
Assert ($missing.completed -eq $false -and $null -eq $missing.inputTokens) 'incomplete sessions have unknown tokens, not zero or success'
Assert ((ConvertTo-WindowsArgument '') -eq '""') 'empty arguments are preserved'
Assert ((ConvertTo-WindowsArgument 'C:\path with spaces\') -eq '"C:\path with spaces\\"') 'trailing backslashes survive Windows argument parsing'
Write-Host 'Metrics checks passed.'
