# Claude Pro Dev

**Claude aboneliğinle daha düzenli geliştirme yapmanı sağlayan küçük bir Claude Code eklentisi.**

[English](README.md) · [Katkıda bulunma](CONTRIBUTING.md) · [MIT lisansı](LICENSE)

Pro Dev; kullanım göstergesi, yerel yardımcı komutlar, **modeli seçilebilen uygulayıcı + danışman** akışı ve isteğe bağlı **Agent Teams** desteği ekler. Varsayılan uygulayıcı Sonnet, danışman Opus'tur; Haiku ve ayrı düşünme seviyeleri de seçilebilir. Abonelik hesabınla giriş yapman yeterli. Ayrı API anahtarı, sunucusu, proxy veya ücretli API entegrasyonu gerekmez.

Sürüm **0.3.1** · Windows PowerShell **5.1+** · Claude Code **2.1.293+** (Haiku 5.5 için gerekli). Claude Code'u `claude update` ile güncelle. [googIeuser](https://github.com/googIeuser) tarafından geliştirilen bağımsız topluluk projesidir; Anthropic ile bağlantılı değildir.

## 1. Kurulum

[Claude Code'u kur](https://code.claude.com/docs/en/setup), `claude --version` komutunu kontrol et ve `claude auth login` ile abonelik hesabına giriş yap.

Repoyu indirip PowerShell'de kur:

```powershell
git clone https://github.com/googIeuser/Claude-Pro-Dev.git
Set-Location .\Claude-Pro-Dev
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

Ya da varsayılan daldaki bağımsız kurulum dosyasını kullan:

```powershell
irm 'https://raw.githubusercontent.com/googIeuser/Claude-Pro-Dev/main/install.ps1' | iex
```

İndirip çalıştırma komutu repo kodunu yürütür; tercih edersen `install.ps1` dosyasını önce indirip incele. Yönetici yetkisi, npm, Python ve ayrı MCP sunucusu gerekmez.

Deneysel Agent Teams desteğini kurulumda açmak için:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -EnableAgentTeams
```

Claude Code'u proje klasöründe yeniden başlat. Önce `/plugin`, ardından `/prodev` ile kontrol et.

## 2. Çalışma şeklini seç

| Yapacağın iş | Kullan | Ne olur? |
| --- | --- | --- |
| Küçük düzeltme veya günlük geliştirme | Normal promptun | Mevcut modelin kısa Pro Dev mühendislik talimatlarıyla çalışır. |
| Karmaşık değişiklik veya zor hata | `/prodev:advisor <görev>` | Oturum modelin uygulayıcı alt ajanı ve gerektiğinde salt okunur danışmanı koordine eder. |
| Modüllerde bağımsız işler | `/prodev:team <görev>` | Lider, ayrı görev ve dosya sahipliğiyle küçük bir yerel ajan ekibi koordine eder. |
| Kullanım veya tanılama | `/prodev`, `/prodev-doctor` | Yerel yardımcılar model isteği başlatmadan mevcut okumaları gösterir. |

### Danışman örneği

```text
/prodev:advisor Oturum yenileme hatasını düzelt. Kodu incele, yaklaşım için danışmandan görüş al, düzeltmeyi uygula ve etkilenen testleri çalıştır.
```

Ana oturumun, uygulama ve doğrulama için `prodev:executor` ajanını koordine eder; karmaşık işlerde `prodev:advisor` görüşü alınır. Takıldığı nokta veya zor son inceleme için ikinci danışma yapılabilir. Basit görevlerde danışman çağrısı atlanabilir. Koordinasyon ve delegasyon ek tüketim ve gecikme oluşturabilir.

Bu akış, [advisor yaklaşımını](https://platform.claude.com/docs/en/agents-and-tools/tool-use/advisor-tool) [Claude Code alt ajanlarıyla](https://code.claude.com/docs/en/sub-agents) uyarlar. Platformdaki gerçek Advisor Tool bir API özelliğidir; bu eklenti normal Claude Code ajanlarını kullanır. Danışman, kendisine aktarılan görev bağlamını ve ilgili dosyaları görür; konuşmanın tamamı otomatik aktarılmaz.

Ana oturum modelin korunur. Uygulayıcı/danışman seçimi aşağıda açıklanır. Gerçekte kullanılabilen modeller aboneliğine ve ortam kısıtlamalarına bağlıdır. Model veya ajan kullanılamıyorsa akış bunu ve kullandığı alternatifi dürüstçe belirtmelidir. Genel model ve effort ayarın korunur.

### Model ve düşünme seviyesi seçimi

Akış komutundan önce tercihlerini ayarla:

```text
/prodev-model executor haiku low
/prodev-model advisor opus high
/prodev:advisor Parser'ın boş girdi hatasını düzelt ve testlerini çalıştır.
```

İstersen uygulayıcı modeli görev başına akış seçsin:

```text
/prodev-model executor auto medium
/prodev:team Parser'ı incele ve ayrı dosyalarda testlerini geliştir.
```

`auto`, akışa model seçimi talimatı verir: dar ve net işler için Haiku; karmaşık, belirsiz veya çok dosyalı işler için Sonnet. Ayrı bir sınıflandırıcı, kota optimizasyonu veya model erişimi garantisi değildir. Seçilen model delegasyondan önce belirtilir.

| Seçim | Değerler |
| --- | --- |
| Rol | `executor` (uygulayıcı), `advisor` (danışman) |
| Model | `haiku`, `sonnet`, `opus`, `inherit` veya tam `claude-haiku-5-5`, `claude-sonnet-5-5`, `claude-opus-5-5` kimliği |
| Otomatik seçim | Yalnız uygulayıcı için `auto` |
| Düşünme seviyesi | `low`, `medium`, `high`, `xhigh`, `max`, `inherit` |

Seviye yazmazsan `inherit` olur; çağrının/host'un ayarı korunur. Modelde `inherit`, üst ajanın modelini kullanır. Kısa adları host çözer; tam kimlik belirli sürümü ister. `/prodev-model` tercihleri gösterir, `/prodev-model reset` Sonnet/Opus varsayılanına ve miras alınan seviyeye döner. Tercihler **bu oturumdaki yeni Pro Dev ajanlarına** uygulanır; yeniden yükleme/çıkışta silinir ve diğer ajanları etkilemez. Çalışan ajanların ayarı değişmez. Yeni model komutunda seviye yazmazsan o rolün seviyesi inherit'e döner.

Ana oturum için yerel `/model` ve `/effort` komutlarını kullan. Gerçek alt ajan modelini/seviyesini `/tasks` ile kontrol et; host politikası, ortam değişkenleri ve model sınırları öncelikli olabilir. Ayrı effort kontrolü için in-process ekipleri kullan; bölünmüş pencere davranışı host'a göre değişir. 5.5 modelleri uyarlanabilir düşünme kullanır; burada desteklenen bir alt ajan düşünmesini tamamen kapatma seçeneği yoktur. Yüksek seviye daha çok kota tüketebilir; aynı seviye adı farklı modellerde aynı düşünme miktarı demek değildir. [Resmî model ayarları](https://code.claude.com/docs/en/model-config).

### Agent Teams örneği

```text
/prodev:team Ayarlar ekranını ve testlerini geliştir. İki Sonnet ekip üyesine ayrı dosyalar ver, bulguları koordine et, sonunda birleşik değişiklikleri doğrula.
```

Ekip desteği **etkileşimli oturum başlamadan önce** açılmalıdır. Kurulum seçeneği kullanıcı ayarlarına `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` yazar. Sadece başlatacağın oturum için alternatif:

```powershell
$env:CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = '1'
claude
```

Ekibi, mesajları ve görevleri Claude Code yönetir. Pro Dev; tekrar kullanılabilen `prodev:executor` (Sonnet), `prodev:advisor` (salt okunur Opus) rollerini ve koordinasyon akışını sağlar. Varsayılan ekip küçüktür; aynı dosyadaki veya sıralı işler tek oturumda yürütülmelidir. Windows'ta varsayılan in-process görünüm için tmux gerekmez.

Ekip özelliği deneyseldir ve `claude -p` modunda çalışmaz. Özellik kullanılamıyorsa bu açıkça belirtilmelidir; normal alt ajanlar alternatif olabilir fakat yerel ekip olarak gösterilmemelidir. Güncel sınırlar ve kontroller için [resmî Agent Teams belgesine](https://code.claude.com/docs/en/agent-teams) bak.

**Advisor ve team akışları abonelik kotanı kullanır.** Ek ajanlar tüketimi artırabilir. Pro Dev tasarruf garantisi vermez, model erişimi açmaz ve hesap limitlerini yükseltmez.

## 3. Yerel yardımcı komutlar

Bu dokuz komut deterministiktir ve model turu başlatmaz. Yukarıdaki iki akış komutu model kullanır.

| Komut | İşlevi |
| --- | --- |
| `/prodev` | Kullanım, sayaçlar ve komut özeti. |
| `/prodev-doctor` | Yüklenen hook'lar, komut çakışmaları ve eksik okumalar. |
| `/prodev-queue add <metin>` | Görevi başlatmadan kuyruğa ekler. |
| `/prodev-queue list` / `draft <id>` / `remove <id>` / `clear` | Kuyruğu yönetir. `draft` prompt alanını doldurur; göndermek için Enter'a sen basarsın. |
| `/prodev-flow [mermaid]` | Gözlenen ajan etkinliği; ekip yöneticisi değildir. |
| `/prodev-next` | Basit sonraki adım önerileri. |
| `/prodev-checks [profile \| run <ad>]` | Doğrulama kayıtları veya açıkça seçtiğin proje kontrolü. |
| `/prodev-report` | Prompt ve araç gövdeleri olmadan JSON oturum metrikleri. |
| `/prodev-model [executor\|advisor <model> [seviye] \| reset]` | Yeni Pro Dev ajanlarının model ve düşünme tercihi. |
| `/prodev-filter on` / `off` | Uzun shell/MCP çıktısını kısaltmayı açar/kapatır. Çıktıdaki hassas veri maskelemesi açık kalır. |

5 saatlik ve 7 günlük kullanım okumaları Claude Code'dan gelir. Okuma yoksa `unknown` gösterilir. Bağlam doluluğu ve önbellek oranı ayrı ölçümlerdir; kalan kota değildir. Kuyruk, doğrulama kayıtları ve sayaçlar oturum bitince kaybolur.

Tanımlı kontroller için [örneği](docs/prodev.example.json) çalışma klasörüne `.prodev.json` olarak kopyala ve programları önce incele. Hiçbir kontrol otomatik çalışmaz. `/prodev-checks run <ad>` programı Windows kullanıcının yetkileriyle yürütür. Çalıştırma ve kayıt sınırları için [proje kontrollerine](docs/PROJECT-CHECKS.md) bak.

## Kurulum değişiklikleri ve kaldırma

- `prodev@claude-pro-dev-local` eklentisini kullanıcı kapsamına, `%USERPROFILE%\.claude\prodev\package` veya mevcut `CLAUDE_CONFIG_DIR` altına kaydeder.
- Ayarları ve önceki paketi yedekler; kurulum başarısız olursa geri yükler.
- Otomatik bağlam sıkıştırmayı kapatır, eski özel eşiği kaldırır. Yeniden başlat ve gerektiğinde `/compact` kullan.
- Model, effort, izinler, diğer ortam ayarları ve proje talimatlarını korur. `-EnableAgentTeams` ekip bayrağını açar; normal kurulum mevcut değerini korur.
- Başka marketplace'teki çakışan kullanıcı kapsamlı `prodev` eklentilerini kapatır; dosyalarını tutar.

Sürüm 0.3, eski komut/dosya adı guard'ını ve `/prodev-guard` komutunu kaldırır. Pro Dev anahtar kelimelere göre araç çağrısı reddetmez. Claude Code'un kendi izin kontrolleri çalışmaya devam eder. Çıktıda hassas veri maskelemesi korunur; eksiksiz gizlilik koruması sağlamaz. Filtre kanıt atlayabilir; gerektiğinde hedefli çıktı al veya filtreyi kapat.

Kapatmak veya kaldırmak için:

```powershell
claude plugin disable prodev@claude-pro-dev-local --scope user
claude plugin uninstall prodev@claude-pro-dev-local --scope user
```

Kaydedilen sıkıştırma ve ekip tercihleri kaldırma sonrasında kalır. Yedek ayarlarını geri yükle veya `settings.json` dosyasını düzenle: otomatik sıkıştırma için `autoCompactEnabled` değerini `true` yap; yeni oturumlarda ekipleri kapatmak için ekip ortam değişkenini kaldır. Shell'de açtıysan o bayrağı da temizle. Yedekler `.claude\prodev\backups` altında kalır.

## Geliştirme ve doğrulama

```powershell
claude plugin validate . --strict
claude plugin validate .\plugins\prodev --strict
claude plugin test .\plugins\prodev
powershell.exe -NoProfile -File .\tests\metrics.Tests.ps1
powershell.exe -NoProfile -File .\scripts\build-release.ps1
powershell.exe -NoProfile -File .\tests\release.Tests.ps1
powershell.exe -NoProfile -File .\tests\install.Tests.ps1
```

Gömülü dosyaları değiştirdikten sonra kökteki `install.ps1` dosyasını yeniden üret. Native testler model hesabı gerektirmez. Model davranışı ve etkileşimli ekipler, giriş yapılmış oturumda denenmelidir; statik doğrulama bunları kanıtlamaz. [Doğrulama kapsamı](docs/VERIFICATION.md) · [Mimari](docs/ARCHITECTURE.tr.md) · [Benchmark](docs/BENCHMARK.tr.md) · [Yayınlama](docs/PUBLISHING.md).

Eski pilot dosyaları v0.2'nin tarihsel kanıtlarıdır; advisor/team akışlarının sonucu değildir. Abonelik tasarrufu kanıtlanmış değildir.
