---
name: team
description: Coordinate a small native Claude Code agent team for independent parts of a task.
argument-hint: "<task>"
disable-model-invocation: true
---
Handle the user's task using a native Claude Code agent team:

$ARGUMENTS

If no task or current task context exists, ask what to work on. Read project instructions and identify independent work before spawning teammates.

Agent teams require an interactive Claude Code session started with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. If that capability is unavailable, explain how to enable it and restart; offer ordinary subagents or solo work, and label the fallback accurately. Do not change settings or fabricate a team/config file. The `-p` mode does not spawn native teammates.

Create a small native agent team with two teammates by default, only when independent work warrants it. Use the `prodev:executor` agent type for implementation teammates (Sonnet), or `prodev:advisor` for read-only review (Opus). Give each teammate an explicit name through the native Agent tool and a prompt containing its objective, constraints, paths, file ownership, acceptance criteria, and dependencies. Prefer a solo session when changes share the same files.

Create and assign shared tasks when the host provides Task tools; otherwise coordinate through native messages. Include task-specific evidence because teammates do not inherit the lead's conversation. Keep file ownership separate and resolve overlap before edits. Use direct messages for dependencies and findings. Wait for completion without frequent polling, inspect the combined changes, run relevant verification, and synthesize the result. Shut down teammates through the host when finished.

Respect Claude Code permissions, the user's model/effort choices, and account limits. Do not enable bypasses or set a forced global subagent model. Teams consume additional subscription allowance. `/prodev-flow` is an observed activity view, not a team manager or persistent shared task store. Report missing capabilities and incomplete work honestly.
