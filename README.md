# Claude Pro Dev

**A small Claude Code plugin for focused development with your Claude subscription.**

[Türkçe](README.tr.md) · [Contributing](CONTRIBUTING.md) · [MIT license](LICENSE)

Pro Dev adds a usage display, local helper commands, a **Sonnet executor + Opus advisor** workflow, and optional **Agent Teams**. Sign in to Claude Code with your subscription. No separate API key, API server, proxy, or paid API integration is required by this plugin.

Version **0.3.0** · Windows PowerShell **5.1+** · Claude Code **2.1.287+**. Use a current Claude Code release for experimental team features. Independent community project by [googIeuser](https://github.com/googIeuser); not affiliated with Anthropic.

## 1. Install

Install [Claude Code](https://code.claude.com/docs/en/setup), check `claude --version`, and sign in with `claude auth login` using your subscription account.

Download the repository and run the installer in PowerShell:

```powershell
git clone https://github.com/googIeuser/Claude-Pro-Dev.git
Set-Location .\Claude-Pro-Dev
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

Or use the self-contained installer from the default branch:

```powershell
irm 'https://raw.githubusercontent.com/googIeuser/Claude-Pro-Dev/main/install.ps1' | iex
```

The download-and-run form executes repository code; download and inspect `install.ps1` first if you prefer. Administrator access, npm, Python, and a separate MCP server are unnecessary.

To enable experimental Agent Teams during installation:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -EnableAgentTeams
```

Restart Claude Code in your project folder. Check `/plugin`, then `/prodev`.

## 2. Choose how to work

| Your task | Use | What happens |
| --- | --- | --- |
| A small fix or ordinary development | Your normal prompt | Your current model uses the short Pro Dev engineering guidance. |
| A complex change or difficult bug | `/prodev:advisor <task>` | Sonnet handles this turn; a read-only Opus advisor gives focused guidance when useful. |
| Independent work across modules | `/prodev:team <task>` | The lead coordinates a small native team with separate assignments and file ownership. |
| Usage or diagnostics | `/prodev`, `/prodev-doctor` | Local helpers show host readings without starting a model request. |

### Advisor example

```text
/prodev:advisor Fix the session refresh bug. Inspect the code, consult the advisor about the approach, implement the fix, and run the affected tests.
```

The executor reads the code, consults `prodev:advisor` for complex work, then implements and verifies the result. A second consultation can help with a blocker or difficult final review. Obvious tasks can skip the advisor.

This adapts the [advisor pattern](https://platform.claude.com/docs/en/agents-and-tools/tool-use/advisor-tool) with [Claude Code subagents](https://code.claude.com/docs/en/sub-agents). The platform's actual Advisor Tool is an API feature; this plugin uses ordinary Claude Code agents instead. The advisor gets the supplied task context and relevant files, not an automatic copy of the complete conversation.

The skill requests Sonnet for its turn; your session model resumes on the next prompt. The advisor requests Opus. Actual availability depends on your subscription and host restrictions. If a model or agent is unavailable, the workflow must report that and continue honestly with an available option. Global model and effort settings are preserved.

### Agent Teams example

```text
/prodev:team Improve the settings screen and its tests. Assign separate files to two Sonnet teammates, coordinate findings, then verify the combined changes.
```

Teams must be enabled **before an interactive session starts**. The installer switch saves `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in user settings. For a one-session alternative:

```powershell
$env:CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = '1'
claude
```

Claude Code manages team creation, messages, and tasks. Pro Dev supplies reusable `prodev:executor` (Sonnet) and `prodev:advisor` (read-only Opus) roles and a coordination workflow. The default team is small; same-file or sequential work should stay in one session. On Windows, the default in-process display needs no tmux.

Teams are experimental and unavailable in `claude -p` mode. An unavailable team feature must be reported; ordinary subagents are a fallback, not a native team. See [official Agent Teams documentation](https://code.claude.com/docs/en/agent-teams) for current limitations and controls.

**Advisor and team workflows consume your subscription allowance.** Extra agents can increase usage. Pro Dev does not guarantee savings, unlock models, or raise account limits.

## 3. Local helper commands

These eight commands are deterministic and do not start a model turn. The two workflow skills above do use models.

| Command | Purpose |
| --- | --- |
| `/prodev` | Usage, counters, and command overview. |
| `/prodev-doctor` | Loaded hooks, command conflicts, and missing readings. |
| `/prodev-queue add <text>` | Queue a task without starting it. |
| `/prodev-queue list` / `draft <id>` / `remove <id>` / `clear` | Manage the queue. `draft` fills the prompt; press Enter to send. |
| `/prodev-flow [mermaid]` | Observed agent activity; not a team manager. |
| `/prodev-next` | Simple next-step suggestions. |
| `/prodev-checks [profile \| run <name>]` | Verification receipts or an explicitly selected project check. |
| `/prodev-report` | Session metrics JSON without prompt or tool bodies. |
| `/prodev-filter on` / `off` | Toggle long shell/MCP output shortening. Output redaction stays active. |

5-hour and 7-day usage readings come from Claude Code. Missing readings show `unknown`. Context fill and cache ratio are separate measurements, not remaining allowance. Queues, receipts, and counters disappear when the session ends.

For configured checks, copy [the example](docs/prodev.example.json) to `.prodev.json` in your working folder and review its programs first. Nothing runs automatically. `/prodev-checks run <name>` runs that program as your Windows user. See [project checks](docs/PROJECT-CHECKS.md) for execution and receipt limits.

## Installation changes and removal

- Registers `prodev@claude-pro-dev-local` in user scope, under `%USERPROFILE%\.claude\prodev\package` or your existing `CLAUDE_CONFIG_DIR`.
- Backs up configuration and the previous package; restores them if installation fails.
- Disables automatic compaction and removes the old custom threshold. Restart Claude Code and use `/compact` manually.
- Preserves model, effort, permissions, other environment settings, and project instructions. `-EnableAgentTeams` enables the teams flag; ordinary installation preserves its current value.
- Disables overlapping user-scope `prodev` plugins from another marketplace to avoid duplicate commands; retains their files.

Version 0.3 removes the command/file-name guard and `/prodev-guard`. Pro Dev does not reject tool calls by keyword. Claude Code's permission checks still apply. Best-effort output redaction remains; it is not complete secret protection. Filtering can omit evidence; use targeted output or switch filtering off when needed.

Disable or uninstall:

```powershell
claude plugin disable prodev@claude-pro-dev-local --scope user
claude plugin uninstall prodev@claude-pro-dev-local --scope user
```

Saved compaction and team preferences remain after removal. Restore backed-up settings, or edit `settings.json`: set `autoCompactEnabled` to `true` for automatic compaction and remove the teams environment entry to disable teams for new sessions. Clear any shell-level teams flag too. Backups remain under `.claude\prodev\backups`.

## Development and verification

```powershell
claude plugin validate . --strict
claude plugin validate .\plugins\prodev --strict
claude plugin test .\plugins\prodev
powershell.exe -NoProfile -File .\tests\metrics.Tests.ps1
powershell.exe -NoProfile -File .\scripts\build-release.ps1
powershell.exe -NoProfile -File .\tests\release.Tests.ps1
powershell.exe -NoProfile -File .\tests\install.Tests.ps1
```

Rebuild root `install.ps1` after editing embedded files. Native tests need no model credentials. Model behavior and interactive teams need a signed-in session; static validation does not prove them. [Verification scope](docs/VERIFICATION.md) · [Architecture](docs/ARCHITECTURE.md) · [Benchmark](docs/BENCHMARK.md) · [Publishing](docs/PUBLISHING.md).

Older pilot files describe v0.2 and remain historical evidence, not results for advisor/team workflows. No subscription savings have been established.
