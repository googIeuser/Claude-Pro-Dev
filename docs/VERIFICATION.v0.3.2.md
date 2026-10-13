# Verification — v0.3.2, 2026-10-13

Local host: Windows, Claude Code **2.1.296**. PowerShell **5.1 and 7** for installation/release checks. Hosted results belong on [Actions](https://github.com/googIeuser/Claude-Pro-Dev/actions/workflows/ci.yml); local checks are not hosted CI results.

## Current revision

| Check | Observed result and scope |
| --- | --- |
| Strict marketplace/plugin validation | Passed in the actual CLI. Marketplace README installation advice is non-blocking; this project uses its self-contained installer. |
| Native Mods tests | **60 passed, 0 failed** across four files. Three new aggregate-budget cases failed against 0.3.1 first, then passed after the change. Two additional preservation cases cover small MCP output/reference and filtering-off with redaction. Existing model routing, permissions, failure evidence, receipts, queue, and UI tests remain passing. External tool work is controlled; the result transformation runs in the native event chain. |
| Real CLI helper smoke | **20 helper results, zero model turns**. Nine helpers and both roles/workflows discovered; independent model/effort choices, reset, queue, exit-zero/exit-seven checks, and masking passed. No interactive UI claim. |
| Reproducible context measurements | Same controlled fixtures against baseline `c91562b` and 0.3.2: MCP 60,355 → 11,491 characters; combined shell 19,849 → 4,022; Pro Dev core + advisor skill + choice text 5,013 → 4,398. Tested failure/stack lines and shell exit 7 retained. [Scope and reproduction](OPTIMIZATION.md), [source hashes and measurements](optimization-results.json). These are not token/quota measurements. |
| Signed-in coding smoke | Sonnet main session (`low`), Sonnet advisor (`medium`), Haiku executor (`low`); the shortened workflow prompt completed the signed-total bugfix. Original fixture failed beforehand; **six independent acceptance cases passed afterward**. Supplied check file unchanged, exit 0, no timeout/model error/permission denial. Resolved models included `claude-sonnet-5-5` and `claude-haiku-5-5`. [Sanitized evidence](live-coding-smoke.v0.3.2.json). |
| Isolated installation, both shells | Source/embedded installation, 0.3.1 → 0.3.2 upgrade, preserved ordinary teams preference, explicit teams enablement, unrelated environment settings, malformed settings rejection, and rollback passed. Tests do not modify the user's existing profile. |
| Release packaging, both shells | Allowlisted contents, embedded agents/skills/docs, payload/checksums, deterministic rebuild, and source-root protection passed. |

The coding test copied `benchmarks/signed-total` into a separate working folder and loaded the repository plugin source. Other plugins were disabled only for that process. Available tools: Agent, Read, Grep, Glob, Edit, Write, Bash. The fixture used edit acceptance and a scoped allowance for `powershell.exe -NoProfile -File ./check.ps1`; permissions were not bypassed. The prompt requested exactly one read-only advisor, then one executor, with no changes to the supplied check file. Independent acceptance used `benchmarks/acceptance.ps1` outside the model session. Requested effort is observed from Agent arguments; effective provider thinking budgets were not measured.

The result removed `TrimStart('-')` so integer conversion keeps the negative sign. Acceptance covers mixed signs, all-negative input, cancellation, whitespace/empty fields, empty input, and positive input. This is one controlled coding task, not a general quality or savings benchmark. Raw streams, account identifiers, and prompt/tool bodies are not published.

## Historical evidence

The [0.3.1 verification record](VERIFICATION.v0.3.1.md) retains three Haiku/Sonnet arithmetic cases, one Opus-advisor/Sonnet-executor coding case, and a separately excluded failed calibration. Those runs establish behavior only for their recorded revision. Historical [v0.1/v0.2 verification](VERIFICATION.v0.2.md) and [pilot results](PILOT.md) do not establish current workflow savings.

## Not established

- Real subscription savings, account-wide quota accuracy, general coding/advice quality, or the quality of automatic routing on complex tasks.
- Actual provider reasoning budgets, model-unavailable fallbacks, or Opus as a coding executor.
- Native interactive teammate creation, messages/shared tasks, shutdown/resume, split-pane behavior, or terminal/Desktop workflow usability.
- Compatibility with every older binary or organization-managed configuration. CI uses 2.1.293/2.1.296 × two PowerShell shells; minimum 2.1.293 supports Haiku 5.5.

The shared limit applies only to visible shell/MCP text. Structured data and non-text blocks may remain large. Failure context is best effort; follow up with targeted output or disable filtering if omitted evidence is needed. Native tests never execute the destructive-looking commands they use as permission-chain fixtures.

Türkçe: 60 eklenti testi ve model turu açmayan 20 gerçek CLI sonucu geçti. Aynı yapay örneklerde bağlam metni azaldı; bu, abonelik tasarrufu ölçümü değildir. Sonnet danışman + Haiku uygulayıcıyla canlı hata düzeltmesinin 6 bağımsız kontrolü geçti. Ayrı düşünme tercihleri Agent çağrılarında gözlendi; gerçek düşünme bütçesi ölçülmedi. İki PowerShell sürümünde kurulum, yükseltme, geri alma ve paket kontrolleri geçti. Etkileşimli Agent Teams hâlâ canlı denenmedi.
