# Context optimization — 0.3.2

The goal is to avoid sending unnecessary plugin instructions and large text output to models. Model defaults, permissions, and the user's account settings are unchanged.

## Measured changes

Identical controlled fixtures, Node 24.19.0, 2026-10-13. Baseline: commit `c91562b` (0.3.1). Counts are JavaScript string characters, **not token counts or subscription quota**.

| Item | Before | After | Character reduction |
| --- | ---: | ---: | ---: |
| Combined MCP text (20 blocks) | 60,355 | 11,491 | 81.0% |
| Combined shell stdout/stderr | 19,849 | 4,022 | 79.7% |
| Session-choice appendix | 760 | 145 | 80.9% |
| Pro Dev core + advisor skill + choices | 5,013 | 4,398 | 12.3% |

Both output fixtures retained the tested error and adjacent stack line. The shell kept exit code 7. The instruction total excludes Claude Code's system prompt, conversation, project instructions, tool schemas, and agent definitions; it is not total request size. Prompt caching and model tokenization can change the practical effect. [Machine-readable evidence](optimization-results.json).

## What changed

Previously each MCP text block, and each shell stream, was filtered separately. Many individually small pieces could therefore exceed the intended text budget together. The new filter applies the existing per-piece filter first, then checks the combined size. If needed, it prioritizes pieces containing failure keywords, then the first/last and remaining pieces. Pieces may be shortened or empty, with one aggregate omission notice. Typed block order and metadata remain intact.

This is a **12,000-character visible-text cap per result**, not a total payload/token cap. Structured content and non-text evidence are preserved and may still be large. Error context is best effort: not every failure can fit. Ask for targeted omitted evidence rather than treating truncation as proof of success. `/prodev-filter off` restores full text; secret redaction remains active.

The advisor/team skills already contain model-alias, inheritance, auto-selection, and permission rules. Their session appendix now adds only the requested role choices instead of repeating those rules. The core and static skills remain stable for caching. Actual model requests still depend on host availability.

## Reproduce the character comparison

Optional maintainer tool; Node 24 was tested. Node is not a plugin installation/runtime dependency. Run from a repository checkout and use a fresh temporary folder:

```powershell
$measurementRoot = Join-Path $env:TEMP ('prodev-context-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $measurementRoot | Out-Null
git archive c91562b --format=zip --output="$measurementRoot/baseline.zip" plugins/prodev
Expand-Archive -LiteralPath "$measurementRoot/baseline.zip" -DestinationPath "$measurementRoot/baseline"
node scripts/measure-context.mjs "$measurementRoot/baseline" "$measurementRoot/before.json"
node scripts/measure-context.mjs . "$measurementRoot/after.json"
```

The tool imports the real policy functions and skill transform; it does not request a model, execute a check, or contact a provider. It records source hashes and uses the same task and text fixtures for both revisions. Native tests separately exercise the transformation in Claude Code's event chain, including metadata, late failure context, full-output opt-out, and unchanged small results.

## Türkçe

Amaç gereksiz metni azaltmaktır; gerçek abonelik tasarrufu ölçülmedi. Ortak sınır sadece terminal/MCP metnine uygulanır; görseller ve yapılandırılmış veriler korunur. Hata bağlamı mümkün olduğunca tutulur, ancak her ayrıntının kalacağı garanti edilmez. Eksik kanıtı hedefli bir komutla iste veya `/prodev-filter off` kullan.

Küçük işlerde normal istek, gerektiğinde danışman ve bağımsız işlerde ekip kullanmak ek koordinasyonu sınırlayabilir. İsteğe bağlı başlangıç: `/prodev-model executor auto low`, `/prodev-model advisor sonnet medium`. Ana model korunur; karmaşık işlerde daha yüksek seviye gerekebilir. Tek başarılı kod testi genel kalite veya kota tasarrufu kanıtı değildir. [Güncel doğrulama](VERIFICATION.md).
