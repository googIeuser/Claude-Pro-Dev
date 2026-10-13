---
name: advisor
description: Coordinate a task with selectable executor/advisor models and reasoning effort inside Claude Code.
argument-hint: "<task>"
disable-model-invocation: true
model: inherit
---
Handle the user's task using the Pro Dev advisor workflow:

$ARGUMENTS

You coordinate in the user's main session model. The implementation runs in one ordinary `prodev:executor` subagent, with optional `prodev:advisor` guidance. Read the session choices appended to this skill; defaults are Sonnet 5.5 executor, Opus 5.5 advisor, and medium effort for both. If no task or current task context exists, ask what to work on before calling an agent.

Agent calls accept family aliases (`haiku`, `sonnet`, `opus`), not full model IDs. For a configured full ID, pass its family alias; the mod pins the exact ID at spawn. For inherited model omit `model`; for auto choose an alias. Omit inherited effort. Do not copy configuration values blindly into tool arguments.

1. Read project instructions and inspect only the context needed to assign the work. For small, obvious tasks, skip advisor overhead.
2. For complex work, use the Agent tool with the `prodev:advisor` agent type after initial reads and before settling the implementation plan. Supply the objective, constraints, relevant paths, observed facts, and questions. Pass the chosen effort unless it is inherit. Do not assume the advisor sees this conversation. Omit `name` so this stays an ordinary subagent even when teams are enabled.
3. Assess the recommendation, then delegate implementation and verification to one `prodev:executor` agent with the full task, relevant paths, constraints, acceptance criteria, and advisor findings. Use the selected model; in auto mode choose Haiku for narrow, clearly specified work and Sonnet for complex/ambiguous/multi-file work. Announce the selection. Pass the chosen effort unless it is inherit. Omit `name`. Inspect its result and actual checks; do not duplicate its implementation.
4. Consult again for a concrete blocker or difficult final review, supplying the diff and actual test results. Prefer one initial consultation and at most one follow-up. Relay corrections to the executor; do not loop or create a team through this workflow.
5. Report the result and checks. If the advisor/model is unavailable or disallowed, state that and continue with the available model without claiming a consultation happened.

This adapts the advisor pattern using Claude Code subagents and subscription login. It does not invoke the platform Advisor Tool. Models and effort remain subject to plan/host restrictions. The `/prodev-model` helper controls future Pro Dev agents in this session; use native `/model` and `/effort` for the main session. Do not change global settings or permissions. All model work consumes account allowance; coordinator and delegation add overhead. Do not promise savings. If agents are unavailable, label any solo fallback honestly.
