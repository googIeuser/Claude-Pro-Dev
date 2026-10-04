# Benchmark protocol

[Detailed Turkish protocol](BENCHMARK.tr.md) · [Blank results table](benchmark-results.template.csv)

Measure feature correctness, live usability and task efficiency separately. A cheaper wrong answer is a failed task. Subscription savings have not yet been measured.

Native tests should cover stable Core context, known risky command rejection before execution, synthetic secret masking, log evidence/exit metadata, queue drafting without submission, measured usage/cache fields and render-tree coexistence. Also test benign commands and important log lines without error keywords. Do not execute destructive commands.

For live usability use a logged-in terminal/Desktop Code session: narrow/wide windows, resizing, other mods, typing during work, queue add/list/draft/remove, agent start/finish and next steps. Native render tests are not screen tests. Mermaid export is text.

## A/B pilot

Three tasks: a reproducible bug, diagnosis from a long log, a small parser/CLI feature. Define independent acceptance checks before either condition; the model's own tests must not be the sole judge.

A: new Pro Dev disabled. B: enabled. Older overlapping prodev stays disabled in both. Other plugins, starting files, instructions, model, effort, fast mode and permissions are identical. Filter off alone is not the A condition.

Three repeats per task/condition = 18 task runs, potentially many API requests. Use fresh sessions and separate identical file copies. Alternate A-first/B-first order. Verify collection with one pair before doing the whole pilot. Keep failures, timeouts and manual interventions in the report.

A fresh session does not guarantee cold server cache. Record observed cache behavior and separate first/continuation turns; follow-ups must match.

## Measurement and decision

Use the same source for A and B; B's Pro Dev HUD cannot be the sole comparison instrument. Claude's [monitoring documentation](https://code.claude.com/docs/en/monitoring-usage) describes token/API/tool fields. A local console exporter/collector can collect both conditions. This document enables no telemetry or external export. Basic measurements do not require raw prompt/tool/API bodies.

Record correctness, wall time, successful/error API events, separate input/output/cache-creation/cache-read tokens, executed/rejected tools, unchanged repeated reads using a shared definition, agents and human interventions. Include main/agent/auxiliary usage. Do not add repeated cumulative counter snapshots or double-count metrics and events.

For fixed logs record before/after length and preserved evidence. Log compression is not whole-task savings. Pro Dev repeat-read counters observe, do not prevent reads, and clear after shell/writes; use one common definition for both conditions.

Real 5h/7d readings are supporting evidence: reset, delayed readings and concurrent account use can distort a small difference. Context/cache percentages do not establish subscription savings.

First require correct completion and preserved evidence. Show success rate, intervention counts, per-task medians and ranges. Suggested exploratory target, not an achieved result: about 15–20% less unnecessary tool/read work or improvement in separately reported token categories with quality maintained. Investigate slower runs or higher output/failures. Three repeats do not support broad claims.

Report three separate conclusions: features behave correctly; live use works; efficiency improved/did not improve on these tasks. Missing measurements stay blank/unknown.
