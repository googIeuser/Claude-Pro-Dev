# v0.2 yapı ve kapsam

```text
claude-pro-dev/
  .claude-plugin/marketplace.json
  install.ps1                     # üretilmiş, gömülü ZIP içeren tek dosya
  plugins/prodev/
    .claude-plugin/plugin.json
    hooks/hooks.json              # tek native mod module
    hooks/register.js             # event middleware ve UI
    hooks/policy.js               # core, guard, redactor, filter
    skills/engineering/SKILL.md    # yalnız kullanıcı çağırır
    tests/prodev.test.ts           # Claude native test engine
  scripts/install.template.ps1
  scripts/build-release.ps1
  scripts/verify.ps1
  scripts/doctor.ps1
  scripts/live-smoke.ps1
  scripts/benchmark.ps1
  scripts/cli-session.ps1
  benchmarks/                     # aynı fixture ve bağımsız kabul kontrolü
  tests/install.Tests.ps1          # PowerShell, ayrı config dizini
  docs/ARCHITECTURE.md
  README.md
  LICENSE
```

`session.start` usage'ı bir kez okur ve dokuz immediate helper'ı bağımsız kaydeder. Komut çakışması kalan helper'ları durdurmaz; doctor bildirir. `prompt.context` sabit core'u bir kez, mevcut proje talimatlarını koruyarak ekler. Usage/sayaçlar kullanıcı rapor istemedikçe prompt'a girmez. `session.measure` host kota/context olaylarını saklar; `turn.complete` agent/turn başına usage ve süreyi iki kez saymaz. UI diğer modların çizimini korur. Skill `engineering` olarak yeniden adlandırıldı; `/prodev` çakışması giderildi.

`tool.call` Bash/PowerShell tehlikeli komut ve secret dosya kalıplarını kontrol eder. `next(e)` modelin normal tool izinlerini korur. Sonuçta redaction ve isteğe bağlı log filtresi uygulanır. Değişen sonuçtan raw engine `ref` ve `text` kaldırılır. Hata satırları önce, çevresindeki stack/assertion ayrıntıları sonra korunur; baş/son kalan bütçeyi kullanır. Atlanan aralıklar işaretlenir. Host'un önceden kestiği içerik kurtarılamaz; tüm kanıt garanti edilmez. Kaynak okumaları ve structured/görsel MCP sonuçları kısaltılmaz.

Tekrarlanan okuma sayacı aynı başarılı Read/Grep/Glob parametrelerini agent başına izler; okumayı engellemez, eski içerik sunmaz. Edit, shell, MCP ve açıkça seçilen proje programı imzaları temizler, gözlenen revision'ı ilerletir. Dışarıdaki dosya değişimi izlenmez.

PASS için sayısal exit zero gerekir; kod yoksa UNKNOWN, hata ve arka plan ayrı değerlendirilir. Başlangıç revision'ı kaydedilir; eşzamanlı edit kaydı eski yapar. Son 50 kayıt argüman/çıktı taşımadan bellekte tutulur. Tek programın başarısı bütün projenin veya test kalitesinin garantisi değildir. [Proje kontrolleri](PROJECT-CHECKS.md) yalnız kullanıcı seçince native process API'sinde, Windows kullanıcısının yetkileriyle çalışır. Model tool onayından ayrı bu helper için dosyayı/script'i önce inceleyin. Shell interpolation yoktur; aynı anda bir kontrol çalışır. Rapor diske export yapmaz; Claude normal transcript kaydı tutabilir.

Guard'ın `.catch` handler'ı `next` çağrılmadan bir hata olursa aracı reddeder. Araç zaten çalıştıysa yeniden çalıştırmaz ve engine'in sonucunu korur. Böyle bir hook arızasında sonuç maskeleme atlanabilir; güvenlik sınırı olarak kullanılmamalıdır.

v0.2 model değiştirmez, ek model request'i/subagent, HTTP/polling/timer üretmez. Optimizer davranış politikasıdır; sert bütçe veya abonelik kontrolü değildir. Queue bellektedir; draft giriş kutusunu doldurur ve Enter bekler. Next-steps yerel sayaçlardan öneri üretir. Mermaid metin export'u vardır; özel renderer yoktur.

Yerel marketplace, kalıcı config altındaki kaynak pakete referans verir. CLI ayrıca plugin cache kaydı oluşturur. Kurucu mevcut ayarların yedeğini alıp resmi CLI'yi kullanır; kurulumu yeniden çalıştırmak ikinci hook veya ikinci core kopyası eklemez. Yerel dosya değişikliklerinin yeni oturuma geçmesi `/reload-plugins` ve yeni context gerektirebilir.

Eski cache sürümü aynı ID üzerinden açıkça güncellenir. Builder, üretilmiş host/özel MCP tiplerini dışarıda bırakır; doctor/benchmark script'leri ve fixture'lar pakete gömülüdür. Live smoke gerçek CLI ve Windows programlarını model turu açmadan sınar. A/B runner eklentileri süreç bazında ayırır, paid task öncesi initialization'ı denetler; iki taraf aynı collector ve bağımsız kabul kontrolünü kullanır. Kalıcı plugin ayarları değişmez. [Kanıt](VERIFICATION.md), [pilot](PILOT.md).

Native pane, proje guard politikaları, semantic log özetleme ve kalıcı queue sonraki çalışmalardır. Mods erken erişim API'sidir; kullandığınız host sürümünde validate/test çalıştırın.
