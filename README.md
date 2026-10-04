# Claude Pro Dev

Focused engineering rules and native Claude Code Mods helpers in one small plugin. For **Windows PowerShell 5.1+** and **Claude Code 2.1.287+**.

[Türkçe README](README.tr.md) · [Benchmark](docs/BENCHMARK.md) · [Contributing](CONTRIBUTING.md) · [MIT license](LICENSE)

Maintained by [googIeuser](https://github.com/googIeuser). [CI status](https://github.com/googIeuser/Claude-Pro-Dev/actions/workflows/ci.yml).

Version **0.2.0** adds diagnostics, verification receipts and a runnable A/B pilot. Live CLI helpers are tested with Claude **2.1.289**; subscription savings remain unproven. [Evidence and limitations](docs/VERIFICATION.md). Independent community project; not affiliated with Anthropic.

## Install

Have Claude Code installed and available as `claude`. Sign in through Claude for interactive use; see [official setup](https://code.claude.com/docs/en/setup).

Install directly from this repository in PowerShell:

```powershell
irm 'https://raw.githubusercontent.com/googIeuser/Claude-Pro-Dev/main/install.ps1' | iex
```

To inspect the installer before running it, download the root `install.ps1` or open an extracted source package, then run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

The installer embeds the plugin. Administrator access, Node.js, npm, Python and a separate MCP server are not required for this package. ExecutionPolicy Bypass applies only to that process.

For a version-pinned download, use this command once the **v0.2.0 release** appears on the [Releases page](https://github.com/googIeuser/Claude-Pro-Dev/releases):

```powershell
# Requires a published v0.2.0 release.
irm 'https://github.com/googIeuser/Claude-Pro-Dev/releases/download/v0.2.0/install.ps1' | iex
```

The `main` URL follows source updates; the release URL pins a version. Maintainers: follow [publishing instructions](docs/PUBLISHING.md). Release assets are `install.ps1`, `claude-pro-dev-v0.2.0.zip` and `SHA256SUMS.txt`. Checksums detect corruption; they do not authenticate the publisher.

## Setup behavior

The installer registers **prodev@claude-pro-dev-local** in user scope using Claude's CLI. Files live under `%USERPROFILE%\.claude\prodev\package`, or your existing `CLAUDE_CONFIG_DIR`. It checks JSON configuration, retains backups, preserves model/permissions/status line/project instructions and restores configuration and the prior package on failure. Unused cache files may remain.

An enabled user-scope `prodev` from another marketplace is disabled to prevent command collisions; its files remain. Other plugins keep their enabled state. Avoid concurrent settings writes during installation.

Open a new Claude session and check `/plugin`, then `/prodev` in a trusted folder. Existing sessions can use `/reload-plugins`; new Core context requires a new session or `/clear`.

Run the same installer to upgrade v0.1. An existing plugin cache with an older version is explicitly updated. The checklist skill is now `/prodev:engineering`, avoiding the earlier collision with the local `/prodev` status command.

## Commands

| Command | Behavior |
|---|---|
| `/prodev` | Observed quota/cache readings and counters |
| `/prodev-doctor` | Observed hooks, unavailable readings and helper registration conflicts |
| `/prodev-checks` | Receipts with PASS / FAIL / UNKNOWN and conservative stale status |
| `/prodev-checks profile` or `run unit` | List trusted project checks / explicitly run one |
| `/prodev-report` | Session metrics JSON without prompts, command arguments or tool bodies |
| `/prodev-queue add Investigate failing test` | Add an in-memory task while Claude works |
| `/prodev-queue list` | List pending tasks |
| `/prodev-queue draft 1` | Replace the prompt with task #1; press Enter to submit |
| `/prodev-queue remove 1` or `clear` | Remove a task or clear the queue |
| `/prodev-flow [mermaid]` | Observed agent relationships/states; optional Mermaid text |
| `/prodev-next` | Local next-step suggestions without a model request |
| `/prodev-filter on` or `off` | Toggle long-output filtering for this session |
| `/prodev-guard on` or `off` | Toggle destructive-command heuristics for this session |
| `/prodev:engineering` | Optional engineering checklist skill; this uses the model |

Helpers run local Mods code. Sending a drafted task uses Claude normally. Drafting replaces existing prompt text and retains the queue item. Queue/history/counters reset on reload or exit; no persistence.

## Features and limits

- Short, stable Core instructions encourage narrow searches, reuse of reads, minimum correct changes, focused verification and concise responses. They are behavioral guidance, not a hard token budget.
- Two-line HUD above the terminal/Desktop Code prompt. Quota readings come from the host; unavailable data shows `unknown`. Context is separate. No background agents, HTTP polling or model switching.
- Cache ratio is observed cache-read / (input + cache-read + cache-creation) across completed turns, not subscription savings. Earlier usage is excluded.
- Agent flow observes existing agents; this plugin starts none. Manual queue, deterministic next steps and Mermaid text export are included. No custom diagram renderer.
- Bash/PowerShell stdout/stderr and MCP text fields are shortened to at most 12,000 characters per field by default. Error lines receive the budget first, followed by nearby stack/assertion context and head/tail samples. Omitted ranges and clipped lines are marked; exit metadata is preserved. Evidence can still be lost, including text already truncated by the host. Source Read/Grep/Glob and MCP structured content are not shortened.
- Best-effort destructive-command/secret-path guards and tool-result redaction. Claude permissions remain active. Turning the destructive guard off leaves secret checks active.

The guard is not a shell parser or sandbox; redaction is not comprehensive DLP. Aliases, encoded commands, symlinks, inputs, user prompts, previous transcripts, other mods and tool-written logs can fall outside coverage. Hook failure after execution can preserve an unsanitized result. Read [architecture](docs/ARCHITECTURE.md) and [security](SECURITY.md).

Repeated-read counters observe; they do not suppress tools or serve cached files. History is bounded to 20 queue tasks, 128 agents and 256 read signatures. UI support targets terminal/Desktop Code; VS Code chat and `claude -p` do not show the band. Host policies, disabled hooks and unsupported Desktop WSL sessions can prevent loading. Mods are an [early-access API](https://code.claude.com/docs/en/plugins/mods).

## Verification receipts and project checks

Create `.prodev.json` in a trusted project's working directory. [PowerShell example](docs/prodev.example.json) and [profile reference](docs/PROJECT-CHECKS.md):

```json
{"version":1,"checks":[{"name":"unit","argv":["powershell.exe","-NoProfile","-File","./tests.ps1"],"timeoutMs":30000}]}
```

Review the file, then explicitly select `/prodev-checks run unit`. Nothing runs automatically. The selected program runs as your Windows user through the native Mods process API, without shell interpolation; project scripts can perform arbitrary work, so this helper is for reviewed checks. Normal model tool permissions remain intact; these explicit user commands use a separate process API.

A receipt needs observed exit zero for PASS. Failure, missing exit code, timeout/background work and subsequent observed edits/shell/MCP activity are distinguished. A pass records one program's exit status; it does not prove test quality, the entire project or unchanged files. Edits outside the session are not watched. Only the last 50 receipts are kept in memory.

If the mod cannot load, run this outside Claude:

```powershell
& "$env:USERPROFILE\.claude\prodev\package\scripts\doctor.ps1"
```

Use your `CLAUDE_CONFIG_DIR` instead when configured. Doctor sends no model request and prints no account identity or settings contents.

## Run a benchmark

From this repository or the installed package:

```powershell
.\scripts\live-smoke.ps1 -OutputDirectory "$env:TEMP\prodev-live-unique"
.\scripts\benchmark.ps1 -RunLive -Repeats 1 -OutputDirectory "$env:TEMP\prodev-pilot-unique"
```

Folders must be fresh. Live smoke tests 16 local helper results and real success/failure processes without model turns. Benchmark explicitly starts **two model sessions per repeat** on your account; sessions contain multiple API requests. It uses Sonnet/low effort by default, per-process plugin isolation, fresh fixture copies, independent acceptance and the same collector in both arms. CSV/JSON summaries omit raw transcripts and identifiers. API cost estimates are not your subscription bill. See the [pilot record](docs/PILOT.md) and [broader protocol](docs/BENCHMARK.md).

## Verify and build

From the repository root:

```powershell
claude plugin validate . --strict
claude plugin validate .\plugins\prodev --strict
claude plugin test .\plugins\prodev
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-release.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\release.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\install.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\doctor.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\metrics.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\benchmark.Tests.ps1
```

Tests do not call a model. Installer tests use temporary config folders and retain them for inspection. Login, real quota readings and screen interactions require separate live checks; see [verification evidence](docs/VERIFICATION.md).

Build refreshes root `install.ps1` and writes assets to ignored `dist/`. Explicit source folders and dot-directory manifests are included; `.git`, `dist/` and unrelated root files are excluded. Included source files still need review for private data.

GitHub CI is configured for PowerShell 5.1/7 and Claude 2.1.287/2.1.289. Version tags trigger checked release publication. Check actual hosted results on the [Actions page](https://github.com/googIeuser/Claude-Pro-Dev/actions).

## Remove

```powershell
claude plugin disable prodev@claude-pro-dev-local --scope user
claude plugin uninstall prodev@claude-pro-dev-local --scope user
claude plugin marketplace remove claude-pro-dev-local
```

Open a new session. Package/backups remain for inspection. Older same-name plugins are not automatically re-enabled.
