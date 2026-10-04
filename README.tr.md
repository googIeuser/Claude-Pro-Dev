# Claude Pro Dev v0.1

[English README](README.md) · [Benchmark](docs/BENCHMARK.tr.md) · [GitHub yayınlama](docs/PUBLISHING.md)

Proje sahibi: [googIeuser](https://github.com/googIeuser). [CI durumu](https://github.com/googIeuser/Claude-Pro-Dev/actions/workflows/ci.yml).

Windows PowerShell 5.1+ ve Claude Code **2.1.287+** için tek plugin başlangıç paketi. Node.js, npm, Python, MCP sunucusu ve üçüncü taraf UI paketi gerektirmez. Claude Code oturum açma işlemini kullanıcı yapar.

## Tek komutla kurulum

PowerShell'de doğrudan GitHub kaynağından kurun:

```powershell
irm 'https://raw.githubusercontent.com/googIeuser/Claude-Pro-Dev/main/install.ps1' | iex
```

Önce kurucuyu incelemek isterseniz repodaki `install.ps1` dosyasını indirin veya kaynak ZIP'ini açın. Dosyanın klasöründe:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

`install.ps1` kendinden yeterlidir: plugin dosyalarının sıkıştırılmış kopyasını içerir. İndirilen **tek dosya** ile de aynı komut çalışır. Yanında paket varsa yerel dosyaları, yoksa gömülü paketi kullanır. Yönetici yetkisi gerekmez. `ExecutionPolicy Bypass` yalnız bu PowerShell sürecine uygulanır.

Belirli sürümü kurmak için [Releases sayfasında](https://github.com/googIeuser/Claude-Pro-Dev/releases) **v0.1.0 yayımlandıktan sonra** şu adresi kullanın:

```powershell
# v0.1.0 release yayımlanmış olmalı.
irm 'https://github.com/googIeuser/Claude-Pro-Dev/releases/download/v0.1.0/install.ps1' | iex
```

`main` adresi kaynak güncellemelerini izler; release adresi belirli bir sürümü kurar. Gömülü payload ayrı dosya indirmez. Payload SHA256 kontrolü bozulmayı yakalar; scriptin yayıncısını doğrulamaz. Builder'ın ürettiği installer ve ZIP için bağımsız SHA256 değerleri `dist\SHA256SUMS.txt` içindedir; release yayımlanırsa aynı dosya indirmelere eklenir.

Kurucu Claude sürümünü kontrol eder, mevcut JSON ayarlarını doğrular, ayarların yedeğini alır, paketi `%USERPROFILE%\.claude\prodev\package` altına kopyalar, yerel marketplace'i ekler ve **`prodev@claude-pro-dev-local`** pluginini kullanıcı kapsamında kurar. Var olan model, izin, status line ve `CLAUDE.md` içeriği korunur; plugin ayarlarını Claude'un resmi CLI'si birleştirir. `CLAUDE_CONFIG_DIR` varsa o dizin kullanılır. Başarısız kurulumda ayar dosyaları ve önceki paket geri yüklenir; oluşturulmuş fakat kayıtlı olmayan cache dosyaları kalabilir. Kurulum sırasında başka bir Claude sürecinin ayarları yazmaması önerilir.

## Claude içinde kullanın

Başka bir marketplace'ten kullanıcı kapsamında kurulmuş ve etkin bir `prodev` varsa, `/prodev` komut çakışmasını önlemek için kurucu onu devre dışı bırakır ve yeni paketi etkinleştirir. Eski plugin dosyaları silinmez. `agent-flow`, `prodev-queue`, `prodev-mermaid` ve diğer pluginler etkinlik durumlarını korur. Kurulum hatayla biterse önceki `prodev` etkinliği de yedekten geri yüklenir.

Yeni bir oturum açın; açık oturumda `/reload-plugins` çalıştırın. Yeni core kuralları için yeni oturum veya `/clear` kullanın. `/plugin` içinde `prodev` aktif görünmelidir. Güvenilir bir çalışma klasörü ve oturum açmış Claude hesabı gerekir.

| Komut | Davranış |
|---|---|
| `/prodev` | Gerçek limit okumaları, cache oranı ve yerel sayaçlar |
| `/prodev-queue add Test hatasını incele` | İş sürerken de yapılacakları bellekte sıraya ekler |
| `/prodev-queue list` | Kuyruğu gösterir |
| `/prodev-queue draft 1` | #1'i giriş kutusuna koyar; göndermek için Enter'a basın |
| `/prodev-queue remove 1` / `clear` | Kuyruktan siler / tümünü temizler |
| `/prodev-flow` | Gözlenen agent ağacı ve durumları |
| `/prodev-flow mermaid` | Aynı ağacı Mermaid metni olarak verir |
| `/prodev-next` | Ek model çağrısı yapmadan 2–3 sonraki adım önerir |
| `/prodev-filter off` / `on` | Uzun log kısaltmayı bu oturumda değiştirir |
| `/prodev-guard off` / `on` | Yıkıcı komut kontrolünü bu oturumda değiştirir |
| `/prodev:prodev` | İstenirse modeli kullanan kısa mühendislik checklist skill'i |

`/prodev*` helper komutları doğrudan Mods kodunu çalıştırır. `/prodev:prodev` skill'i ve kuyruğa alınmış bir işi Enter ile gönderme normal Claude kullanımı tüketir. Queue otomatik çalışmaz; `draft` mevcut giriş metninin yerine geçer ve öğeyi kuyrukta tutar. Kuyruk, agent geçmişi ve sayaçlar plugin yeniden yüklenince veya süreç kapanınca sıfırlanır; diske yazılmaz.

## Neler hazır?

- **Senior Engineer Core:** `hooks/policy.js` içindeki kısa, sabit kurallar ilk bağlama bir kez eklenir. En küçük doğru değişiklik, dar arama, önceki okumaları kullanma, az ve anlamlı doğrulama, kısa cevap ve ihtiyaca göre delegation davranışını teşvik eder.
- **Usage/cache HUD:** Terminal ve Claude Desktop Code sekmesinde giriş üstünde iki satır. 5h ve 7d alanları son API cevabının gerçek limit yüzdeleridir. Veri yoksa `unknown`; context ayrı alandadır. Limit reset tarihleri API verisinde olabilir; v0.1 bandı bunları göstermez.
- **Cache oranı:** Gözlenen tamamlanmış turn'lerde `cache_read / (input + cache_read + cache_creation)`. Token tasarrufu veya abonelikten kalan miktar değildir. Plugin yüklenmeden önceki kullanım dahil değildir; devam eden turn sırasında tamamlanmış turn'lerin verisini gösterir.
- **Agent flow:** Bu plugin agent başlatmaz; var olan spawn/complete olaylarını izler. Geçmiş en fazla 128 agent kaydıdır. Adımlar ve full agent çıktıları saklanmaz.
- **Tool-output filtering:** Bash stdout/stderr ve MCP text çıktıları için alan başına yaklaşık 12.000 karakter / 160 satır. İlk 50, son 50 ve ortadaki en fazla 60 hata satırını örnekler. Kaynak kod okuma/arama ve MCP structuredContent kısaltılmaz. Kısaltma görünür biçimde belirtilir; tüm hata kanıtını koruma garantisi yoktur. Küçük çıktılar olduğu gibi kalır. Çıkış kodu gibi metadata korunur.
- **Safety iskeleti:** Hard reset, force push, git clean, recursive silme ve DROP/TRUNCATE için açık komut kalıplarını engeller. Claude'un normal izin kontrolünü atlamaz. Güvenlik kapatılınca secret kontrolleri sürer.
- **Secret iskeleti:** `.env`, bazı credential/private-key dosya adlarını doğrudan araç erişiminde engeller. Tool sonuçlarındaki bilinen API key, token, password, authorization, JWT ve private-key kalıplarını maskeler. Raw log yedeği yazmaz.

Koruma **heuristic bir başlangıçtır**: shell parser, dosya erişim sandbox'ı veya tam DLP değildir. Alias, symlink, encoded komut, başka modlar, tool input'ları, user prompt'ları, debug logları, tool'ların kendi disk yazıları ve önceki transcript verileri kapsam dışındadır. Secret dosya adları otomatik örnek dosya istisnaları dışında bloklanır; `.key` gibi adlar yanlış pozitif üretebilir. Belirsiz veya yüksek riskli migration için yerel proje kuralları ve Claude'un izin sistemi kullanılmalıdır.

## Kurulum doğrulama

Paket klasöründe:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1
claude plugin list --json
claude plugin validate .\plugins\prodev --strict
claude plugin test .\plugins\prodev
```

Gerçek ayarları değiştirmeden kurucu testi:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\install.Tests.ps1
```

Test geçici bir Claude config dizini kullanır ve inceleme için bırakır. Hook testleri Claude'un kendi engine'inde çalışır; guard, redaction, uzun çıktı, queue, stable context, gerçek ölçüm alanları ve terminal/Desktop render ağacını sınar. Testler model çağırmaz. Bu makinedeki doğrulama **Claude Code 2.1.289**, Windows PowerShell 5.1 ve PowerShell 7 ile yapılır; 2.1.287 üzerindeki canlı hesap/ekran testi ayrıca kullanıcı oturumunda yapılmalıdır.

Kurucu testleri, birden fazla plugin ve marketplace ile önceki `prodev` kurulumu içeren config üzerinde de çalışır. Bu, Windows PowerShell 5.1'in JSON array sonucunu tek pipeline öğesi olarak döndürdüğü durumda plugin listesinin yanlış değerlendirilmesini önler.

## Kaldırma ve sorun giderme

```powershell
claude plugin disable prodev@claude-pro-dev-local
claude plugin uninstall prodev@claude-pro-dev-local --scope user
claude plugin marketplace remove claude-pro-dev-local
```

Yeni oturum açın veya `/reload-plugins` çalıştırın. Paket ve yedekler `.claude\prodev` altında inceleme için kalır. Core'u temizlemek için yeni oturum veya `/clear` gerekir. `disableAllHooks`, `--safe-mode`, `--bare`, yönetilen kuruluş politikaları veya pluginlerin desteklenmediği Desktop WSL oturumları modun yüklenmesini önleyebilir. VS Code chat ve `claude -p` UI bandını çizmez; hook/komutlar desteklenen hostlarda çalışır.

Yerel kaynak veya indirilen dosya değiştirildiğinde kurucuyu tekrar çalıştırın. Gömülü dağıtımı güncellemek için:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-release.ps1
```

## Resmi kaynaklar

- [Mods ve 2.1.287 alt sınırı](https://code.claude.com/docs/en/plugins/mods)
- [Mod oluşturma ve paket yükleme](https://code.claude.com/docs/en/plugins/mods/create)
- [Event, tool.call ve başarısız hook davranışı](https://code.claude.com/docs/en/plugins/mods/events)
- [UI yüzeyleri ve diğer modların bandını koruma](https://code.claude.com/docs/en/plugins/mods/interface)
- [Mods API ve session.usage](https://code.claude.com/docs/en/plugins/mods/api)
- [Native mod testleri](https://code.claude.com/docs/en/plugins/mods/test)

Mods erken erişim API'sidir. Claude güncellendiğinde `/plugin-types` ile kendi sürümünüzün tiplerini üretin ve `validate` / `test` komutlarını tekrar çalıştırın.

GitHub paylaşımı için İngilizce/Türkçe belgeler, katkı ve issue şablonları, CI ve release iş akışları hazırdır. Builder kökteki install.ps1 dosyasını yeniler ve dağıtım dosyalarını git tarafından dışlanan dist/ dizininde oluşturur. GitHub üzerindeki gerçek test sonuçlarını [Actions sayfasından](https://github.com/googIeuser/Claude-Pro-Dev/actions) izleyin. Sürüm yayımlamak için [yayınlama belgesini](docs/PUBLISHING.md) kullanın.
