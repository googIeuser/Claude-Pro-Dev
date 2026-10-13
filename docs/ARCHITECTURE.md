# Architecture — v0.3.3

Fresh installation adds main `claude-opus-5-5` and canonical `modelSettings` entries with medium effort for Opus/Sonnet/Haiku 5.5. Existing personal settings are preserved unless `-ResetModelDefaults` is requested. Other entry fields, including effort caps, are retained. The workflow defaults are pinned Sonnet 5.5 executor and Opus 5.5 advisor, each medium. Omitted command effort means medium; explicit inherit preserves caller effort. Reset restores the pinned profile while allowing a caller's different family unless an explicit helper override is active. Main-session model/effort remain editable through native commands; host restrictions take precedence.

In 0.3.2, shell streams and MCP text blocks share one 12,000-character visible-text budget per result. Failure-containing pieces get priority; omitted text may be empty with one aggregate notice. Non-text blocks, structured content, and metadata stay intact. This is not a total payload/token cap. Session choices append only role settings; delegation rules remain in the static skills. [Measurements](OPTIMIZATION.md).

[Türkçe](ARCHITECTURE.tr.md)

The root marketplace exposes one `prodev` plugin. It contains a native Mods module, two reusable agent definitions, and user-invoked skills. There is no standalone model client, server, credential store, or network request code in the plugin.

| Component | Role |
| --- | --- |
| `hooks/register.js` | Host events, nine immediate commands, session model choices, usage HUD, queue, receipts, activity tracking |
| `hooks/policy.js` | Stable engineering context, output redaction/filtering, structural check-profile validation |
| `agents/advisor.md` | Opus; Read/Grep/Glob only; strategic guidance and review |
| `agents/executor.md` | Sonnet; implementation within assigned scope |
| `skills/advisor/SKILL.md` | Main-model coordination of an ordinary implementation worker and optional advisor |
| `skills/team/SKILL.md` | Native team coordination with named teammates and distinct file ownership |
| `skills/engineering/SKILL.md` | Optional engineering checklist |
| `scripts/install.template.ps1` | Transactional user-scope installer and optional teams setting |
| `scripts/build-release.ps1` | Allowlisted ZIP and self-contained root installer |

`session.start` reads host usage once and independently registers local helpers. Command conflicts are reported without stopping remaining registrations. `prompt.context` appends a stable Core block once and preserves project instructions. `session.measure` records host quota/context readings. `turn.complete` deduplicates agent/turn tokens and duration. UI rendering preserves other mods.

`tool.call` always delegates to the host permission chain. There is no command-word or secret-file-path rejection, and hook failure falls back to the host. Results receive best-effort redaction and optional long-text filtering; a changed result loses the original engine `ref` and `text` to avoid replaying unsanitized content. Filtering prioritizes errors and nearby evidence, then head/tail samples. Omitted ranges are marked. Read/Grep/Glob source text and non-text MCP blocks are not shortened. Hook failure may preserve an original result; redaction is not a security boundary.

Repeated-read tracking observes successful Read/Grep/Glob parameters per agent without suppressing reads. Edits, shells, MCP calls, and explicit project checks clear signatures and advance an observed revision. External edits are not detected. Receipts require numeric exit zero for PASS, retain only the last 50 records, and become stale after observed activity. Reports use schema 2, omit the removed blocked counter, and contain no prompt or output bodies.

Advisor and team skills are explicitly invoked and use the host's model runtime. They do not run inside deterministic command handlers. The advisor skill preserves the main model as coordinator, delegates implementation to an executor, and consults a read-only advisor when useful. Defaults are Sonnet/Opus; all agents need explicit task context. Omitting agent names keeps the advisor workflow ordinary even when teams are enabled. Model access remains subject to plan and host restrictions.

`/prodev-model` stores model and effort choices for each Pro Dev role in session memory. `skill.prompt` appends current choices to the two workflow prompts; generic Core stays stable. `agent.spawn` applies explicitly selected models only to those roles. The Agent `tool.call` forwards explicitly selected effort before the native engine runs. Inherit effort leaves the caller value untouched; reset releases explicit overrides. Unrelated agents, permissions, and global model/effort configuration are unchanged. Reports show requested choices, not a guarantee of effective host values. Auto executor selection is workflow guidance: it preserves the chosen model from the assignment, rather than classifying task text deterministically. Split-pane effort handling remains a host limitation.

The team skill requires native interactive Agent Teams. Claude Code owns team directories, shared tasks, and messages; Pro Dev does not pre-author runtime team configuration. Teammates receive objectives, evidence, file ownership, and dependencies. `/prodev-flow` shows observed spawn/turn activity only and cannot reconstruct a full persistent team state.

The installer stages an allowlisted package, snapshots settings/marketplace metadata, installs through the official CLI, updates stale caches, verifies, and rolls back on failure. `-EnableAgentTeams` merges only the teams environment entry; ordinary installation preserves the current preference. Model and permission settings are retained. Manual compaction remains the package default. The generated root installer must be rebuilt after embedded source changes.

Native tests exercise the real Mods event chain with controlled external tool responses. Installer/release tests use isolated configuration folders; they never install into the user's existing profile. Interactive advisor/team behavior needs separate live verification. [Verification](VERIFICATION.md).
