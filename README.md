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

Type these commands into **Claude Code's prompt**, one at a time. They are not PowerShell commands.

| Command | What it does | When to use it |
|---|---|---|
| `/prodev` | Shows the host's latest 5-hour/weekly usage, observed cache/context readings and activity counters. | Check usage before or after a task. |
| `/prodev-doctor` | Shows which hooks have been observed, how many helpers registered, command conflicts and guard/filter settings. | Check loading after installation or investigate missing readings. An unobserved event does not mean a broken hook. |
| `/prodev-checks` | Lists observed check results as PASS / FAIL / UNKNOWN and indicates stale results. | Review what verification actually ran after a change. |
| `/prodev-checks profile` | Reads and lists checks from the working directory's `.prodev.json`; runs nothing. | Review available checks and their program arguments. |
| `/prodev-checks run <name>` | Explicitly runs one configured check and records its exit code. For example: `/prodev-checks run unit`. | Run a check after reviewing its profile and script. See [project checks](#verification-receipts-and-project-checks). |
| `/prodev-report` | Prints session metrics JSON, including counters, completed-turn tokens and check receipts; omits prompts, command arguments and tool bodies. | Inspect a session in detail or copy its metrics for comparison. The plugin does not save a report file. |
| `/prodev-queue` | Lists pending tasks; same as `/prodev-queue list`. | Keep follow-up work handy while Claude works. See the queue commands below. |
| `/prodev-flow` | Shows the relationships and states of agents observed in this session. | Inspect agent activity. It does not start any agents. |
| `/prodev-flow mermaid` | Outputs the same agent graph as Mermaid text. | Copy the graph into a Markdown document or Mermaid viewer. |
| `/prodev-next` | Suggests 2–3 next steps based on local activity, failed checks and the queue. | Get a short follow-up checklist after a task; no model request. |
| `/prodev-filter on` / `/prodev-filter off` | Enables/disables long shell and MCP text filtering for this session; defaults to on. | Turn it off when investigating evidence omitted from a long result. Secret redaction stays active. |
| `/prodev-guard on` / `/prodev-guard off` | Enables/disables recognizable destructive-command checks for this session; defaults to on. | Temporarily allow an intentionally authorized operation, then turn it back on. Secret checks and normal model tool permissions remain active. |
| `/prodev:engineering` | Invokes the optional engineering checklist skill using Claude's model. | Explicitly ask for focused engineering guidance. This consumes normal Claude usage. |

### Queue commands

| Command | What it does |
|---|---|
| `/prodev-queue add Review the parser tests` | Adds a task and returns its ID, for example `#1`. Nothing starts automatically. |
| `/prodev-queue list` | Lists task IDs and text. |
| `/prodev-queue draft 1` | Replaces the current prompt text with task #1. Review it and press Enter to send. The queue item remains. |
| `/prodev-queue remove 1` | Removes task #1 without running it. |
| `/prodev-queue clear` | Removes all pending tasks without running them. |

The queue holds up to 20 tasks, each at most 4,000 characters. Drafting requires an editable prompt; headless mode reports that none is available. Helpers run local Mods code without model requests. Sending a drafted task and invoking `/prodev:engineering` use Claude normally. Queue/history/counters reset on plugin reload or exit; no persistence.

### Reading the status

- `5h: 3% used` means 3% of the host's 5-hour allowance is consumed; `7d: 20% used` means 20% of the weekly allowance is consumed. These are account usage readings, not savings attributed to Pro Dev.
- `cache` is the observed cache-read share across completed turns. `context` is the host's context-use percentage. `unknown` means the relevant measurement is unavailable; no percentage is guessed.
- `tools` counts observed tool attempts, `repeat reads` counts repeated Read/Grep/Glob requests, and `agents` counts observed agents still running. `queue`, `filtered` and `blocked` count pending tasks, shortened results and refusals respectively. Zeros in a fresh session are normal.
- `observed input`, `cache read`, `cache write` and `output` are token totals reported by completed turns observed by this plugin. `checks: 0 current pass` means no exit-zero receipt belongs to the current observed revision. UNKNOWN and stale receipts are not current passes.

For a first session, run `/prodev-doctor`, then `/prodev`. Complete a normal coding task, then use `/prodev-checks`, `/prodev-report` and `/prodev-next` to review verification, activity and possible follow-up work. Configured checks require a reviewed `.prodev.json` and an explicit `/prodev-checks run <name>`.

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
