# Kanitlar: bayt aynilik tablosu ve tekrar tarifi

Kural: bellek yamalari ve bayraklari ciktiyi DEGISTIRMEMELI. Referans (R0): 56 kare, tek parca (karosuz) VAE ile uretilen
`vae_karosuz.avi`, sha256 `0979f156d548169b...`. Her yama ve bayrak kumesi bu referansla karsilastirilir
(`scripts/bayt_kiyas.py <referans.avi> <aday.avi> --json cikti.json`; karar BAYT_AYNI ya da FARKLI).
Etiketler: [olctum] (= [measured]) kayitli kosu ve sha256, [tahmin] (= [guess]) denenmedi/dogrulanmadi; ayrica [okudum], [tasarim], [denenmedi]. Ortak sozluk: README, Evidence labels / Kanit etiketleri.
Not: tablodaki kosu kimlikleri (B56H4, B141K ve benzerleri) bizim yerel kosu kayitlarimizdir ve bu repoda DAGITILMAZ; okur ayni tarifi kosarak yeniden uretir ya da sayilari "bizim makinede olculdu" diye okur.

## Tablo

| Kapi | Kare | Ne karsilastirildi | Sonuc | Etiket |
|---|---|---|---|---|
| Marj 512 / 256 / 96 (B56Mk2, B56M4k, B56M96k) | 56 | dosya sha256, R0 ile | BAYT_AYNI | [olctum] |
| 0011 dahil (B56H4) | 56 | dosya sha256, R0 ile | BAYT_AYNI | [olctum] |
| 0012 derlemesi, bayraksiz (B56H7) | 56 | dosya sha256 | BAYT_AYNI | [olctum] |
| ATTN_SET_OUT + QKV_CHUNK 64 + QKV_SET_OUT + MLP_CHUNK 64, marj 96 (B56H8) | 56 | dosya sha256 | BAYT_AYNI | [olctum] |
| 0015 MLP_SET_OUT + 0016 (B56H9k, ikili `1af9d546...`) | 56 | dosya sha256, R0 ile | BAYT_AYNI | [olctum] |
| Uretim bayraklari, tam DiT (B141K) | 141 | latent sha256 == onceki uretimin latent'i (`E5D028F8632BE4FE`) | BAYT_AYNI | [olctum] |
| Ayri surec VAE, host cache 100 + `SD_VAE_EMBED_CUT` (F141Vh2K) | 141 | kare md5 + ses md5 (kap baytlari farkli) | BAYT_AYNI (kare+ses duzeyi) | [olctum] |
| Goruntu kosullu (i2v) bayraklar ACIK / KAPALI (I2VAC / I2VKA) | 56 | latent sha256 `4A670AE0C1A845E5` ve avi | BAYT_AYNI | [olctum] |
| 158, 175, 192, 209 kare | 158-209 | ayni bayrak ve ikili zinciri; DiT icin dogrudan bayt referansi YOK | dogrulanmadi | [olctum: referans yok] |
| 0017 DiT host cache (B56H10) | 56 | kosu `DUR_TA` ile 200 sn'de kesildi, cikti yok; B56H10b ile tekrarlandi (sha256 0979f156... = R0) | BAYT_AYNI (B56H10b) | [olctum] |
| 0015 + 0019 + 0020, MLP_SET_OUT + BLOCK_TAIL_FUSE acik (B56H10b, B56H11) | 56 | dosya sha256 (`0979f156d548169b...`), R0 ile | BAYT_AYNI | [olctum] |
| 0019 / 0020 141 kare (B141K2) | 141 | kosmadi | KANITSIZ (yalniz 56 kare kaniti), varsayilan kapali | [olctum] |

## Gorsel/olcu kapilari (bayt kaniti DEGIL)
`scripts/uretim_kapi.ps1 -Dizin <klasor> -Ad <ad> -Kare <N>`: kare sayisi, gurultu <= 1,5, orta akis > 0,05, log'da
tiling/retry/hata taramasi. Gurultu olcusu sahne icerigine baglidir (yogun cim/dal dokusu ham olcuyu yukseltir);
`-DokuNorm` bilgi amacli doku-normalize N'yi ekler (esik degistirmez).

