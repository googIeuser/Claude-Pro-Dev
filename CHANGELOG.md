# Changelog

## 0.3.1 — 2026-10-13

- Add session-only `/prodev-model` choices for executor/advisor models and separate reasoning effort, including full 5.5 IDs, inherited settings, and executor auto mode.
- Apply explicit model choices at the native spawn boundary and effort choices to Pro Dev Agent calls; unrelated agents and global settings are preserved.
- Advisor workflow now keeps the main model as coordinator and delegates implementation to the selectable executor. Auto selection is workflow guidance, not a deterministic classifier or savings guarantee.
- Require Claude Code 2.1.293+ for Haiku 5.5; update the CI matrix to 2.1.293/2.1.296.
- Add native routing regression tests and real local-command smoke coverage. Update both READMEs and the self-contained installer.

## 0.3.0 — 2026-10-13

- Add `/prodev:advisor`: a Sonnet executor turn with focused read-only Opus advice through native Claude Code subagents and subscription login.
- Add `/prodev:team` and reusable executor/advisor roles for experimental native Agent Teams.
- Add installer `-EnableAgentTeams`, preserving other environment settings and rollback behavior.
- Remove command/file-name guard heuristics, profile keyword screening, `/prodev-guard`, and blocked counters. Claude Code permissions still apply.
- Remove API billing estimates from new metrics; retain previous pilot evidence as historical records.
- Rewrite English and Turkish READMEs with setup, examples, commands, limitations, and removal instructions.
- Session report schema is now 2 because `counters.blocked` was removed. Local helpers remain deterministic; advisor/team workflows consume account allowance.

- PowerShell installation disables automatic context compaction and removes custom compaction thresholds; use `/compact` manually. Settings remain covered by installation backup and rollback.

## 0.2.0 — 2026-10-04

- Live hook doctor, external read-only installation doctor and registration-conflict isolation.
- Explicit project checks with real exit-code receipts, UNKNOWN/stale states and body-free session reports.
- PowerShell guard/filter support; failure context gets log budget before head/tail noise.
- Rename optional checklist to engineering: the live host refused the former /prodev name because its skill already used it.
- Explicitly update an old cache when upgrading an existing user-scope plugin ID; regression test covers v0.1 to v0.2.
- Live CLI smoke and a reproducible A/B pilot with independent acceptance, plugin isolation and a shared metrics collector.
- Exclude generated host/MCP declarations from release archives. No measured subscription savings claimed.
- Negative doctor tests explicitly return suite success to CI after asserting the expected failing child exit status.

## 0.1.0 — 2026-10-04

- Initial single-plugin engineering Core, usage/cache HUD, observed agent flow, manual queue and local next steps.
- Long Bash/MCP text filtering and best-effort secret/destructive-command guards.
- Self-contained PowerShell installer with backups and rollback.
- Regression fix for populated plugin lists in PowerShell 5.1 and reversible same-name plugin collision handling.
- Native hook, isolated installer and release packaging tests.
- English/Turkish docs, A/B benchmark protocol and GitHub CI/release workflows.

No measured subscription savings, queue persistence, automatic task execution or custom Mermaid renderer in this release.
