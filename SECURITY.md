# Security

Pro Dev v0.2 provides best-effort guards/redaction, not a sandbox or complete secret-protection system. Keep normal project security controls and Claude permission checks.

`/prodev-checks run <name>` explicitly runs a program from the reviewed `.prodev.json` as your user through the Mods process API. This is separate from model tool-call approval; project scripts are executable code and can perform arbitrary work. No profile is run automatically. Regex checks do not make an untrusted script safe.

Coverage limits include aliases/encoding, symlinks, user prompts, tool inputs, old transcripts, other plugins and tool-written logs. A hook failure after tool execution can preserve the original result. `/prodev-guard off` affects destructive-command heuristics; secret checks remain active.

Do not include real credentials in issues, screenshots, transcripts or pull requests. Use synthetic examples. Revoke or rotate exposed credentials with their provider.

Use **Security → Report a vulnerability** if private reporting is enabled on the repository. Until it exists, report only a non-sensitive summary publicly and request a private contact channel before sharing details. This source package does not invent a maintainer email address.

Maintainers: enable GitHub private vulnerability reporting when publishing. Release checksums verify consistency, not publisher identity.
