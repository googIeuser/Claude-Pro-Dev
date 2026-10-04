# Contributing

Use Windows PowerShell 5.1 or PowerShell 7 and Claude Code 2.1.287+. Claude's native engine runs the plugin tests; no package manager is needed.

Keep changes focused. Preserve project instructions and Claude permissions. Avoid background polling, unsolicited model requests/agents, raw secret logging and broad truncation. Explain the benefit before adding dependencies.

For behavior changes add a regression test that fails before the fix. Native tests live in `plugins/prodev/tests/`; installer/release tests live in `tests/` and use temporary folders. Test guards with synthetic events, not destructive real commands. Use fake secrets.

Run the README validation/build commands, then also run:

```powershell
pwsh.exe -NoProfile -File .\tests\release.Tests.ps1
pwsh.exe -NoProfile -File .\tests\install.Tests.ps1
```

Rebuild after changing embedded files and include refreshed root `install.ps1`. Do not commit `dist/`, account configuration, transcripts, private paths or credentials. The archive allowlist does not sanitize included source files.

Describe the problem, resulting behavior and validation in pull requests. Explain model/tool overhead, false positives or possible evidence loss. Report live UI and A/B results separately from native tests; use [the benchmark protocol](docs/BENCHMARK.md).

When investigating API compatibility, use `/plugin-types` to generate types for your installed version. Do not commit account-specific generated output.
