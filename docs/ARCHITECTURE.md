# Architecture — v0.3

[Türkçe](ARCHITECTURE.tr.md)

The root marketplace exposes one `prodev` plugin. It contains a native Mods module, two reusable agent definitions, and user-invoked skills. There is no standalone model client, server, credential store, or network request code in the plugin.

| Component | Role |
| --- | --- |
| `hooks/register.js` | Host events, eight immediate commands, usage HUD, queue, receipts, activity tracking |
| `hooks/policy.js` | Stable engineering context, output redaction/filtering, structural check-profile validation |
| `agents/advisor.md` | Opus; Read/Grep/Glob only; strategic guidance and review |
| `agents/executor.md` | Sonnet; implementation within assigned scope |
| `skills/advisor/SKILL.md` | Sonnet main-session turn, focused ordinary advisor consultations |
| `skills/team/SKILL.md` | Native team coordination with named teammates and distinct file ownership |
| `skills/engineering/SKILL.md` | Optional engineering checklist |
| `scripts/install.template.ps1` | Transactional user-scope installer and optional teams setting |
| `scripts/build-release.ps1` | Allowlisted ZIP and self-contained root installer |

`session.start` reads host usage once and independently registers local helpers. Command conflicts are reported without stopping remaining registrations. `prompt.context` appends a stable Core block once and preserves project instructions. `session.measure` records host quota/context readings. `turn.complete` deduplicates agent/turn tokens and duration. UI rendering preserves other mods.

`tool.call` always delegates to the host permission chain. There is no command-word or secret-file-path rejection, and hook failure falls back to the host. Results receive best-effort redaction and optional long-text filtering; a changed result loses the original engine `ref` and `text` to avoid replaying unsanitized content. Filtering prioritizes errors and nearby evidence, then head/tail samples. Omitted ranges are marked. Read/Grep/Glob source text and non-text MCP blocks are not shortened. Hook failure may preserve an original result; redaction is not a security boundary.

Repeated-read tracking observes successful Read/Grep/Glob parameters per agent without suppressing reads. Edits, shells, MCP calls, and explicit project checks clear signatures and advance an observed revision. External edits are not detected. Receipts require numeric exit zero for PASS, retain only the last 50 records, and become stale after observed activity. Reports use schema 2, omit the removed blocked counter, and contain no prompt or output bodies.

Advisor and team skills are explicitly invoked and use the host's model runtime. They do not run inside the deterministic command handlers. The advisor skill requests Sonnet for the current turn and calls the read-only Opus role only when useful. Context must be supplied explicitly. Omitting an agent name keeps this an ordinary consultation even with teams enabled. Model access remains subject to plan and host restrictions.

The team skill requires native interactive Agent Teams. Claude Code owns team directories, shared tasks, and messages; Pro Dev does not pre-author runtime team configuration. Teammates receive objectives, evidence, file ownership, and dependencies. `/prodev-flow` shows observed spawn/turn activity only and cannot reconstruct a full persistent team state.

The installer stages an allowlisted package, snapshots settings/marketplace metadata, installs through the official CLI, updates stale caches, verifies, and rolls back on failure. `-EnableAgentTeams` merges only the teams environment entry; ordinary installation preserves the current preference. Model and permission settings are retained. Manual compaction remains the package default. The generated root installer must be rebuilt after embedded source changes.

Native tests exercise the real Mods event chain with controlled external tool responses. Installer/release tests use isolated configuration folders; they never install into the user's existing profile. Interactive advisor/team behavior needs separate live verification. [Verification](VERIFICATION.md).