## Tekrar tarifi [tahmin: temiz kokte denenmedi]
1. `scripts/derleme_sablonu.ps1` ile motoru derle (ortam: `VT_ENGINE_SRC`); yedek `bin_yedek` alinir.
2. 56 kare referans uretimi: `scripts/hiz_kos3.ps1 -Deney R0 -Karosuz -Kare 56 -MotorDizin <bin>` (varsayilan istem `docs/ornek_istem_R0.txt`; betik VARSAYILAN olarak karosuz VAE kullanir, karoli/yaklasik VAE uretimde yasaktir).
3. Ayni komutu bayraklar acik (`-Env SD_VRAM_MARGIN_MB=96,SD_ATTN_SET_OUT=1,...`) kosun; iki avi icin `sha256sum` ya da `bayt_kiyas.py`.
4. 141 kare icin `SD_VIDEO_LATENT_SAVE=<dosya>` ile latent kaydedip sha256 karsilastirin (`scripts/b141k_cmp.ps1` sablonu).
5. VAE ayri surec: `SD_VIDEO_LATENT_LOAD=<latent>` ile ikinci kosu, VAE bayraklariyla.
Ortam degiskenleri: `VT_ROOT`, `VT_PYTHON`, `VT_FFMPEG`, `VT_ENGINE_BIN`, `VT_ENGINE_SRC`, `VT_CUDA_BIN`.

## R0 ve latent referansi nasil uretilir (yabanci dogrulama) [tahmin: temiz kokte denenmedi]
Release ikilisi icin sonuc: 56 karede R0 ile bayt ayni (sha256 `0979f156d548169be03acd1a9d7617102a75333aa48a28d6bbfd1cc5fa3f604d`, kare md5 ve ses ayni), bayraksiz, cikis 0, 601 sn [olctum B56VT2, 2026-11-19; kapsam: yalniz sm_61 ve 56 kare, temiz kok kurulum testi degil; 141 latent ve 209 zinciri eski ikiliyle olculdu; 209 icin release ikilisi uret.ps1 ile ayrica kostu ve kapiyi gecti [olctum U209], latent bayt-ayni, kareler ve ses ayni, dosya sha konteynerden farkli [olctum U209/kiyas_f209v2.json]].
R0 dosyasi (`vae_karosuz.avi`) dagitilmaz; kendi R0'inizi uretirsiniz ve sonucu onunla karsilastirirsiniz:
1. R0 icin motor: stable-diffusion.cpp 32d516c + `01-taban-hiz-yamalari` (seri patches/SERIES.txt'in basi), seri yamalari (0001-0020) UYGULANMAMIS ve bayraksiz derleme.
2. Komut: `scripts/hiz_kos3.ps1 -Deney R0 -Karosuz -Kare 56 -MotorDizin <taban bin>` (istem `docs/ornek_istem_R0.txt`, tohum 42, 640x384, 6 adim, cfg 1, karosuz VAE). Cikti avi'nin sha256'si sizin R0'inizdir; bizim makinemizde `0979f156d548169be03acd1a9d7617102a75333aa48a28d6bbfd1cc5fa3f604d` (sm_61, GTX 1050 Ti).
3. Ayni komut, ayni istem ve tohum, bu repodaki 0006-0020 serisi uygulanmis motorla ve `Tekrar tarifi` bayraklariyla: sha256 R0 ile AYNI olmali. Beklenen: kendi R0'iniz ile esitlik; bizim hash'imizle esitlik yalnizca sm_61 (GTX 1050 Ti) uzerinde beklenir.
4. 141 kare latent referansi (`E5D028F8632BE4FE...`): yamali motorla `SD_VIDEO_LATENT_SAVE=<dosya>` ile latent kaydedin ve ayni sekilde yamasiz motorun latent'iyle karsilastirin (`scripts/b141k_cmp.ps1` sablonu); yamasiz motor 141 karede VAE asamasina kadar bu kartta tam kosamayabilir, bu yuzden bizim referansimiz onceki yamali bir uretimin latent'idir.
Dil: bayt aynilik sm_61 (GTX 1050 Ti) uzerinde bizim makinemizde dogrulandi; baska GPU/surucude bayt ayni olmayabilir [tahmin: karta bagimli].

## Model dosyalari (sha256, calistirdigimiz dosyalar) [olctum]
| Dosya | Boyut (bayt) | sha256 |
|---|---|---|
| minimax_h3_fl2va_hyperflow_flash_14b-Q4_K_M.gguf (HyperFlow Flash, Q4_K_M) | 9053456480 | `ee251661dffdebfa4a8c2555d2967b642f0efe9f2e350830a6e5c691935e23c3` |
| qwen3vl_32b_minimax_h3-Q4_K_M.gguf (metin kodlayici, Q4_K_M) | 18218065024 | `11e6efe70a57ce7f4838c47bdbd1a1c4b8ce10e2b7747f1b065990b70f4b05fc` |
| minimax_h3_sol_vae_fp16.safetensors (video VAE) | 3596335728 | `61eaab3d7ca1659f20bce4d02bbc5bd5e5af608c73328d30cda96c8dc4d033e0` |
| minimax_h3_audio_vae_fp32.safetensors (ses VAE) | 605254808 | `8e505d95dd1561d47abd43d4238fd40d9bb1ae9e147ed0a4cba778d76ae4db48` |
Bu degerler bizim yerel dosyalarimizindir; Hugging Face sayfasindaki sha256 ile karsilastirmak kullanicinin kontrolu (dosyalar bu repoda dagitilmaz).
