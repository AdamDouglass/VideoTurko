# RTX 3060 Laptop 6 GB test raporu (TR)

> EN summary [user-reported, PR #14]: contributor's runs on an RTX 3060 Laptop 6 GB (stock CUDA 12 engine). 158 frames text-to-video passed the quality gate (peak 5122/6144 MiB); 175 frames stopped (`VT-E-TILING`); a 141-frame `-InitImg` run got gate RED on a painterly clip. Three setup frictions are listed below: the quality gate does not look in `.venv`, a model download timeout, and a fixed 32 GiB disk threshold when resuming. The [ölçtüm] labels below are the contributor's own measurements.

> Katkıcı ölçümü [kullanıcı bildirdi]. Koşuları Claude Code (yapay zekâ kod ajanı) katkıcının bilgisayarında çalıştırdı; katkıcı izledi ve çıktıları kontrol etti. Model lisansını (`docs/LISANS_KABUL.txt`) katkıcı kendisi kabul etti.

**Tarih:** 2026-11-23
**Repo:** `a009d2d` (koşuların yapıldığı commit)
**Motor:** `kur.ps1`'in bu kart sınıfı için seçtiği stock motor (`stable-diffusion.cpp` `master-1106-532d2c1`, `win-cuda12-x64`, yama yok), `uret.ps1` üzerinden.

## Donanım ve sistem

| | |
|---|---|
| Kart | NVIDIA GeForce RTX 3060 Laptop GPU, 6 GB (6144 MiB), compute capability 8.6 |
| Sürücü | 610.88 |
| İşlemci | AMD Ryzen 7 6800H |
| RAM | 32 GB (31,3 GB görünür) |
| Disk | NVMe SSD, modeller `<ROOT>\model` |
| Sayfa dosyası | 8–48 GB (koşuların çoğu), sonra 32–48 GB |
| Windows | 11 Pro, build 26200 |

## Kurulum

`kur.cmd -Kuru`: 0 HATA, 2 UYARI (`VT-W-GPU-DENENMEDI`, `VT-W-PY`) [ölçtüm]. Motor seçimi `stock_cuda12` (ampere, topluluk).

Kalite kapısı için Python ortamı, kurulumun önerdiği gibi kökte kuruldu: `py -3 -m venv <ROOT>\.venv` + `opencv-python numpy` (cv2 5.1.0, numpy 2.5.5).

Karşılaşılan sorunlar:

1. **Kalite kapısı `.venv`'i bulamıyor** [ölçtüm]. `kur.ps1` ve `uret.ps1` kökteki `.venv\Scripts\python.exe`'yi buluyor, ama `uret.ps1`'in çağırdığı `scripts\uretim_kapi.ps1` yalnız `VT_PYTHON`'a ya da `python`'a bakıyor (satır 10) [okudum]. Sonuç: video üretiliyor, kapı `ModuleNotFoundError: No module named 'cv2'` ile çalışmıyor, `uret.ps1` çıkış 6 (`VT-E-PY`). `VT_PYTHON=<ROOT>\.venv\Scripts\python.exe` verince kapı çalıştı. Öneri: `uretim_kapi.ps1` de `uret.ps1` gibi önce `.venv`'e baksın.
2. **Model indirmesi zaman aşımında kurulum duruyor** [ölçtüm]. 18,2 GB'lık metin kodlayıcıda `HttpWebRequest` okuması `The operation has timed out` verdi, `modelleri_indir.ps1` çıkış 1, `kur.ps1` durdu. `.part` korundu ve devam ettirilebildi.
3. **Devam ederken disk eşiği** [ölçtüm]. Yalnız 2,71 GiB indirme kalmışken `kur.ps1` ve `modelleri_indir.ps1` boş alan 26,9 GiB < 32 GiB diye `VT-E-DISK` ile durdu (eşik eksik bayta değil sabit 32 GiB'a bakıyor). `modelleri_indir.ps1 -MinBosGiB 8` ile devam edildi, sonra `kur.ps1 -Adim kontrol`.
4. Bilgi: indirme hızı bu hatta tek bağlantıyla ~11 MB/sn idi [ölçtüm].

5 karelik kontrol: `HAZIR`, 62 sn, VRAM tepe 5269 / 6144 MiB [ölçtüm].

## Koşular

Kalite ayarları hiçbir koşuda değişmedi (6 adım, cfg 1, 640x384, karosuz VAE, tohum 42). Komut:

```
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\uret.ps1 -Istem <ISTEM> -Kare <N> -Cikti <OUT>\video.avi
```

VRAM: `uret.ps1`'in `nvidia-smi` tepe değeri (tüm kart, 5 sn örnek; ekran başlangıçta ~510 MiB kullanıyor). Süre: `uret.ps1` duvar saati / motorun `generate_video` süresi [ölçtüm].

| Koşu | İstem | Kare | Süre (uret / motor) | VRAM tepe | Kapı |
|---|---|---|---|---|---|
| R0 | `docs/ornek_istem_R0.txt` | 56 | 104 sn / 94,2 sn | 5288 MiB | GEÇTİ (gürültü 0,70, orta akış 3,59) |
| Metin, kendi istemi (illüstrasyon) | vapur sahnesi | 141 | 210 sn / 201,5 sn | 4914 MiB | GEÇTİ (1,49 / 0,62) |
| Metin, kendi istemi (gerçekçi) | Balat sokağı, kedi | 141 | 206 sn / 192,4 sn | 5455 MiB | GEÇTİ (1,25 / 0,22) |
| Metin, aynı istem | Balat sokağı, kedi | 158 | 248 sn / 231,8 sn | 5122 MiB | GEÇTİ (1,23 / 0,17) |
| Metin, aynı istem | Balat sokağı, kedi | 175 | 43 sn, hata | – | – |
| `-InitImg` (el boyaması ilk kare, 640x384) | vapur sahnesi | 141 | 267 sn / 253,0 sn | 5456 MiB | RED (gürültü 1,95 / 0,92) |

Notlar:

- **175 kare sığmadı** [ölçtüm]: `[E] minimax_h3 segment 5/51 (minimax_h3.blocks.1) failed during weight preparation`, `uret.ps1` `VT-E-TILING` ile durdu. Bu kartta ve bu ekran yüküyle yalnız metinden üretimde sınır 158 kare (6,6 sn).
- **RED klibi** [ölçtüm]: `DOKU_NORM` N=0,051 (temiz bant 0,034–0,052, `docs/KAPILAR.md` 3), `SON_KARE` eşik aşılmadı. Klip izlendiğinde bozulma görülmedi; yüksek okuma fırça dokusu ve parlayan sudan geliyor olabilir [tahmin]. GTX 1650 satırındaki el boyaması RED gözlemine benziyor.
- **RAM** [ölçtüm]: motor ağırlıkları RAM'de tutuyor (`total params memory size = 30040.19MB (VRAM 0.00MB, RAM 30040.19MB)`). Sistem genelinde kullanılan fiziksel bellek koşu sırasında 31,2 GB'a çıktı, commit yalnız ~11,4 GB (mmap). 16 GB RAM'li makinede de çalıştığı bildirildi (RTX 3060 12 GB satırı, PR #11), yani bu sayı gereksinim değil, eldeki RAM'in dolması.
- Uyarı çıkmadı: `VT-W-VRAM-MARJ` (≤296 MiB boş) hiçbir koşuda tetiklenmedi; en dar marj 688 MiB.

## Ayrı bölüm: başka kurulumla H3 [kullanıcı bildirdi, farklı kurulum ve ayarlar]

Bu bölüm VideoTurko ölçümü değildir; karşılaştırma için, aynı kartta başka bir proje (Diffusers tabanlı MiniMax H3, int8 transformer, 4-bit Qwen3-VL-4B metin kodlayıcı, Turbo LoRA 4 adım) ile yapılan denemedir:

- 1152x640, 7 sn sesli çekim (ilk + son kare): ~13–15 dk; Görev Yöneticisi'nde VRAM 5,6 / 6,0 GB.
- Yukarıdaki RED klibiyle aynı ilk kare, 1152x640, 6,6 sn (yalnız ilk kare): 736 sn.
- Bu kurulumda sunucu açılırken sayfa dosyası 8 GB'ta `torch_cpu.dll` erişim hatasıyla çöktü, 32 GB'ta açıldı. VideoTurko koşuları 8 GB sayfa dosyasıyla sorunsuz.

## Kontroller

Bkz. PR açıklaması (`python -I -X utf8 scripts/denetim.py --hizli`).
