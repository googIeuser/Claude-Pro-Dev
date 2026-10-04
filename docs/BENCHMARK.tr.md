# Claude Pro Dev benchmark protokolü

Amaç: özelliklerin doğruluğunu, gerçek görevlerde verimliliği ve canlı UI deneyimini ayrı ölçmek. Daha kısa yanıt veya daha az araç çağrısı, iş eksik ya da yanlışsa başarı değildir.

Bu belge geniş ölçüm protokolüdür. Yanındaki CSV boş şablondur. v0.2'de ayrıca [çalıştırılabilir tek görevli pilot](../scripts/benchmark.ps1), [canlı smoke testi](../scripts/live-smoke.ps1) ve [gerçek pilot sonuçları](PILOT.md) bulunur. `-RunLive` her tekrar için hesabınızda iki model oturumu açar. Sonnet/low, süreç bazında izolasyon, ortak collector ve bağımsız altı kabul koşulu kullanılır. Abonelik tasarrufu kanıtlanmış değil.

## 1. Bugünkü kanıt

4 Ekim 2026'da Claude Code **2.1.289** üzerinde v0.2 native Mods testleri: **48 geçti, 0 başarısız**. Native engine dış cevapları kontrollüdür. Ayrıca gerçek CLI'de 16 helper sonucu, exit 0/7 süreçleri ve CMD terminalinde HUD/queue draft sınandı. Dört final model koşusu bağımsız kabulü geçti; araç sayısı aynı, maliyet tahmini B'de biraz daha yüksek. Gerçek hesap kotası ve üretim tasarrufu bu sonuçtan çıkarılamaz. v0.1'in [2.1.287/2.1.289 ve iki PowerShell CI koşusu](https://github.com/googIeuser/Claude-Pro-Dev/actions/runs/37221899516) geçti; güncel v0.2 sonuçları Actions'ta izlenir.

Tekrar çalıştırma, paket klasöründe:

```powershell
claude plugin test .\plugins\prodev
```

## 2. Özellik doğruluğu ve canlı kontroller

| Özellik | Deneme | Başarı ölçütü |
|---|---|---|
| Core kuralları | Ardışık context olayları, proje talimatlarıyla birlikte | Core bir kere bulunur; proje talimatları korunur |
| Output filtering | 5.000 satır log; başta, ortada, sonda tanımlı hata kanıtı | Tanımlı kanıt ve hata/exit bilgisi kalır; çıktı kısalır; kesilme belirtilir |
| Secret redaction | Sahte API anahtarı, parola, Bearer, yapılandırılmış secret alanı | Tanımlı sahte değerler model sonucunda görünmez; güvenli alanlar korunur |
| Safety guard | Bilinen tehlikeli komut dizgileri ve zararsız kontrol grubu | Bilinen riskli örnekler araç yürütmeden reddedilir; yanlış engellemeler ayrıca sayılır |
| Usage/cache HUD | Gerçek oturumda kaynak değerlerle karşılaştır | Context, cache ve kota ayrı gösterilir; eksik veri unknown olur |
| Queue | add → list → draft → remove | Taslak birebir gelir; kendiliğinden gönderilmez; çalışırken erişilebilir |
| Agent flow | Bir görevde açıkça istenmiş tek alt ajan | Başlangıç/bitiş, ad ve üst ajan ilişkisi gözlenen akışla uyuşur |
| Next steps | Hata, değişiklik ve queue durumları | İlgili 2–3 öneri çıkar; helper çağrısı model isteği üretmez |
| UI | Dar/geniş terminal, pencere boyutlandırma, diğer modlarla birlikte | Yazım ve gezinme çalışır; göstergeler okunur; diğer modların içeriği korunur |

Tehlikeli komutları bu benchmark için gerçek shell'de çalıştırma. Native testlerde komutlar yürütülmeden olay zincirine verilir. Secret örnekleri tamamen sahte olmalıdır. Bilinen örneklerde sıfır sızıntı, tüm secret türlerinin korunduğu anlamına gelmez; guard da bir shell parser veya güvenlik sınırı değildir.

Log testini yalnız ERROR sözcüklü örneklerle sınırlama. Keyword içermeyen önemli bir orta satır ve uzun stack trace de ekle; kayıp kanıtı başarısızlık olarak kaydet. Küçük çıktılar değişmemeli. Kaynak Read/Grep/Glob sonuçları kısaltılmamalı.

Canlı UI smoke testi için yeni, giriş yapılmış Claude oturumunda:

```text
/prodev
/prodev-queue add İncelenen değişikliğin test sonucunu kontrol et
/prodev-queue list
/prodev-queue draft 1
/prodev-queue remove 1
/prodev-flow
/prodev-flow mermaid
/prodev-next
```

Draft sonrasında Enter'a basmadan bir iş başlamamalı. Bu komutlar kendi başlarına model turu başlatmaz; taslağı gönderme ve agent-flow için istenen alt ajan görevi model kullanır. Mermaid çıktısında akış metninin doğruluğu değerlendirilir; v0.1 özel bir diagram renderer içermez.

## 3. Gerçek görev A/B pilotu

**A:** yeni Pro Dev kapalı. **B:** yeni Pro Dev açık. Eski çakışan prodev her iki tarafta da kapalı kalmalı. Diğer pluginler, izinler, proje talimatları, status line, model, effort ve fast-mode ayarı aynı kalmalı. `/prodev-filter off`, A koşulunun yerine geçmez; Core ve diğer hook'lar hâlâ çalışır.

Her koşu aynı başlangıç dosyalarının ayrı bir kopyasında, yeni oturumda başlasın. Kullanıcının asıl reposunu sıfırlama. Koşu başlangıcında plugin durumunu ve sürümü kaydet. Oturum içinde kapat/aç yapıp eski Core içeren context ile karşılaştırma yapma.

Görevleri ve başarı ölçütlerini sonuçları görmeden dondur:

| Görev | Örnek sabit talimat | Önceden belirlenmiş doğrulama |
|---|---|---|
| T1 — Hata düzeltme | Verilen hatayı ilgili dosyalarda bul, düzelt ve doğrula | Dışarıdan hazırlanmış hata reproducer'ı ve regresyon kontrolleri geçer; ilgisiz dosyalar değişmez |
| T2 — Uzun log teşhisi | Verilen test komutundaki başarısızlığın kök nedenini bul ve düzelt | 5.000 satırlı logun tanımlı hata kanıtıyla doğru teşhis yapılır; aynı kontrol yeşile döner |
| T3 — Küçük özellik | Bir parser veya CLI'ye tanımlı bir seçenek ekle ve doğrula | Önceden hazırlanmış kabul kontrolleri, sınır değerler ve eski davranış kontrolleri geçer |

Claude'un kendi yazdığı testler tek başarı hakemi olmamalı. Kontrollerin cevaplarını başlangıç talimatına koyma; değerlendirici koşudan sonra çalıştırsın. Sabit zaman sınırı ve sabit takip talimatı politikası belirle. Başarısız, yarıda kesilen veya manuel düzeltilen koşuları rapordan çıkarma.

**3 görev × 2 koşul × 3 tekrar = 18 koşu.** Bu 18 API isteği demek değildir; bir görev çok sayıda istek üretebilir. İlk bir A/B çiftinde ölçümün çalıştığını kontrol et. Bu pilot küçük bir örneklemdir; güçlü genelleme sağlamaz.

Sıra CSV'de dengelenmiştir: bazı çiftlerde A önce, diğerlerinde B önce. Yeni oturum sunucu cache'ini kesin olarak boşaltmaz. İlk tur ve devam turunun cache davranışını ayrı kaydet; gözlenmeyen cache durumunu cold diye etiketleme. Aynı sabit devam talimatı gerekiyorsa iki tarafta da kullan.

## 4. Ortak ölçüm kaynağı

B için `/prodev` tanı koymaya yardımcı olur. A tarafında bu komut bulunmadığı için ana karşılaştırmayı yalnız B HUD'una dayandırma. İki tarafta da aynı yerel ölçüm yolu kullanılsın.

Claude'un resmî [Monitoring belgesi](https://code.claude.com/docs/en/monitoring-usage#api-request-event), API olaylarında input, output, cache-read, cache-creation token alanlarını ve süreyi; tool olaylarında araç adı, başarı ve süreyi tanımlar. [Token counter](https://code.claude.com/docs/en/monitoring-usage#token-counter) alanında input, cache kategorileri hariç tutulur. Oturum kimliğiyle filtrele; ya olayları ya sayaç farklarını kullan, ikisini birden toplama. Tekrarlanan kümülatif sayaç snapshot'larını toplama.

Pilot için yerel console exporter veya yerel collector kullanılabilir. İki koşulda aynı ayarlar uygulanmalı; bu belge telemetry'yi açmaz veya dış servise veri göndermez. Prompt, ham API gövdesi ve araç içeriği kaydını açmak temel token/süre ölçümü için gerekmez. Tekrar okumaları aynı tanımla incelemek için yalnız sahte veri içeren benchmark reposunun oturum kayıtlarından yararlanılabilir.

Kaydet:

- Görev başarı durumu, dış kontrol sonucu ve kullanıcı müdahaleleri.
- Baştan sona geçen süre; model istek süresiyle ayrı tutulur.
- Başarılı API olayları ve hata olayları ayrı; retry bilgisi varsa ayrıca.
- Input, cache-creation, cache-read ve output token sayıları ayrı.
- Gerçekten yürütülen tool çağrıları; reddedilenler ayrı.
- Değişmeyen dosyada aynı parametrelerle yinelenen okuma ve aramalar.
- Başlatılan alt ajan sayısı; maliyet hesabında tüm oturumun agent/auxiliary istekleri.
- Filtre öncesi/sonrası sabit log uzunluğu ve korunan kanıtlar.
- Gerçek 5h/7d başlangıç/bitiş değerleri, mevcutsa; pencere reset bilgisi ve eşzamanlı hesap kullanımı.

Pro Dev'in repeat-read sayacı tanı amaçlıdır: okumayı engellemez; Bash/Write/Edit sonrası izleme kümesini temizler. Dolayısıyla B'nin HUD sayacını A'da farklı bir yöntemle sayılmış tekrarlarla doğrudan karşılaştırma. İki tarafın ortak tanımını kullan.

5h/7d yüzde farkı yardımcı gözlemdir. Ölçüm gecikmesi, reset ve başka oturumlar etkileyebilir. Context doluluğu veya cache oranından abonelik tasarruf yüzdesi üretme. Bildirilen API maliyet tahmini de abonelik faturası değildir.

## 5. Karar verme

Önce kalite kapısı: aynı kabul kontrolleri geçmeli, kritik kanıt kaybolmamalı, yeni hatalar ve secret sızıntıları olmamalı. Başarısız koşular toplam başarı oranında kalır; tasarruf hesabında başarılı işlerle karıştırılmaz.

Her görev için A ve B'nin üç koşusunun medyanını ve aralığını göster. İş başarısı oranını da yanında göster. Fark hesabı: `(A - B) / A × 100`; A sıfırsa yüzde hesaplama. Farklı büyüklükteki görevleri tek toplamla gizleme.

Önerilen pilot hedefi, **ölçülmüş sonuç değildir**: kalite korunurken gereksiz araç/tekrar okuma veya ayrı raporlanan token kategorilerinde yaklaşık %15–20 düşüş. Her kategoriyi birlikte değerlendir; input azalırken output veya başarısızlık artıyorsa bunu yaz. Sürede belirgin kötüleşme varsa kaynağını incele. Olumlu pilot sonucu daha fazla görevle doğrulanmalı.

Uzun logun karakter sayısının %95 azalması, tüm işin token veya abonelik tüketiminin %95 azalması değildir. Sadece sabit log üzerindeki metin küçülmesini gösterir. Helper gecikmesini birkaç gerçek etkileşimde ölç; native test sürelerini canlı UI gecikmesi olarak sunma.

Son raporda üç ayrı karar ver: **özellikler doğru**, **canlı kullanım çalışıyor**, **bu görevlerde verim artışı gözlendi/gözlenmedi**. Eksik ölçümü unknown olarak bırak; sıfır yazma.
