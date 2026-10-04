# Changelog

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
