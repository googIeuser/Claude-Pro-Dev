# v0.1 yapı ve kapsam

```text
claude-pro-dev-v0.1/
  .claude-plugin/marketplace.json
  install.ps1                     # üretilmiş, gömülü ZIP içeren tek dosya
  plugins/prodev/
    .claude-plugin/plugin.json
    hooks/hooks.json              # tek native mod module
    hooks/register.js             # event middleware ve UI
    hooks/policy.js               # core, guard, redactor, filter
    skills/prodev/SKILL.md         # yalnız kullanıcı çağırır
    tests/prodev.test.ts           # Claude native test engine
  scripts/install.template.ps1
  scripts/build-release.ps1
  scripts/verify.ps1
  tests/install.Tests.ps1          # PowerShell, ayrı config dizini
  docs/ARCHITECTURE.md
  README.md
  LICENSE
```

`session.start` helper komutları kaydeder ve mevcut usage bilgisini bir kere okur. `prompt.context` sabit core metnini ekler; mevcut proje talimatlarını silmez. Core her request'te değiştirilmez, usage ve sayaçlar prompt'a taşınmaz. `session.measure` gerçek quota/context olaylarını UI için saklar; `turn.complete` cache token sayaçlarını günceller. UI render hook'u mevcut diğer modların çizimini kendi ağacında korur.

`tool.call` açık tehlikeli komutları ve bilinen secret dosya adlarını kontrol eder. Sonra `next(e)` ile Claude'un izin sistemi ve aracı çalışır. Dönüşte redaction ve isteğe bağlı log filtresi uygulanır. Sonuç değişirse engine `ref` kaldırılır; aksi halde eski raw sonucu kullanabilirdi. Sonuç tekrar tool mapper'ına gider. Filtreleme LLM summarization değildir; kesilen metin her zaman kayıp bilgi içerir. Kaynak kod Read/Grep/Glob sonuçları kısaltılmaz.

Tekrarlanan okuma sayacı yalnız başarıyla okunan aynı Read/Grep/Glob parametrelerini izler; **okumayı engellemez veya cache'den eski dosya içeriği döndürmez**. Write/Edit/Bash görüldüğünde set temizlenir; diğer süreçlerin disk değişikliklerini izlemez. Sayaç teşhis amaçlıdır.

Guard'ın `.catch` handler'ı `next` çağrılmadan bir hata olursa aracı reddeder. Araç zaten çalıştıysa yeniden çalıştırmaz ve engine'in sonucunu korur. Böyle bir hook arızasında sonuç maskeleme atlanabilir; güvenlik sınırı olarak kullanılmamalıdır.

v0.1 model değiştirmez, ekstra model request'i veya subagent üretmez, HTTP/polling/timer kullanmaz. Usage optimizer core davranış politikasıdır, sert token bütçesi veya abonelik limit kontrolü değildir. Queue girişleri bellektedir; `draft` ile kişi istediği işi gönderir. Next-steps mevcut değişiklik/hata/queue sayaçlarından deterministik öneriler üretir. Mermaid metin export'u vardır; özel diagram renderer veya dış CDN yoktur.

Yerel marketplace, kalıcı config altındaki kaynak pakete referans verir. CLI ayrıca plugin cache kaydı oluşturur. Kurucu mevcut ayarların yedeğini alıp resmi CLI'yi kullanır; kurulumu yeniden çalıştırmak ikinci hook veya ikinci core kopyası eklemez. Yerel dosya değişikliklerinin yeni oturuma geçmesi `/reload-plugins` ve yeni context gerektirebilir.

Sonraki sürüme uygun noktalar: native pane'de seçilebilir agent listesi, kullanıcı tarafından açıkça seçilen proje guard kuralları, semantic log özetleme için ayrı ve isteğe bağlı maliyet politikası, queue persistence için secret-aware storage. Bunlar v0.1'de tamamlanmış özellik olarak sunulmaz.
