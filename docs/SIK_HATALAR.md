# VideoTurko: Sik hatalar / Common pitfalls

Bu liste gercek kosulardan cikmistir (4 GB GTX 1050 Ti, stable-diffusion.cpp `sd-cli -M vid_gen`, MiniMax H3 HyperFlow Flash GGUF).
Her madde: **belirti**, **neden**, **kalici cozum**. Etiketler: [olctum] = bu projede olculdu, [okudum] = kodda/belgede goruldu, [tahmin] = dogrulanmadi.
This list comes from real runs. Each item: symptom, cause, lasting fix.

## A. Bellek ve kapi (VRAM)

1. **VRAM kapisi `blocks.0` agirlik hazirliginda dusuyor** (`segment 5/52 (blocks.0) failed during weight preparation`) [olctum]
   - Neden: yukleme kapisi `ihtiyac = bekleyen + eksik + marj`; kare sayisi buyudukce compute tamponu artar, tahliye yetmez.
   - Cozum: marj icin `SD_VRAM_MARGIN_MB=1` kullan. **`0` degeri "ayarsiz" sayilir ve 1024 MB'lik tuzaga duser** [okudum]. Kare tavani tablosu: `OLCUMLER.md`.
2. **`SD_CAPACITY_LOG` satirlari bir sonraki segmentin kapisini gosterir** (etiket kaymasi) [olctum]
   - `executing segment N` satirindan sonra yazilan CAPACITY satiri N+1'in kapisidir; olen kapiyi `segment K/52 (blocks.X) failed` satiri belirler.
3. **`SD_MLP_SET_OUT=1` bellegi azaltmaz, artirir** [okudum + olctum]
   - Hedef tensor "yaprak" oldugundan grafik basinda ayrilir ve tum blok boyunca canli kalir: 209 karede ~+342 MB (G209c'de +320 MB olculdu). Varsayilan kapali kalir; kanitli yama listesi `YAMALAR.md`.
4. **Bir yamanin tek basina kullanimi tepeyi buyutebilir**: `0006b` tek basina +121,5 MB; `SD_QKV_SET_OUT` ile birlikte kullan [olctum].
5. **Bellek tahmini yanlis girdiyle yapildi**: jeton sayisi N'yi formulle varsayma, logdaki `PEAK_DUMP` sekillerinden oku (209: N=15889); iki kosuyu karsilastirmadan once bayrak setini fark'la (ayni bayrak seti degilse "karsilastirilamaz" yaz) [olctum].

## B. VAE ve uretim

6. **Karoli VAE'ye sessiz dusus (`retrying with temporal tiling`)**: cikti gecersiz sayilir [olctum]. Cozum: DiT ve VAE'yi AYRI surecte kos (latent kaydet/yukle), `SD_VAE_NO_TILING_FALLBACK=1` ile dusus yerine hizli hata ver. 192 ve 209 kare bu yolla uretildi.
7. **Sure tavani (`-TavanDk`) kare sayisina gore ayarlanmadi**: 209 karede 6 DiT adimi bittikten sonra VAE sirasinda 50 dk tavanda olduruldu [olctum]. Kural: tavan = tahmini sure x 1,4; 209 icin en az 80 dk.
8. **Kopyalanan satirda latent/cikti yolu eski adda kaldi** (yeni kosu eski `*_latent.bin` uzerine yazdi) [olctum]: kopyada `-Deney`, `-Cikti`, `-OutDir`, `SD_VIDEO_LATENT_SAVE` ve `-TavanDk` ayri ayri dogrulanir.
9. **Zincirleme (`--init-img`) icin onceki videonun GERCEK son karesi kullanilmadi** (205. kare verildi, son kare 208'di): dikis SSIM 0,659 [olctum]. Cozum: kare sayisini `ffprobe` ile al, son kareyi cikar, orijinal videoyla 0,00 fark dogrula; birlestirirken onceki videoyu kirp, tekrar eden ilk kareyi at.
10. **Karolu VAE yedegi, adim/cfg/cozunurluk dusurmek kalite yolu degildir**: bu proje sabit ayar kullanir (6 adim, cfg 1, 640x384), bellek yamalari yalniz hesabin NEREDE yapildigini degistirir ve 56/141 kare kapilarinda bayt-aynidir.

## C. Kalite kapisi

11. **Ham gurultu olcusu sahne dokusuna baglidir**: gri karelerde her 8. karede ortalama |kare - 3x3 medyan| yuksek frekansli dokuyu (dal, cim, toz, yakin ucak) da sayar; Z3_175 klibi 1,86 ile RED aldi ama gozle ve zamansal olcuyle bozulma yoktu [olctum]. Ek olarak dokuya normalize N (medyan artik / Sobel doku gucu) kullanilir; esik kapiyi gevsetmez, yalniz RED nedenini raporlar. Hangi `doku_norm` surumunun hangi olcekte oldugunu belgeleyin (iki surumun degerleri farkli olcekte).
12. **Bayt kapisi bayrak setiyle yapilir**: bir yama 56 karede R0'a bayt-ayni gecmediyse reddedilir; kapi hangi env bayraklariyla kosulduysa uretim de o setle kosulmalidir. 158-209 kare icin dogrudan bayt referansi YOKTUR: "ayni bayrak ve ikili zinciri" dur [okudum].

## D. Kosucu ve Windows

13. **DLL bulunamadi (`STATUS_DLL_NOT_FOUND` / 0xC0000135)**: `cudart`/`cublas` DLL'lerini calistirma PATH'ine ekle [olctum].
14. **Cikis kodu bos "bitti" yazildi**: `Process` bitmeden `ExitCode` okundu; `WaitForExit()` sonrasi oku [olctum].
15. **Turkce kulturde ondalik virgul CSV'yi kaydirdi**: bicimlemede `InvariantCulture` kullan [olctum].
16. **Durdurma isareti (`DUR` dosyasi) kosan satiri da oldurur**: "kosan satir dogal bitsin" isteniyorsa isaret satir bitince konur; satirin ozet dosyasi (`ozet=`) olmadan koşucu cikis=0'i BITTI sayar, kanit yoktur: uretim ve kapi satirlarinda ozet zorunlu [olctum].
17. **Gozlemci sessizce sondu** (izleyicinin 30 dk tavani): alarm yazilir ama okuyan kalmaz; bitis saatini kaydet, sona erince yeniden kur, uzun islerde kalp atisi ve yedek is satiri kullan [olctum].
18. **Bellek baskisi**: sd-cli ~10-11 GB RAM kullanir (16 GB sistemde); uretim sirasinda diski tarayan agir islerden kacin, bellek kritik dusunce yardimci surecler durdurulur [olctum].
