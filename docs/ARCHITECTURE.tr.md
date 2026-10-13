# Mimari — v0.3.1

[English](ARCHITECTURE.md)

Kökteki marketplace tek `prodev` eklentisi sunar. Eklenti; native Mods modülü, iki ajan tanımı ve kullanıcının çağırdığı skill'lerden oluşur. Ayrı model istemcisi, sunucu, kimlik bilgisi deposu veya ağ isteği kodu içermez.

| Bileşen | Görevi |
| --- | --- |
| `hooks/register.js` | Host olayları, dokuz yerel komut, oturum model tercihleri, kullanım göstergesi, kuyruk ve kayıtlar |
| `hooks/policy.js` | Sabit mühendislik bağlamı, çıktı maskeleme/filtresi, kontrol profili yapı doğrulaması |
| `agents/advisor.md` | Opus; yalnız Read/Grep/Glob; stratejik öneri ve inceleme |
| `agents/executor.md` | Sonnet; verilen kapsamda uygulama |
| `skills/advisor/SKILL.md` | Ana modelin normal uygulayıcı alt ajanını ve gerektiğinde danışmanı koordine etmesi |
| `skills/team/SKILL.md` | İsimli ekip üyeleri ve ayrı dosya sahipliğiyle yerel ekip koordinasyonu |
| `skills/engineering/SKILL.md` | İsteğe bağlı mühendislik kontrol listesi |
| `scripts/install.template.ps1` | Yedekli kullanıcı kapsamlı kurulum ve isteğe bağlı ekip ayarı |
| `scripts/build-release.ps1` | İzin verilen dosyalardan ZIP ve bağımsız kök kurulum dosyası |

`session.start` host kullanımını bir kez okur ve yardımcıları ayrı ayrı kaydeder. Komut çakışması kalan kayıtları durdurmaz. `prompt.context` sabit Core bloğunu bir kez ekler, proje talimatlarını korur. `session.measure` kota/bağlam okumalarını tutar. `turn.complete` ajan/tur token ve sürelerini tekrar saymaz. Arayüz diğer modları korur.

`tool.call` host izin zincirine aktarır. Komut kelimesi veya hassas dosya adı nedeniyle ret yoktur; hook hatasında da host'a bırakılır. Sonuçlarda hassas veri maskelemesi ve isteğe bağlı uzun çıktı filtresi uygulanır. Değişen sonuçtan engine `ref` ve `text` kaldırılarak ham içeriğin yeniden gösterilmesi önlenir. Hata ve yakın kanıt önce korunur, kalan bütçeyle baş/son örneklenir; atlanan aralıklar belirtilir. Read/Grep/Glob kaynak metni ve metin dışı MCP blokları kısaltılmaz. Hook hatasında ham sonuç kalabilir; maskeleme güvenlik sınırı değildir.

Tekrar okuma sayacı başarılı parametreleri ajan başına gözler, okumayı engellemez. Edit, shell, MCP ve açıkça seçilen proje kontrolü imzaları temizleyip gözlenen revision'ı ilerletir. Dış değişiklikler görülmez. PASS sayısal exit zero gerektirir. Son 50 kayıt tutulur; sonraki gözlenen etkinlik kaydı eski yapar. Rapor şeması 2'dir; kaldırılan blocked sayacı, prompt ve çıktı gövdeleri içermez.

Advisor ve team skill'leri açıkça çağrılır ve host'un model altyapısını kullanır; deterministik yardımcıların içinde model isteği yoktur. Advisor skill'i ana modeli koordinatör olarak korur, uygulamayı uygulayıcıya devreder ve gerektiğinde salt okunur danışmana başvurur. Varsayılan Sonnet/Opus'tur; görev bağlamı açıkça aktarılır. Ajan adı verilmemesi, ekip açıkken de normal alt ajan kalmasını sağlar. Model erişimi abonelik ve host kısıtlamalarına bağlıdır.

`/prodev-model`, rol başına model/effort tercihini oturum belleğinde tutar. `skill.prompt`, iki akışa güncel tercihleri ekler; genel Core sabit kalır. `agent.spawn` yalnız açıkça seçilmiş Pro Dev modellerini uygular. Agent `tool.call` seçilen effort'u native engine'e aktarır; inherit çağrının mevcut değerini korur. Reset açık tercihleri bırakır. Diğer ajanlar, izinler ve genel ayarlar değişmez. Rapor istenen tercihleri gösterir; gerçek host değerinin garantisi değildir. Auto, akışa seçim talimatı verir ve görev için seçilen modeli korur; deterministik metin sınıflandırması yapmaz. Bölünmüş pencere effort davranışı host'a bağlıdır.

Team skill'i etkileşimli yerel Agent Teams gerektirir. Ekip klasörlerini, görevleri ve mesajları Claude Code yönetir; Pro Dev çalışma zamanı ekip ayar dosyası üretmez. Her üyeye hedef, kanıt, dosya sahipliği ve bağımlılıklar verilir. `/prodev-flow` yalnız gözlenen spawn/tur etkinliğini gösterir; kalıcı ekip durumu değildir.

Kurucu paketi hazırlar, ayar/marketplace yedeklerini alır, resmî CLI ile kurar, eski cache'i günceller, doğrular ve hata olursa geri döner. `-EnableAgentTeams` yalnız ekip ortam ayarını birleştirir; normal kurulum mevcut tercihi korur. Model ve izin ayarları korunur. Elle sıkıştırma varsayılanı devam eder. Gömülü kaynak değişince kök kurulum dosyası yeniden üretilmelidir.

Native testler gerçek Mods olay zincirinde dış araç cevaplarını kontrollü kullanır. Kurulum/paket testleri ayrı ayar klasörlerinde çalışır; mevcut kullanıcı profiline kurulum yapmaz. Etkileşimli advisor/team davranışı ayrıca canlı doğrulama gerektirir. [Doğrulama](VERIFICATION.md).
