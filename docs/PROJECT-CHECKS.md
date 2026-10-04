# Project checks / Proje kontrolleri

English: place `.prodev.json` in the session's working directory. Nothing reads/runs it automatically; `/prodev-checks profile` lists it, `/prodev-checks run <name>` explicitly selects a check. Review the file and the selected script first. The program runs as your user through the native [Mods process API](https://code.claude.com/docs/en/plugins/mods/api#reach-files-processes-and-the-network); this does not ask for the model's tool permission. No shell interpolation or environment overrides are added. Windows `.cmd` programs may require an explicitly configured interpreter; prefer an executable, for example `node.exe` or `powershell.exe`, with arguments. Project-specific runtimes are optional dependencies of your project, not Pro Dev.

Türkçe: `.prodev.json` oturumun çalışma klasöründe olmalı. Başlangıçta okunmaz veya çalıştırılmaz. `/prodev-checks profile` dosyayı listeler, `/prodev-checks run <name>` seçileni açıkça çalıştırır. Önce dosyayı ve script'i inceleyin. Program kullanıcınızın yetkileriyle native Mods process API'sinde çalışır; modelin tool izin sorusunu kullanmaz. Shell interpolation ve özel environment eklenmez. Windows'ta `.cmd` için yorumlayıcı gerekebilir; doğrudan executable tercih edin. Projenizin runtime ihtiyacı plugin bağımlılığı değildir.

| Field / Alan | Contract / Kural |
|---|---|
| `version` | Exactly / Tam olarak `1` |
| `checks` | 0–8 entries / öğe |
| `name` | Unique lowercase identifier: `^[a-z][a-z0-9-]{0,31}$` / benzersiz küçük harfli ad |
| `argv` | 1–32 strings; nonempty executable; at most 1,000 characters per argument; no newline/NUL / 1–32 metin, boş olmayan program adı |
| `timeoutMs` | Optional; 100–600,000ms; default 30,000 / isteğe bağlı; varsayılan 30 saniye |
| File / Dosya | Regular non-symlink, at most 16 KiB / normal dosya, symlink değil, en fazla 16 KiB |

Recognizable destructive commands, known secret paths and labelled secret arguments are refused even with `/prodev-guard off`. This is a heuristic, not script auditing. The helper allows one configured process at a time. Start failure/refusal/timeout yields UNKNOWN, without falsely inferring success from output. Exit-zero receipts can still represent bad or trivial tests. Native shell calls often omit numeric exit codes; those cannot earn PASS. Changing source files outside the session is not observed.

Tanımlı yıkıcı kalıplar, bilinen secret dosya yolları ve secret argümanları guard kapalıyken de reddedilir. Bu script denetimi değildir. Aynı anda tek proje kontrolü çalışır. Başlatma/izin/timeout sorunu UNKNOWN olur. Sıfır çıkış kodu, testin kalitesini kanıtlamaz. Native shell sonucu sayısal kod vermediğinde PASS oluşmaz. Oturum dışındaki disk değişiklikleri görülmez.

Receipts retain only bounded names, source, status, exit code, observed revision and elapsed time. Any observed edit, shell, MCP call or explicitly selected process advances the revision conservatively. Running lint after tests can make the test receipt stale even if lint was read-only. Concurrent activity during a check also makes its receipt stale. Reload/exit clears everything. No persistent report is written by the plugin; `/prodev-report` prints metrics JSON to the transcript, which Claude may retain normally.

Kayıtlar ad, kaynak, durum, çıkış kodu, gözlenen revision ve süre taşır. Edit, shell, MCP veya açıkça seçilen program revision'ı temkinli biçimde ilerletir. Lint yalnız okuma yapsa bile önceki test kaydı eski görünebilir. Kontrol sırasında başka etkinlik de kaydı eski yapar. Yeniden yükleme/çıkış tüm kayıtları temizler. Plugin raporu diske kaydetmez; `/prodev-report` JSON'u transcript'e yazar, Claude normal oturum kaydı tutabilir.
