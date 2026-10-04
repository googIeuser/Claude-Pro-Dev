# Architecture and scope

[Türkçe](ARCHITECTURE.tr.md)

The root marketplace exposes a single `prodev` plugin. `.claude-plugin/plugin.json` holds plugin metadata; `hooks/hooks.json` loads one native module, `register.js`. `policy.js` contains Core, guard, redaction and filtering policies. Native tests and isolated PowerShell installer/release tests ship with the source.

`session.start` reads host usage once and independently registers nine immediate helpers; individual command conflicts are caught and reported. `prompt.context` appends stable Core instructions without replacing project context or duplicating the named block. Usage/counters are not placed in the model prompt unless a user explicitly prints a report. `session.measure` updates observed quota/context data; `turn.complete` deduplicates per-agent/turn usage and duration. UI rendering preserves other mods' content. The optional checklist is now `skills/engineering/SKILL.md`, avoiding its former collision with `/prodev`.

`tool.call` inspects recognizable destructive Bash/PowerShell commands and secret paths before `next(e)`. The engine retains its normal model-tool permission checks. Results then undergo recursive redaction and optional long-text filtering. When changed, engine `ref` and `text` are removed so raw content is not replayed. Errors receive the character budget first, then nearby stack/assertion context, then head/tail samples. Omitted ranges and clipped lines are marked. This is deterministic sampling; it cannot recover host-truncated text or guarantee all evidence. Read/Grep/Glob source text and MCP structured/image content are not shortened.

Repeated-read tracking observes identical successful parameters per agent. It does not block reads, cache file contents or observe outside filesystem changes. Edits, shells, MCP calls and explicitly selected project checks conservatively clear signatures and advance an observed revision.

Verification receipts need numeric exit zero for PASS; missing exit, interruption/background work and failure remain distinct. Starting revision is captured before execution so concurrent edits make receipts stale. Only the last 50 names/statuses/codes/revisions/durations stay in memory, without command arguments or output bodies. An exit-zero program does not prove test quality or the entire project. External edits are not watched.

`/prodev-checks run <name>` reads a bounded reviewed `.prodev.json` only on demand, then explicitly uses `$.process.run(argv)` as the Windows user, without a shell. This user-selected process API is separate from model tool approval; project scripts can do arbitrary work, so review them first. One profile process runs at a time. [Profile contract](PROJECT-CHECKS.md). `/prodev-report` prints metrics JSON to the transcript; no plugin disk export. Claude may retain its normal transcript.

Hook error handling denies a call if inspection failed before `next`. After the engine has run, it returns the existing engine result without executing again; redaction can be bypassed on that error path. Treat guard/redaction as scaffolding, not a security boundary.

The plugin does not change model/effort, start agents, make extra model requests, poll HTTP or use timers. Queue state stays in memory; draft fills the prompt and waits for user submission. Suggestions use local state only. Mermaid output is text, with no custom renderer or CDN.

Installation copies source under the chosen Claude config folder and registers a local marketplace through the official CLI. Existing configuration and the prior package are backed up and restored on failure. The same ID's older cache is explicitly updated before verification. Only overlapping user-scope prodev plugins are disabled. Release building uses selected source paths; Git/build metadata, unrelated root files and generated host/private MCP types stay outside archives. Scripts and benchmark fixtures are embedded; included files still require privacy review.

Live smoke exercises real CLI sessions and Windows processes without model turns. The A/B runner uses per-process disabled-plugin maps and checks initialization before paid task work. Built-in host plugins remain identical in both arms; one collector and independent acceptance evaluate both. Permanent plugin settings are not changed. See [evidence](VERIFICATION.md) and [pilot](PILOT.md).

The API is early access. Custom panes, persisted queues, project-specific guard policies and semantic summarization remain future work.
