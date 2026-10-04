# Live A/B pilot — 2026-10-04

One signed-integer bug, two repeats per arm, alternating A/B then B/A. Claude Code 2.1.289, resolved model **claude-sonnet-5-5**, low effort. Fresh file copies and sessions; explicit per-process plugin settings. A has no custom plugins; B loads Pro Dev 0.2.0. Built-in host plugins and existing home instructions remain the same in both. Model tools: Read/Grep/Glob/Edit/Write/Bash. No permission bypass. Independent acceptance outside each model fixture checks six predefined cases.

All **4/4** final runs passed independent acceptance and initialization isolation, with zero tool errors, permission denials, agents or manual interventions. CSV/JSON contain individual observations; the table contains per-arm medians, not a statistical claim.

| Median / Medyan | A | B |
|---|---:|---:|
| Wall time / Süre (ms) | 11293 | 10926 |
| Tool requests / Araç isteği | 4 | 4 |
| Uncached input tokens | 6 | 6 |
| Cache read tokens | 22366 | 23443 |
| Cache creation tokens | 4695 | 5232.5 |
| Output tokens | 851 | 831 |
| API estimate (USD; not subscription bill) | 0.0317752 | 0.0339406 |

**Conclusion:** correctness was maintained on this tiny task; tool requests were identical. Replies were slightly shorter, but cache creation/read inputs and API cost estimates were higher with Pro Dev. These observations do **not** establish a general efficiency improvement or subscription savings. A fresh session does not guarantee cold server cache. Two repeats on one task do not control service latency, cache warming or account-wide background activity. No actual 5h/7d quota delta was measured. API estimates are not the user's Pro bill.

[Final CSV](pilot-final.csv) · [Final JSON](pilot-final.json) · [Live helper smoke](live-smoke.json)

## Calibration runs retained

- [First pair](pilot-excluded.json): both independent acceptance checks passed, but both isolation checks failed. An empty `--setting-sources` argument still let the installed Pro Dev load into A. Excluded from the table and from efficiency conclusions.
- [Second pair](pilot-with-refusals.json): isolation and independent acceptance passed, but each arm had one native PowerShell refusal for spawning a nested PowerShell process, then a successful Bash fallback. Retained separately; not pooled with the final configuration. The final runner exposes Bash for this Windows executable fixture to avoid that avoidable detour. Guardrails were preserved.
- [Final script](../scripts/benchmark.ps1): checks plugin initialization using local `/help` before starting a task. Existing plugin settings are overridden only for the child process. If isolation is invalid, it stops before the paid task. Summaries omit account identity, session IDs, paths, prompts and tool bodies. The CLI may still retain its normal session records.

## Türkçe

Tek signed-integer hatasında A/B ve B/A sırasıyla toplam dört model oturumu çalıştı. Model/effort, başlangıç dosyaları ve bağımsız altı kabul koşulu aynıydı. A'da özel plugin yoktu; B'de Pro Dev 0.2.0 vardı. Host'un yerleşik plugin'leri ve mevcut home talimatları iki tarafta aynı kaldı. Dört koşu da doğru sonuç verdi; tool hatası, izin reddi, agent veya insan müdahalesi olmadı.

Araç sayısı değişmedi. Yanıt biraz kısaldı; cache input ve API maliyet tahmini yükseldi. Bu küçük ölçüm **tasarruf kanıtı değildir**. İlk hatalı izolasyon çifti ve nested PowerShell reddi içeren ikinci çift ayrı tutuldu. Raw transcript, kişisel path veya hesap verisi paylaşılmadı. Gerçek 5h/7d değişimi ölçülmedi; daha geniş görevler ve tekrarlar için [benchmark protokolünü](BENCHMARK.tr.md) kullanın.
