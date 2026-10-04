# Verification evidence — 2026-10-04

Local Claude version: **2.1.289**. Supported target floor: **2.1.287**. Initial v0.1 hosted CI passed on both binaries and both PowerShell shells: [four-job run](https://github.com/googIeuser/Claude-Pro-Dev/actions/runs/37221899516). Check current v0.2 hosted results on the [Actions page](https://github.com/googIeuser/Claude-Pro-Dev/actions).

## v0.2 local and live evidence

| Check | Evidence |
|---|---|
| Actual native Mods engine | 48 tests passed, 0 failed; 17 added confidence tests |
| Long shell output | Bash and PowerShell retain a middle error, following stack and assertion despite huge head/tail noise; bounded output and exit metadata |
| Verification receipts | Numeric success/failure, unknown/background, stale after edits, and concurrent-edit handling covered |
| Actual CLI helper smoke | 16 helper results; 0 model turns and 0 API duration; real Windows processes return exit 0/7; synthetic secret masked |
| Actual CMD interactive terminal | HUD at 80 columns, doctor, queue add/list/draft; draft fills composer and waits for Enter; report shows 0 completed model turns |
| Actual model work | Four final Sonnet/low runs; 4/4 independent six-case acceptance, correct A/B isolation, no tool errors/permission denials |
| PowerShell 5.1 and 7 | Fresh isolated upgrade/reinstall/rollback, doctor, metrics, independent acceptance and release-reproducibility suites passed |
| Existing user profile | Upgraded to 0.2.0; installed doctor passed; model/effort/permission/status-line and unrelated plugin fields preserved |

The live doctor exposed a /prodev collision with this package's own skill; renaming the optional skill to engineering fixed all nine helper registrations. An upgrade regression exposed `plugin install` retaining the old cache; the installer now explicitly updates an older version for the same user-scope ID. Calibration runs and the lack of a demonstrated savings result are retained in [PILOT.md](PILOT.md).

Native test external engine responses are controlled; live smoke uses real command registrations, real queue state and Windows processes. The CMD terminal check uses actual interactive CLI rendering and input through a pseudoterminal, not a Desktop screenshot. Desktop is covered by render-tree tests only. Real agent-spawn UI, resizing, organization-managed policies, live quota accuracy and actual subscription savings remain unmeasured. Missing quota values were honestly unknown. No destructive command was executed; guard tests use controlled engine responses.

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

The v0.1 observations above are historical. The v0.2 section adds live terminal/helper/model evidence; it does not extend those results to Desktop screens, account-wide quota accuracy or general savings.
