# Benchmark protocol — v0.3

[Türkçe](BENCHMARK.tr.md)

Measure correctness, usability, and efficiency separately. A shorter wrong answer is a failure. No subscription savings are established. [Older pilot evidence](PILOT.md) concerns v0.2 only; new collectors omit billing estimates.

## Local checks

Run native tests, isolated installer/release suites, and `scripts/live-smoke.ps1`. Cover stable Core, command text reaching host permissions, synthetic output redaction, bounded logs, queue draft without submission, unknown usage, and numeric/stale verification receipts. Use controlled tool events for destructive-looking strings; never execute them as real commands for a test.

## Advisor scenario (signed-in session)

Use an isolated repository with a known bug and independent acceptance cases. Run `/prodev:advisor <task>`. Check the selected implementation worker and read-only advisor receive relevant context, implementation completes, and independent checks pass. Try a trivial task to check unnecessary consultation is skipped. Verify that the main model remains unchanged. Test `/prodev-model executor haiku low`, separate advisor effort, executor auto, inherit, and reset; inspect actual values in `/tasks` and record substitutions. Auto must announce its choice; it is prompt guidance, not a classifier guarantee. Record actual model identities and consultations, not just intended behavior.

## Team scenario (interactive only)

Enable the experimental flag and restart. Use `/prodev:team <task>` on two independent modules. Confirm native named teammates, separate file ownership, messages, task dependencies where supported, completion, combined verification, and shutdown. Check disabled-flag and headless fallbacks. Ordinary subagents do not prove a native team formed. Resize the terminal, type while work runs, and check other mods still render.

## Controlled comparison

Use three tasks: a reproducible bug, long-log diagnosis, and a small feature. Define independent acceptance before model work. Compare baseline, advisor, and teams only where each fits. Use identical starting files, instructions, model/effort choices, permissions, and other plugins. For advisor/team arms, record every model used. Use fresh copies and alternate run order; three repeats per condition are exploratory, not general proof.

Record completion, acceptance, wall time, separate input/output/cache-read/cache-write tokens, tool counts/errors, repeated reads under one common definition, agent consultations, and human interventions. Include main and agent usage without double-counting cumulative readings. Missing values stay unknown. The existing `scripts/benchmark.ps1 -RunLive` is a normal-plugin A/B fixture, not an advisor/team benchmark; it uses your account and must be selected explicitly.

5h/7d host readings can support comparisons, but resets, delayed readings, and concurrent account use distort small differences. Context/cache percentages do not prove allowance savings. Report per-task medians/ranges and failures. Keep feature correctness, live usability, and measured efficiency conclusions separate.
