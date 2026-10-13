---
name: team
description: Coordinate a small native Claude Code agent team for independent parts of a task.
argument-hint: "<task>"
disable-model-invocation: true
---
Handle the user's task using a native Claude Code agent team:

$ARGUMENTS

If no task or current task context exists, ask what to work on. Read project instructions and identify independent work before spawning teammates.

Agent calls accept family aliases (`haiku`, `sonnet`, `opus`), not full IDs. For a configured full ID, pass its family alias and let the mod pin the exact ID at spawn. Omit model for inherit; choose an alias for auto. Omit inherited effort. Never pass `auto`, `inherit`, or a full ID as the Agent tool's model argument.

Agent teams require an interactive Claude Code session started with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. If that capability is unavailable, explain how to enable it and restart; offer ordinary subagents or solo work, and label the fallback accurately. Do not change settings or fabricate a team/config file. The `-p` mode does not spawn native teammates.

Read the session model/effort choices appended to this skill. Create a small native agent team with two teammates by default, only when independent work warrants it. Use `prodev:executor` for implementation or `prodev:advisor` for read-only review. Defaults are Sonnet executor, Opus advisor, and inherited effort. In executor auto mode choose Haiku for narrow, clearly specified assignments and Sonnet for complex/ambiguous/multi-file work; announce each selection. Pass the chosen effort unless inherit. Give each teammate an explicit name through the native Agent tool and a prompt containing its objective, constraints, paths, file ownership, acceptance criteria, and dependencies. Prefer a solo session when changes share the same files.

Create and assign shared tasks when the host provides Task tools; otherwise coordinate through native messages. Include task-specific evidence because teammates do not inherit the lead's conversation. Keep file ownership separate and resolve overlap before edits. Use direct messages for dependencies and findings. Wait for completion without frequent polling, inspect the combined changes, run relevant verification, and synthesize the result. Shut down teammates through the host when finished.

Respect permissions and account limits. `/prodev-model` affects future Pro Dev agents in this session; native `/model` and `/effort` control the main session. Do not enable bypasses or force a global subagent model. Model/effort requests may be constrained or substituted by the host; verify effective values in `/tasks`. Use the default in-process display for individual effort control; split-pane effort behavior depends on the host. Teams consume additional allowance. `/prodev-flow` is observed activity, not a team manager. Report missing capabilities and incomplete work honestly.
