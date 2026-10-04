# Architecture and scope

[Türkçe](ARCHITECTURE.tr.md)

The root marketplace exposes a single `prodev` plugin. `.claude-plugin/plugin.json` holds plugin metadata; `hooks/hooks.json` loads one native module, `register.js`. `policy.js` contains Core, guard, redaction and filtering policies. Native tests and isolated PowerShell installer/release tests ship with the source.

`session.start` registers six immediate commands and reads host usage once. `prompt.context` appends stable Core instructions without replacing project context or duplicating the named block. Usage/counters are not placed in the model prompt. `session.measure` updates observed quota/context data; `turn.complete` aggregates usage once per agent/turn. UI rendering preserves other mods' content.

`tool.call` inspects recognizable destructive Bash commands and secret paths before `next(e)`. The engine retains its normal permission checks. Results then undergo recursive redaction and optional long-text filtering. When changed, the original engine `ref` and `text` are removed so raw content is not replayed in place of the sanitized result. This is deterministic text sampling, not model summarization. Read/Grep/Glob source text is not shortened.

Repeated-read tracking observes identical successful parameters per agent. It does not block reads, cache file contents or observe outside filesystem changes. Write/Edit/MultiEdit/Bash clear the tracked signatures conservatively.

Hook error handling denies a call if inspection failed before `next`. After the engine has run, it returns the existing engine result without executing again; redaction can be bypassed on that error path. Treat guard/redaction as scaffolding, not a security boundary.

The plugin does not change model/effort, start agents, make extra model requests, poll HTTP or use timers. Queue state stays in memory; draft fills the prompt and waits for user submission. Suggestions use local state only. Mermaid output is text, with no custom renderer or CDN.

Installation copies source under the chosen Claude config folder and registers a local marketplace through the official CLI. Existing configuration and the prior package are backed up and restored on failure. Only overlapping user-scope prodev plugins are disabled. Release building includes explicitly selected source paths; Git metadata, dist and unrelated root files stay outside archives. Included files still require privacy review.

The API is early access. Custom panes, persisted queues, project-specific guard policies and semantic summarization are future work, not completed v0.1 features.
