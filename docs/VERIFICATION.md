# Verification evidence — 2026-10-04

Local Claude version: **2.1.289**. Supported target floor: **2.1.287**, configured in CI but not separately run on the local machine. Check current hosted results on the [Actions page](https://github.com/googIeuser/Claude-Pro-Dev/actions).

Initial v0.1 validation recorded:

| Check | Evidence |
|---|---|
| Strict marketplace/plugin manifests | Passed |
| Native Mods engine tests | 31 passed, 0 failed |
| PowerShell 5.1 and 7 isolated installer suites | Passed |
| Spaces in config paths, repeat installation, embedded scriptblock install | Passed |
| Existing model/permission/unrelated plugin settings preserved | Passed |
| Populated plugin/marketplace arrays and legacy prodev collision | Passed |
| Mid-install failure rollback and malformed settings rejection | Passed |
| Release allowlist, embedded/checksum integrity and reproducibility | Passed under local PowerShell 5.1 during packaging development |

Native tests load actual plugin files into the real event chain. Controlled responses substitute external engine work, including tool execution and usage readings. Terminal/Desktop render trees are covered; a real screen usability test is not. Tests do not require a model request.

The earlier package was also installed in an existing user profile. The new plugin was enabled, an overlapping older prodev was disabled with files retained, and unrelated plugin states/model/permission/status-line settings were preserved. Private account data and profile paths are intentionally absent from this public record.

The GitHub preparation changes distribution, tests and documentation; it does not change plugin runtime policy. See README for repeatable commands.

## GitHub preparation checks

The prepared source was checked locally on the same date:

- Strict marketplace/plugin validation passed; native engine tests: **31 passed, 0 failed**.
- Release packaging, payload/asset hashes, repeated-build reproducibility and source-root protection passed in Windows PowerShell 5.1 and PowerShell 7.
- Isolated installer suites passed in both shells: first/repeat/embedded installation, legacy collision, unrelated settings and failed-install rollback.
- Both GitHub workflow definitions passed **actionlint 1.7.12**. This validates workflow definitions; it is not a hosted execution result.

Repository: [googIeuser/Claude-Pro-Dev](https://github.com/googIeuser/Claude-Pro-Dev). The READMEs use the real source installer URL. Version-pinned installation requires the matching release to have been published. Initial preparation evidence above describes local checks; hosted results are recorded by GitHub Actions.

Not measured: live authenticated quota accuracy, true subscription savings, real window interaction, organization-managed policies and exact 2.1.287 binary behavior. Use the benchmark protocol and inspect hosted CI results before extending claims.
