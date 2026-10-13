# Verification — v0.3.3, 2026-10-13

Local host: Windows, Claude Code **2.1.296**. Installation checks use PowerShell **5.1 and 7**. [Hosted CI](https://github.com/googIeuser/Claude-Pro-Dev/actions/workflows/ci.yml) separately covers Claude 2.1.293/2.1.296 × both shells.

| Check | Evidence and scope |
| --- | --- |
| Strict marketplace/plugin validation | Passed in the actual CLI. Non-blocking marketplace README advice does not affect the self-contained installer. |
| Native Mods tests | **64 passed, 0 failed**. Four new cases cover pinned default role models/medium effort, reset, omitted effort, and explicit inherit. Five assertions/cases failed before implementation (including the existing advisor-preservation expectation changed to the new default), then passed afterward. Existing budget, permission, queue, redaction and receipt tests remain passing. |
| Real CLI helpers | **20 results, zero model turns**; nine commands and both roles/workflows discovered. Reset restores `claude-sonnet-5-5` / `claude-opus-5-5` with medium effort. Explicit choices, auto, queue, exit-zero/exit-seven receipts, and masking passed. |
| Fresh installation, both shells | Main model `claude-opus-5-5`; canonical `modelSettings` entries save medium effort for Opus/Sonnet/Haiku 5.5. A fresh 0.3.2 embedded installation was observed missing the requested main default before the implementation. |
| Reinstallation/reset/rollback, both shells | Existing model/effort choices preserved on ordinary reinstall; missing defaults filled; `-ResetModelDefaults` restores Opus/medium without dropping effort caps. Source and embedded install, 0.3.2 → 0.3.3 upgrade, teams/environment preservation, malformed settings rejection, and mid-install rollback passed. Test profiles are isolated. |
| Release packaging, both shells | Allowlisted files, payload/checksum integrity, workflow embedding, reproducibility, and source-root protection passed. |
| Installed signed-in coding test | **No model/effort launch flags and no role-setting commands.** CLI initialization selected `claude-opus-5-5`; `/effort status` reported medium. Agent calls requested Opus advisor + Sonnet executor, both medium. Aggregate resolved models included Opus 5.5/Sonnet 5.5. Original signed-total fixture failed beforehand; **six independent acceptance cases passed after the fix**. Check file unchanged, exit 0, no timeout/model error. [Sanitized evidence](live-coding-smoke.v0.3.3.json). |

The live test used the installed plugin, with hook source matching the repository, and a fresh copy of `benchmarks/signed-total`. Other plugins were disabled for that process. Available tools were Agent, Read, Grep, Glob, Edit, Write, and Bash. Edit acceptance and a scoped check-command allowance were used; no permission bypass. **One host tool permission denial was reported.** Its reason was not retained. The six acceptance cases were therefore also verified independently outside the model session with `benchmarks/acceptance.ps1`; the model's own verification statement is not the acceptance evidence.

Effort evidence consists of saved canonical settings, the main session's effort-status result, and Agent invocation arguments. Actual provider reasoning budgets were not measured. Aggregate model usage does not identify per-role billing or independently prove each child model. Native spawn-boundary tests additionally verify the requested role pins. Host policy, environment, project settings, and launch overrides may take precedence.

## Historical evidence and limits

- [0.3.2 verification](VERIFICATION.v0.3.2.md) records the shared output-budget optimization and Sonnet/Haiku coding test. [Character measurements](OPTIMIZATION.md) belong to that revision; they are not current token/quota measurements.
- [0.3.1 verification](VERIFICATION.v0.3.1.md) retains arithmetic and Opus/Sonnet coding runs plus the excluded initial calibration. [Older verification](VERIFICATION.v0.2.md) and [pilot](PILOT.md) remain historical.
- Native interactive teams, terminal/Desktop workflow usability, model-unavailable fallback quality, general coding quality, account-wide quota accuracy, and real subscription savings remain unverified.
- Filtering bounds visible shell/MCP text, not structured content or images. Failure context is best effort; request targeted omitted evidence when needed.

Fresh defaults are editable: native `/model` and `/effort` for the main session; `/prodev-model` for future role agents. Ordinary reinstall preserves personal choices. Role reset affects this session's roles; installer `-ResetModelDefaults` explicitly restores the saved main-model/effort profile. Existing permissions and unrelated per-model fields are retained. The implementation follows [model configuration](https://code.claude.com/docs/en/model-config) and canonical [modelSettings](https://code.claude.com/docs/en/settings-reference#modelsettings).

Türkçe: 64 test ve model turu açmayan 20 CLI sonucu geçti. Yeni kurulum ana Opus 5.5 ve üç 5.5 modelinde medium eforla gelir; kişisel seçimler yeniden kurulumda korunur, açık sıfırlama test edildi. Kurulu profille canlı oturum Opus 5.5/medium açıldı; Opus danışman ve Sonnet uygulayıcı medium çağrıldı. Bir host araç reddi kaydedildi; oturum dışında 6 bağımsız kabul kontrolü geçti. Gerçek düşünme bütçesi, genel kalite, tasarruf ve etkileşimli ekipler ölçülmedi.
