# RTX 3070 Ti 8 GB Masaustu Test Raporu (TR + EN)

> EN summary [user-reported]: contributor's runs on an NVIDIA GeForce RTX 3070 Ti 8 GB Desktop GPU (stock CUDA 12 engine, sm_86). Runs up to 192 frames in one pass passed the quality gate (peak 7456/8192 MiB); 175 frames peaked at 7699 MiB (margin 493 MiB). All runs produced valid video and audio, passed the quality gate (`KAPI GECTI`), and ran via `uret.ps1`. The [ölçtüm] labels below are the contributor's own measurements.

> Katkıcı ölçümü [kullanıcı bildirdi]. Model lisansı (`docs/LISANS_KABUL.txt`) kabul edilmiştir.

**Tarih:** 2026-11-23  
**Motor:** `kur.ps1`'in bu kart sınıfı için seçtiği stock motor (`stable-diffusion.cpp` `master-1106-532d2c1`, `win-cuda12-x64`, yama yok), `uret.ps1` üzerinden.

## Donanım ve sistem

| Donanım / Özellik | Değer |
|---|---|
| Kart | NVIDIA GeForce RTX 3070 Ti, 8 GB (8192 MiB), compute capability 8.6 |
| Sürücü | 621.24 |
| RAM | 32 GB (31,8 GB görünür) |
| Disk | NVMe SSD, modeller `<ROOT>\model` |
| Windows | 11 Pro, build 26300 |

## Kurulum ve Kontrol

`kur.ps1 -Kuru`: 0 HATA, 1 UYARI (`VT-W-GPU-DENENMEDI`) [ölçtüm]. Motor seçimi `stock_cuda12` (ampere, topluluk).

Kalite kapısı için Python ortamı (`opencv-python`, `numpy`) hazırdır.

`nvidia-smi` doğrulama satırı [okudum]:
```text
NVIDIA GeForce RTX 3070 Ti, 8192, 621.24, 8.6
```

## Koşular

Kalite ayarları hiçbir koşuda değiştirilmemiştir (6 adım, cfg 1, 640x384, karosuz VAE, tohum 42, 24 FPS).

Komut standardı:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\uret.ps1 -Istem <ISTEM> -Kare <N> -Cikti <OUT>\video.avi
```

VRAM: `uret.ps1`'in `nvidia-smi` tepe değeri (tüm kart, 5 sn örnek; masaüstü ekran yükü başlangıçta ~1,2–1,8 GB kullanmaktadır). Süre: `uret.ps1` duvar saati süresidir [ölçtüm].

| Koşu Türü | Kare | Süre (uret.ps1) | VRAM Tepe | Boş Marj | Kalite Kapısı Sonucu |
|---|---|---|---|---|---|
| Metinden Video (Sahne 1) | 90 | 162 sn (2,7 dk) | 7248 MiB | 944 MiB | GEÇTİ (gürültü 0,59, akış 1,08, N=0,037) |
| Metinden Video (Sahne 2) | 107 | 234 sn (3,9 dk) | 7494 MiB | 698 MiB | GEÇTİ (gürültü 0,62, akış 0,44, N=0,036) |
| Metinden Video (Sahne 1) | 175 | 281 sn (4,7 dk) | 7699 MiB | 493 MiB | GEÇTİ (gürültü 0,38, akış 0,73, N=0,029) |
| `-InitImg` Zincir (Sahne 2) | 175 | 326 sn (5,4 dk) | 7538 MiB | 654 MiB | GEÇTİ (gürültü 0,31, akış 0,31, N=0,026) |
| Metinden Video (Sahne 3) | 192 | 332 sn (5,5 dk) | 7444 MiB | 748 MiB | GEÇTİ (gürültü 0,34, akış 0,52, N=0,025) |
| `-InitImg` Zincir (Sahne 4) | 192 | 323 sn (5,4 dk) | 7456 MiB | 736 MiB | GEÇTİ (gürültü 0,34, akış 0,43, N=0,024) |

## Gözlemler ve Notlar

- **192 kareye kadar tam destek:** 8 GB VRAM'e sahip RTX 3070 Ti masaüstü kartında hem salt metinden video hem de `-InitImg` referanslı görselden video üretiminde 192 kareye kadar (8.0 saniye) tek aşamada sorunsuz ulaşılmıştır [ölçtüm].
- **Güvenli VRAM Marjı:** En yüksek VRAM tepe noktası 175 kare metin üretiminde 7699 MiB olarak ölçülmüş olup, tüm koşularda en az 493–944 MiB boş marj korunmuştur. Hiçbir koşuda bellek taşması (`VT-E-VRAM`) veya karolu VAE'ye düşme (`VT-E-TILING`) yaşanmamıştır [ölçtüm].
- **Masaüstü Yükü Toleransı:** Masaüstü ortamının ekran kartı üzerinde başlangıçta ~1,2–1,8 GB bellek kullanmasına rağmen 192 kareye kadar olan üretimler başarıyla tamamlanmıştır.
- **Kalite Kapısı:** Tüm çıktılarda ses akışı (`pcm_s16le`) doğrulanmış, ham gürültü ($N \le 1.5$) ve orta akış ($F > 0.05$) kabul bantlarında kalarak kapıdan başarıyla geçmiştir (`KAPI GECTI`).

## Kontroller

`python -I -X utf8 scripts/denetim.py --hizli` çıktısı: `SONUC: GECTI`
