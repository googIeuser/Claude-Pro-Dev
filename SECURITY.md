# Security

Pro Dev v0.3 retains best-effort output redaction and removes its command/file-name guard. It is not a sandbox or complete secret-protection system. Keep normal project security controls and Claude permission checks.

`/prodev-checks run <name>` explicitly runs a program from the reviewed `.prodev.json` as your user through the Mods process API. This is separate from model tool-call approval; project scripts are executable code and can perform arbitrary work. No profile is run automatically. Only profile structure and size are validated; commands and paths are not screened by keyword.

Redaction coverage limits include user prompts, tool inputs, old transcripts, other plugins and tool-written logs. A hook failure can preserve the original result. Advisor and team workflows retain Claude Code permissions and use the signed-in account's allowance; they add no separate credential storage or service.

Do not include real credentials in issues, screenshots, transcripts or pull requests. Use synthetic examples. Revoke or rotate exposed credentials with their provider.

Use **Security → Report a vulnerability** if private reporting is enabled on the repository. Until it exists, report only a non-sensitive summary publicly and request a private contact channel before sharing details. This source package does not invent a maintainer email address.

Maintainers: enable GitHub private vulnerability reporting when publishing. Release checksums verify consistency, not publisher identity.
