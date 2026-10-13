# Verification — v0.3.1, 2026-10-13

Local host: Claude Code **2.1.296**, Windows, Windows PowerShell 5.1 and PowerShell 7. Current hosted results belong on the [Actions page](https://github.com/googIeuser/Claude-Pro-Dev/actions); local checks are not hosted CI results.

Update check on 2026-10-13: `claude update` reported **2.1.296 already up to date**. Strict validation, all 55 native tests, and the 20-result/zero-model-turn helper smoke were repeated before the bilingual README refresh. The installed plugin's hook source matched the repository before the following live coding test.

| Check | Evidence and scope |
| --- | --- |
| Strict marketplace/plugin validation | Passed in the actual Claude Code CLI. |
| Native Mods tests | 55 passed, 0 failed. External engine work is controlled. Eight model-choice cases cover spawn model/full ID/inheritance, Agent effort forwarding, invalid-input preservation, auto/reset, workflow context, unrelated agents, and no model request from the helper. Existing permissions, output filtering/redaction, receipts, usage, and queue cases remain covered. |
| Actual CLI loading | Initialization discovers `prodev:advisor` and `prodev:executor` agents, plus `prodev:advisor` and `prodev:team` skills/commands. This proves discovery, not model behavior. |
| Actual local helper smoke | 20 helper results, zero model turns; nine immediate helpers registered; independent model/effort choices, auto, and reset persist correctly in a real session. Real Windows processes return exit 0 and 7; synthetic output secret is masked. |
| Signed-in model smoke | Three small arithmetic cases passed: explicit Haiku 5.5 executor, Sonnet 5.5 advisor/executor with separate requested high/medium effort, and auto selection of Haiku for a narrow task. Main coordinator models were preserved. Resolved model IDs came from CLI usage; Agent arguments show requested effort. No file/shell tools or permission denials. [Sanitized evidence](live-model-smoke.json). |
| Signed-in coding smoke | Sonnet coordinator (`low`), one Opus advisor (`high`), then one Sonnet executor (`medium`) fixed the existing signed-total fixture in an isolated working folder. The original bug failed independent acceptance beforehand; all six cases passed afterward. The supplied `check.ps1` hash was unchanged. Exit 0, no timeout/model error/permission denial. Actual usage included `claude-opus-5-5` and `claude-sonnet-5-5`. [Sanitized evidence and case results](live-coding-smoke.json). |
| Isolated installer, both shells | Default teams preference preserved; explicit teams flag enabled with unrelated environment entries preserved; repeat/source/embedded installation, version upgrade, malformed settings rejection, and rollback pass. Existing user profile is not modified by these tests. |
| Release packaging, both shells | Agent roles and workflow skills are embedded; allowlist, payload/checksum integrity, reproducibility, and source-root protection pass. |
| Earlier unchanged collector evidence (v0.3.0) | Billing estimates omitted; separate token categories retained; original bug rejected and six fixed cases accepted in both shells. This is not a model-routing benchmark. |

Seven new model-routing assertions were observed failing before implementation; reset/preserve-caller behavior was also observed failing before correction. Unrelated-agent behavior remains a preservation case. Destructive-looking command tests use controlled tool responses; no destructive real command was executed.

One live calibration was incomplete: a full ID was attempted in the Agent tool's alias-only model field, and the fixture omitted the advisor's required read-only tools. Workflow instructions now require family aliases at the tool boundary and pin exact IDs at native spawn; the fixture was corrected. The repeated Sonnet advisor/executor case passed. Calibration is retained separately in the sanitized evidence rather than counted as a successful case.

## Live coding test conditions

The test used a copy of `benchmarks/signed-total`, the installed Pro Dev 0.3.1 source, and a Sonnet main session. Other plugins were disabled for that process; no user-wide plugin preference was changed. Available tools were Agent, Read, Grep, Glob, Edit, Write, and Bash. The fixture used edit acceptance and a scoped allowance for `powershell.exe -NoProfile -File ./check.ps1`; permissions were not bypassed. The prompt explicitly requested one read-only advisor consultation followed by one executor and prohibited modifying the supplied check file. Independent acceptance ran outside the model session using `benchmarks/acceptance.ps1`.

The resulting change removed `TrimStart('-')` so integer conversion retains the sign. The six cases cover mixed signs, all-negative input, cancellation, whitespace/empty fields, empty input, and positive input. This proves this controlled path worked once; it does not establish model quality on broader work or guarantee delegation for every prompt. Raw session streams, account identifiers, and prompt/tool bodies are not published.

## Not verified by these checks

- General advice/coding quality, model-unavailable fallbacks, Opus as a coding executor, or auto-selection quality beyond the narrow smoke task. Opus was exercised as a read-only advisor in the coding test. Requested Agent effort is observed; actual provider reasoning budgets/quality are not measured.
- Native interactive teammate creation, task/message coordination, shutdown, resume behavior, or terminal/Desktop usability of the new workflows.
- Account-wide quota accuracy, reduced allowance consumption, or general task-quality improvement.
- Current changes on every older binary or organization-managed configuration. The minimum is 2.1.293 for Haiku 5.5; CI is configured for 2.1.293/2.1.296 and both PowerShell shells.

Use the signed-in scenarios in [the benchmark protocol](BENCHMARK.md) to test model/team behavior. Those scenarios consume account allowance. The self-contained installer is generated from source; rebuild after embedded changes. Historical [v0.1/v0.2 verification](VERIFICATION.v0.2.md) and [pilot results](PILOT.md) do not establish v0.3 workflow behavior or savings.

Türkçe: Güncelleme kontrolünde 2.1.296 zaten günceldi. 55 native test ve model turu açmayan 20 gerçek CLI sonucu tekrar doğrulandı. Üç küçük canlı denemede Haiku/Sonnet 5.5 çalıştı; ayrı düşünme tercihleri Agent çağrılarına aktarıldı ve auto basit görevde Haiku seçti. Ek canlı kod testinde Opus danışman + Sonnet uygulayıcı işaretli sayı hatasını düzeltti; 6 bağımsız kontrol geçti ve verilen kontrol dosyası değişmedi. İlk kalibrasyon başarısızlığı ayrıca kayıtlıdır. Genel kod kalitesi, karmaşık işlerde otomatik seçim, gerçek düşünme bütçeleri ve canlı ekip koordinasyonu ölçülmedi. Tasarruf iddiası yoktur.
