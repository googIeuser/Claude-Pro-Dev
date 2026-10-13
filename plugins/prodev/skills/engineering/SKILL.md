---
name: engineering
description: Apply a short engineering and usage checklist when the user requests Pro Dev guidance.
disable-model-invocation: true
---
Apply the Pro Dev core already supplied by the mod. Inspect the relevant code, make the smallest correct change, and verify the affected behavior. Reuse previous reads; delegate only when independent work justifies its cost. Keep replies concise. Respect repository instructions and the user's model/effort choice.

The deterministic helpers `/prodev`, `/prodev-doctor`, `/prodev-checks`, `/prodev-report`, `/prodev-queue`, `/prodev-flow` and `/prodev-next` run without a model request. Quota readings can be unavailable; never estimate remaining subscription allowance from token counts. Long shell/MCP text can be filtered, so request targeted missing evidence before concluding.

For an explicitly requested advisor workflow, use `/prodev:advisor <task>`; for independent team work, use `/prodev:team <task>` in an interactive session with teams enabled. These workflows consume model allowance. Pro Dev adds no command/file-name guard; retain the host's permission checks.

Use `/prodev-model executor|advisor <model> [effort]` to choose future Pro Dev agents' model and reasoning in this session; executor accepts auto. Defaults are Sonnet/Opus with inherited effort. Native `/model` and `/effort` control the main session. Model selections remain subject to host access/capability limits; check `/tasks` for actual values.
