# Verification — v0.3.0, 2026-10-13

Local host: Claude Code **2.1.292**, Windows, Windows PowerShell 5.1 and PowerShell 7. Current hosted results belong on the [Actions page](https://github.com/googIeuser/Claude-Pro-Dev/actions); local checks are not hosted CI results.

| Check | Evidence and scope |
| --- | --- |
| Strict marketplace/plugin validation | Passed in the actual Claude Code CLI. |
| Native Mods tests | 47 passed, 0 failed. External engine work is controlled. Command/file-name blocking is removed; host permission refusals pass through. Output redaction/filtering, receipts, usage, and queue behavior remain covered. |
| Actual CLI loading | Initialization discovers `prodev:advisor` and `prodev:executor` agents, plus `prodev:advisor` and `prodev:team` skills/commands. This proves discovery, not model behavior. |
| Actual local helper smoke | 14 helper results, zero model turns; eight immediate helpers registered; real Windows processes return exit 0 and 7; synthetic output secret is masked. |
| Isolated installer, both shells | Default teams preference preserved; explicit teams flag enabled with unrelated environment entries preserved; repeat/source/embedded installation, version upgrade, malformed settings rejection, and rollback pass. Existing user profile is not modified by these tests. |
| Release packaging, both shells | Agent roles and workflow skills are embedded; allowlist, payload/checksum integrity, reproducibility, and source-root protection pass. |
| Metrics, acceptance, doctor, both shells | API billing estimates omitted; token categories retained; original bug rejected and six fixed cases accepted; negative diagnostics leave the test suite with exit zero. |

The changed permission-chain/profile tests and billing-metric assertion were observed failing before the implementation. The installer test also failed on the absent `-EnableAgentTeams` parameter before it was added. Destructive-looking commands use controlled tool responses; no destructive real command was executed.

## Not verified by these checks

- Actual Sonnet/Opus selection and advice quality under a subscription, model-unavailable fallbacks, or return to the session model after a skill turn.
- Native interactive teammate creation, task/message coordination, shutdown, resume behavior, or terminal/Desktop usability of the new workflows.
- Account-wide quota accuracy, reduced allowance consumption, or general task-quality improvement.
- Current changes on every older supported binary or organization-managed configuration. CI is configured for Claude 2.1.287/2.1.289 and both PowerShell shells.

Use the signed-in scenarios in [the benchmark protocol](BENCHMARK.md) to test model/team behavior. Those scenarios consume account allowance. The self-contained installer is generated from source; rebuild after embedded changes. Historical [v0.1/v0.2 verification](VERIFICATION.v0.2.md) and [pilot results](PILOT.md) do not establish v0.3 workflow behavior or savings.

Türkçe: Native testler, iki PowerShell sürümündeki ayrı kurulum/paket kontrolleri ve model isteği açmayan gerçek CLI yardımcıları doğrulandı. Yeni ajan/komutlar host tarafından bulunuyor. Canlı Sonnet/Opus danışma kalitesi ve yerel ekip koordinasyonu henüz sınanmadı; bunlar için giriş yapılmış etkileşimli oturum gerekir. Tasarruf iddiası yoktur.
