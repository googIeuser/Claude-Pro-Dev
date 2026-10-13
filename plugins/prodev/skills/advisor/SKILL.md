---
name: advisor
description: Implement a task with a Sonnet executor and focused Opus advice inside Claude Code.
argument-hint: "<task>"
disable-model-invocation: true
model: sonnet
---
Handle the user's task using the Pro Dev advisor workflow:

$ARGUMENTS

You are the executor in the main session. If no task or current task context exists, ask what to work on before calling an advisor.

1. Read project instructions and inspect the relevant code. For a small, obvious change, act directly without advisor overhead.
2. For complex work, use the Agent tool with the `prodev:advisor` agent type after the initial reads and before settling the implementation plan. Supply the objective, constraints, relevant paths, observed facts, and specific questions. Do not assume the advisor sees this conversation. Omit `name` so this stays an ordinary subagent even when agent teams are enabled.
3. Assess the recommendation against the evidence, then implement and verify the task yourself. The advisor does not approve prompts or tool calls.
4. Consult again for a concrete blocker or a difficult final review, supplying the current diff and actual test results. Prefer one initial consultation and at most one follow-up; do not loop or create a team through this workflow.
5. Report the result and checks. If the advisor/model is unavailable or disallowed, state that and continue with the available model without claiming a consultation happened.

This is an adaptation of the advisor pattern using Claude Code subagents and subscription login. It does not invoke the platform Advisor Tool. Model availability depends on the user's plan and host configuration; do not set credentials, billing, global model overrides, effort, or permission bypasses. All model work consumes the account's normal allowance. Do not promise savings.
