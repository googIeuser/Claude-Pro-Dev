# Shared, dependency-free collector for controlled Claude CLI tests.
function ConvertTo-WindowsArgument([string]$Value) {
    return '"' + ([regex]::Replace([regex]::Replace($Value, '(\\*)"', '$1$1\"'), '(\\+)$', '$1$1')) + '"'
}
function Invoke-ClaudeSession([string]$WorkingDirectory, [string[]]$Arguments, [string[]]$Prompts, [int]$TimeoutSeconds = 180) {
    $info = New-Object Diagnostics.ProcessStartInfo
    $info.FileName = (Get-Command claude -CommandType Application -ErrorAction Stop).Source
    $info.Arguments = ($Arguments | ForEach-Object { ConvertTo-WindowsArgument $_ }) -join ' '
    $info.WorkingDirectory = [IO.Path]::GetFullPath($WorkingDirectory)
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardInput = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.StandardOutputEncoding = [Text.Encoding]::UTF8
    $info.StandardErrorEncoding = [Text.Encoding]::UTF8
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $info
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $timedOut = $false
    try {
        if (-not $process.Start()) { throw 'Claude could not start.' }
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        foreach ($prompt in $Prompts) {
            $message = @{ type = 'user'; message = @{ role = 'user'; content = $prompt } }
            $process.StandardInput.WriteLine(($message | ConvertTo-Json -Depth 5 -Compress))
        }
        $process.StandardInput.Close()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) { $timedOut = $true; $process.Kill(); $process.WaitForExit() }
        $watch.Stop()
        return [pscustomobject]@{ exitCode = $process.ExitCode; timedOut = $timedOut; wallMs = $watch.ElapsedMilliseconds; stdout = $stdout.GetAwaiter().GetResult(); stderr = $stderr.GetAwaiter().GetResult() }
    } finally { $process.Dispose() }
}
function Get-ClaudeMetrics([string]$JsonLines) {
    $events = @($JsonLines -split '\r?\n' | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
    $final = $events | Where-Object { $_.type -eq 'result' } | Select-Object -Last 1
    $ids = @{}; $errors = @{}; $reads = @{}; $repeated = 0
    foreach ($event in $events) {
        foreach ($part in $event.message.content) {
            if ($part.type -eq 'tool_result' -and $part.is_error) { $errors[$part.tool_use_id] = $true }
            if ($part.type -ne 'tool_use' -or -not $part.id -or $ids.ContainsKey($part.id)) { continue }
            $ids[$part.id] = $true
            if ($part.name -in @('Read', 'Grep', 'Glob')) {
                $key = $part.name + ':' + ($part.input | ConvertTo-Json -Depth 20 -Compress)
                if ($reads.ContainsKey($key)) { $repeated++ }; $reads[$key] = $true
            }
            if ($part.name -in @('Edit', 'Write', 'MultiEdit', 'NotebookEdit', 'Bash', 'PowerShell') -or $part.name -like 'mcp__*') { $reads.Clear() }
        }
    }
    $models = if ($final.modelUsage) { @($final.modelUsage.PSObject.Properties.Name) -join ',' } else { $null }
    return [pscustomobject]@{
        completed = $null -ne $final; modelError = if ($final) { [bool]$final.is_error } else { $null }
        model = $models; turns = $final.num_turns; durationMs = $final.duration_ms
        inputTokens = $final.usage.input_tokens; outputTokens = $final.usage.output_tokens
        cacheReadTokens = $final.usage.cache_read_input_tokens; cacheWriteTokens = $final.usage.cache_creation_input_tokens
        apiCostUsd = $final.total_cost_usd; toolRequests = $ids.Count; toolErrors = $errors.Count
        repeatedReads = $repeated; permissionDenials = if ($final) { @($final.permission_denials).Count } else { $null }
        agents = $final.subagent_stats.spawned
    }
}
