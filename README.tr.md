# Claude Pro Dev

**Claude aboneliğinle daha düzenli geliştirme yapmanı sağlayan küçük bir Claude Code eklentisi.**

[English](README.md) · [Katkıda bulunma](CONTRIBUTING.md) · [MIT lisansı](LICENSE)

Pro Dev; kullanım göstergesi, yerel yardımcı komutlar, **Sonnet uygulayıcı + Opus danışman** akışı ve isteğe bağlı **Agent Teams** desteği ekler. Claude Code'a abonelik hesabınla giriş yapman yeterli. Bu eklenti için ayrı API anahtarı, API sunucusu, proxy veya ücretli API entegrasyonu gerekmez.

Sürüm **0.3.0** · Windows PowerShell **5.1+** · Claude Code **2.1.287+**. Deneysel ekip özellikleri için güncel Claude Code kullan. [googIeuser](https://github.com/googIeuser) tarafından geliştirilen bağımsız topluluk projesidir; Anthropic ile bağlantılı değildir.

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
| Karmaşık değişiklik veya zor hata | `/prodev:advisor <görev>` | Bu turu Sonnet yürütür; gerektiğinde salt okunur Opus danışmanından görüş alır. |
| Modüllerde bağımsız işler | `/prodev:team <görev>` | Lider, ayrı görev ve dosya sahipliğiyle küçük bir yerel ajan ekibi koordine eder. |
| Kullanım veya tanılama | `/prodev`, `/prodev-doctor` | Yerel yardımcılar model isteği başlatmadan mevcut okumaları gösterir. |

### Danışman örneği

```text
/prodev:advisor Oturum yenileme hatasını düzelt. Kodu incele, yaklaşım için danışmandan görüş al, düzeltmeyi uygula ve etkilenen testleri çalıştır.
```

Uygulayıcı kodu okur, karmaşık işlerde `prodev:advisor` ajanına danışır, sonra değişikliği kendisi uygular ve doğrular. Takıldığı nokta veya zor son inceleme için ikinci danışma yapılabilir. Basit görevlerde danışman çağrısı atlanabilir.

Bu akış, [advisor yaklaşımını](https://platform.claude.com/docs/en/agents-and-tools/tool-use/advisor-tool) [Claude Code alt ajanlarıyla](https://code.claude.com/docs/en/sub-agents) uyarlar. Platformdaki gerçek Advisor Tool bir API özelliğidir; bu eklenti normal Claude Code ajanlarını kullanır. Danışman, kendisine aktarılan görev bağlamını ve ilgili dosyaları görür; konuşmanın tamamı otomatik aktarılmaz.

Komut o tur için Sonnet ister; sonraki promptta oturum modelin geri gelir. Danışman Opus ister. Gerçekte kullanılabilen modeller aboneliğine ve ortam kısıtlamalarına bağlıdır. Model veya ajan kullanılamıyorsa akış bunu belirtip mevcut seçenekle dürüstçe devam etmelidir. Genel model ve effort ayarın korunur.

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

Bu sekiz komut deterministiktir ve model turu başlatmaz. Yukarıdaki iki akış komutu model kullanır.

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
