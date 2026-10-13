# Benchmark yöntemi — v0.3

[English](BENCHMARK.md)

Doğruluk, kullanılabilirlik ve verimliliği ayrı ölç. Daha kısa yanlış cevap başarısızdır. Abonelik tasarrufu kanıtlanmış değildir. [Eski pilot](PILOT.md) yalnız v0.2'yi kapsar; yeni ölçüm çıktıları fatura tahmini içermez.

## Yerel kontroller

Native testleri, ayrı kurulum/paket testlerini ve `scripts/live-smoke.ps1` dosyasını çalıştır. Sabit Core, komutun host izinlerine ulaşması, sahte sır maskelemesi, sınırlı loglar, gönderimsiz kuyruk taslağı, bilinmeyen kullanım ve sayısal/eski doğrulama kayıtlarını kontrol et. Yıkıcı görünen metinleri kontrollü araç olaylarıyla sına; test için gerçek komut olarak çalıştırma.

## Advisor senaryosu (giriş yapılmış oturum)

Bilinen hata ve bağımsız kabul koşulları içeren ayrı repo kullan. `/prodev:advisor <görev>` çalıştır. Seçilen uygulayıcı ve salt okunur danışmana ilgili bağlamın aktarıldığını, işin tamamlandığını ve bağımsız kontrollerin geçtiğini gözle. Basit görevde gereksiz danışma atlanmalı; ana model değişmemeli. `/prodev-model executor haiku low`, ayrı danışman effort'u, auto, inherit ve reset'i dene; gerçek değerleri `/tasks` ile kontrol edip model değişimlerini kaydet. Auto seçimini belirtmeli; sınıflandırma garantisi değil akış talimatıdır. Niyet yerine gerçek model ve danışma sayısını kaydet.

## Ekip senaryosu (yalnız etkileşimli)

Deneysel bayrağı açıp yeniden başlat. İki bağımsız modülde `/prodev:team <görev>` kullan. İsimli yerel ekip üyeleri, ayrı dosya sahipliği, mesajlar, varsa görev bağımlılıkları, tamamlanma, birleşik doğrulama ve kapanışı gözle. Kapalı bayrak ve headless alternatiflerini kontrol et. Normal alt ajanlar yerel ekip kurulduğunu kanıtlamaz. Terminali boyutlandır, çalışma sırasında yaz ve diğer modların görünümünü kontrol et.

## Kontrollü karşılaştırma

Üç görev seç: tekrarlanabilir hata, uzun logdan tanılama, küçük özellik. Kabul koşullarını model çalışmadan belirle. Temel kullanım, advisor ve ekip koşullarını yalnız uygun oldukları işlerde karşılaştır. Başlangıç dosyaları, talimatlar, model/effort, izin ve diğer eklentiler aynı olsun. Advisor/ekip koşulunda tüm kullanılan modelleri kaydet. Yeni dosya kopyaları kullan ve sırayı değiştir; koşul başına üç tekrar yalnız keşif ölçümüdür.

Tamamlanma, kabul, süre, ayrı input/output/cache-read/cache-write tokenları, araç/hata sayısı, ortak tanımla tekrar okumalar, danışmalar ve insan müdahalesini kaydet. Ana/alt ajan kullanımını ekle; kümülatif okumaları iki kez toplama. Eksik veri bilinmeyen kalır. Mevcut `scripts/benchmark.ps1 -RunLive` normal eklenti A/B örneğidir, advisor/ekip ölçümü değildir; hesabını kullanır ve açıkça seçilmelidir.

5h/7d okumaları destekleyici olabilir; reset, gecikme ve başka oturumlar küçük farkları çarpıtır. Bağlam/cache yüzdeleri kota tasarrufu kanıtlamaz. Görev başına medyan/aralık ve başarısızlıkları raporla. Özellik doğruluğu, canlı kullanılabilirlik ve ölçülen verimlilik sonuçlarını ayrı tut.
