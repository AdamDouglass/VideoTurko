# AMD (RX 9070 XT): Vulkan and ROCm / AMD kartlar: Vulkan ve ROCm (EN + TR)

> **Automatic path / Otomatik yol:** `scripts\kur.ps1` now recognises the card class and installs the stock engine itself (`-Kuru` shows the choice, `-MotorTuru` overrides it). The manual steps and measurements below stay as they were measured. / `scripts\kur.ps1` artık kart sınıfını tanıyıp stock motoru kendisi kurar (`-Kuru` seçimi gösterir, `-MotorTuru` ezer). Aşağıdaki elle adımlar ve ölçümler ölçüldükleri gibi kalır.

**EN** Short note from one machine: RX 9070 XT, 16 GB, Windows 11. Label for everything below: [user-reported, PR #4]; each number is [measured] unless marked [read] or [guess]. The release engine of this repo is CUDA (`sm_61`) and does not run on AMD, so a stable-diffusion.cpp release build was used instead. No patch from `patches/` was applied. Quality settings are the fixed ones (6 steps, cfg 1, 640x384, seed 42, non-tiled VAE).

**TR** Tek makineden kısa not: RX 9070 XT, 16 GB, Windows 11. Aşağıdaki her şey [user-reported, PR #4] etiketlidir; her sayı [measured]'dir, aksi belirtilmedikçe ([read] ya da [guess]). Bu deponun hazır motoru CUDA (`sm_61`) olduğu için AMD'de çalışmaz; bunun yerine stable-diffusion.cpp'nin hazır sürümü kullanıldı. `patches/` içinden hiçbir yama uygulanmadı. Kalite ayarları sabit olanlardır (6 adım, cfg 1, 640x384, seed 42, parçasız VAE).

> **Community report / Topluluk bildirimi.** EN: maintainers have not measured this card; AMD is not an officially supported platform (the release engine is CUDA), there is no support guarantee, and the quality gate result on AMD output is unknown. TR: bakımcılar bu kartı ölçmedi; AMD resmî desteklenen platform değil (hazır motor CUDA), destek garantisi yok, AMD çıktısında kalite kapısı sonucu bilinmiyor.

## Engine / Motor

- stable-diffusion.cpp release `master-1106-532d2c1` (commit `532d2c1`) [read: GitHub release page].
- ROCm asset: `sd-master-532d2c1-bin-win-rocm-10.1.0-x64.zip`, 283,581,117 bytes, sha256 `b10fcc88f5a37adc1b63e0c1bd06fcbc8212340a68b96022b45d72e64c9e45a1` [read: GitHub release digest; the downloaded file matched].
- Vulkan asset: `sd-master-532d2c1-bin-win-vulkan-x64.zip`, 30,312,081 bytes [read].
- `amdhip64_7.dll` inside the ROCm zip reports file version `10.0.3684.0` [measured: file properties].
- This sd.cpp version already knows the `hyperflow-h3-flash-6` sigmas preset and the `minimax_h3_attn_chunk_budget` model argument [measured: the `--sigmas` presets are listed by `sd-cli --help`, and both builds accepted the model argument], so no patch was needed for the recipe in these runs.

## Command line / Komut satırı

Windows `cmd.exe` syntax (`set`, `^`); in PowerShell use `$env:HIP_VISIBLE_DEVICES='1'` and a backtick for line breaks. / `cmd.exe` sözdizimi; PowerShell'de `$env:HIP_VISIBLE_DEVICES='1'` ve satır sonu için ters tırnak.

```bat
set HIP_VISIBLE_DEVICES=1
sd-cli.exe -M vid_gen ^
  --diffusion-model <MODEL_DIR>\minimax_h3_fl2va_hyperflow_flash_14b-Q4_K_M.gguf ^
  --llm <MODEL_DIR>\qwen3vl_32b_minimax_h3-Q4_K_M.gguf ^
  --vae <MODEL_DIR>\minimax_h3_sol_vae_fp16.safetensors ^
  --audio-vae <MODEL_DIR>\minimax_h3_audio_vae_fp32.safetensors ^
  --prompt-file prompt.txt -W 640 -H 384 --video-frames 209 --fps 24 ^
  --steps 6 --sampling-method euler --sigmas hyperflow-h3-flash-6 --cfg-scale 1.0 ^
  --rng cpu --seed 42 -t 4 --flash-attn off,diffusion=on ^
  --model-args minimax_h3_attn_chunk_budget=0.03 ^
  --offload-to-cpu --mmap --backend te=cpu -o out.avi
```

- Vulkan: the same line without `HIP_VISIBLE_DEVICES` (the release Vulkan build). The Vulkan 56/141/209-frame runs in `docs/KART_PROFILLERI.md` used the default `minimax_h3_attn_chunk_budget=0.05`; see `docs/SIK_HATALAR.md` item 34 for why `0.03` was used later.
- Image-to-video: add `--init-img first_frame.png` (192 frames measured on ROCm).
- `HIP_VISIBLE_DEVICES`: on this machine the integrated GPU is ROCm device 0 and the RX 9070 XT is device 1 [measured: llama.cpp's `llama-bench --list-devices` with the variable unset listed both, iGPU first; with `HIP_VISIBLE_DEVICES=1` `sd-cli --list-devices` showed only the RX 9070 XT]. Set the number of your discrete card.
- No VAE tiling flags, as in `scripts/uret.ps1`.

TR: Vulkan için aynı satır, `HIP_VISIBLE_DEVICES` olmadan (hazır Vulkan sürümü). `docs/KART_PROFILLERI.md`'deki Vulkan 56/141/209 kare koşuları varsayılan `minimax_h3_attn_chunk_budget=0.05` ile yapıldı; `0.03`'ün neden kullanıldığı için `docs/SIK_HATALAR.md` madde 34. Görselden videoya: `--init-img ilk_kare.png` (ROCm'da 192 kare ölçüldü). Bu makinede tümleşik ekran kartı ROCm aygıt 0, RX 9070 XT aygıt 1'dir [measured: llama.cpp `llama-bench --list-devices`; `HIP_VISIBLE_DEVICES=1` ile `sd-cli --list-devices` yalnız RX 9070 XT'yi gösterdi]; kendi ayrık kartınızın numarasını yazın. VAE tiling bayrağı yok.

## Missing `hipblas.dll` / Eksik çıkan `hipblas.dll`

**EN** The sd.cpp ROCm zip does not contain `hipblas.dll`. An import scan of `stable-diffusion.dll` found `hipblas.dll` as the only DLL name that is neither in the zip folder nor in System32 [measured]. This machine has no AMD HIP SDK installed [measured: no `C:\Program Files\AMD\ROCm`, no hipblas DLL in System32 or on `PATH`], so nothing provided it.

**Source with a known version:** AMD's own portable Windows archive for ROCm 10.1.0, listed in the ROCm 10.1.0 install guide [read]: `https://stable.repo.amd.com/rocm/core/tarball/therock-dist-windows-gfx120X-all-10.1.0.tar.gz` (2,244,477,973 bytes; `gfx120X` is the RDNA 4 family that includes the RX 9070 XT). Nothing was installed: only its `bin\` folder was extracted (about 2 GB) and put on `PATH`, while `sd-cli.exe`, `sd-server.exe` and `stable-diffusion.dll` from the sd.cpp zip stayed in their own folder. Files used from it [measured: file properties]:

Maintainer note: the archive URL answered HTTP 200 with exactly 2,244,477,973 bytes on 2026-11-21 [measured, maintainers; no sha256 published for the archive itself]. Safer than adding the whole `bin\` folder to the system `PATH`: copy only `hipblas.dll`, `rocblas.dll` and the `rocblas\` and `hipblaslt\` folders next to `sd-cli.exe`, or set `PATH` only in the console you run it from.

| File | Version | Size (bytes) | sha256 |
|---|---|---|---|
| `hipblas.dll` | 3.7.0 | 820,176 | `93422e5f17589fbb8a1c26d7bc8e0d6fdca04730c465052186352859b5835fa7` |
| `rocblas.dll` | 5.7.0 | 21,095,888 | `2a6a98b547bf27b109f11f09b2473ffab80a2e2f1e7efd3e83e4ece1bd18ccbc` |
| folders `rocblas\` and `hipblaslt\` (kernel libraries, with `gfx1201` files) | | | |

- Result with only these official files (no other ROCm DLLs added): H3, 56 frames, finished without errors; `generate_video` 59.2 s (first run) and 54.0 s (second run, sampling 31.1 s), default sample prompt, budget 0.03 [measured]. The same 56 frames with the earlier mix below took 50.6 s (another prompt, so not an exact comparison).
- The DLL files are NOT in this repo; only names, versions, sizes and hashes.

Measurement condition only, not a recommendation: use the official files above. **Used for the timings in `docs/KART_PROFILLERI.md`:** the 209-frame and other timings in that row were measured with an earlier mix of files, version **unknown**: they have no version resource (file properties are empty) and a simple text search for version strings found nothing [measured]. Origin: the folder of a llama.cpp `b9592` HIP build on the same machine [read]; the exact zip they came from was not recorded (the HIP asset of that release is named `llama-b9592-bin-win-hip-radeon-x64.zip` [read: GitHub release page]). Added next to `sd-cli.exe`:

| File added | Size (bytes) | sha256 |
|---|---|---|
| `libhipblas.dll`, renamed to `hipblas.dll` | 716,696 | `6055254510d720213f6f835efb92f3d08dc49d5023dd0a14c00111771051a74e` |
| `rocblas.dll` | 41,072,536 | `5c001a3a4693f344899d36bc31c6202681fa467e9e25b127a42067c6732b3fc5` |
| `libhipblaslt.dll` | 6,012,312 | `9f97d95c3b7257efcab992914b4e1c1b3b71b0693a6ad5d61a8f3cbf08a96dee` |
| folders `rocblas/` and `hipblaslt/` | | |

**TR** sd.cpp ROCm zip'inde `hipblas.dll` yok. `stable-diffusion.dll`'in içe aktarma taramasında zip klasöründe de System32'de de olmayan tek DLL adı `hipblas.dll` çıktı [measured]. Bu makinede AMD HIP SDK kurulu değil [measured: `C:\Program Files\AMD\ROCm` yok, System32'de ya da `PATH`'te hipblas DLL'i yok], yani onu sağlayan bir şey yoktu.

**Sürümü bilinen kaynak:** AMD'nin ROCm 10.1.0 için kendi taşınabilir Windows arşivi (ROCm 10.1.0 kurulum kılavuzunda listeli [read]): yukarıdaki adres (2.244.477.973 bayt; `gfx120X`, RX 9070 XT'yi içeren RDNA 4 ailesidir). Hiçbir şey kurulmadı: yalnızca `bin\` klasörü açıldı (yaklaşık 2 GB) ve `PATH`'e eklendi; `sd-cli.exe`, `sd-server.exe` ve `stable-diffusion.dll` sd.cpp zip'indeki kendi klasörlerinde kaldı. Ondan kullanılan dosyalar yukarıdaki tabloda (`hipblas.dll` **3.7.0**, `rocblas.dll` **5.7.0**) [measured: dosya özellikleri]. Yalnız bu resmî dosyalarla (başka ROCm DLL'i eklenmeden) H3 56 kare hatasız bitti; `generate_video` ilk koşuda 59,2 sn, ikinci koşuda 54,0 sn (örnekleme 31,1 sn), varsayılan örnek istem, bütçe 0.03 [measured]. Aşağıdaki karışımla aynı 56 kare 50,6 sn sürdü (başka istem, tam kıyas değil). DLL dosyaları bu depoda YOK, yalnız ad, sürüm, boyut ve özet.

Bakımcı notu: arşiv adresi 2026-11-21'de HTTP 200 ve tam 2.244.477.973 bayt döndü [bakımcılar ölçtü; arşivin kendi sha256'sı yayımlanmamış]. Bütün `bin\` klasörünü sistem `PATH`'ine eklemek yerine daha güvenlisi: yalnız `hipblas.dll`, `rocblas.dll` ve `rocblas\`, `hipblaslt\` klasörlerini `sd-cli.exe`'nin yanına kopyalayın ya da `PATH`'i yalnız çalıştırdığınız konsolda ayarlayın.

Yalnız ölçüm koşulu, tavsiye değil: yukarıdaki resmî dosyaları kullanın. **`docs/KART_PROFILLERI.md`'deki sürelerde kullanılan:** o satırdaki 209 kare ve diğer süreler daha önceki bir dosya karışımıyla ölçüldü, sürümü **bilinmiyor**: sürüm kaynağı boş (dosya özellikleri), basit bir metin aramasıyla sürüm metni de bulunamadı [measured]. Kaynak: aynı makinedeki bir llama.cpp `b9592` HIP derlemesinin klasörü [read]; geldikleri zip'in adı kaydedilmemiş (o sürümün HIP dosyası `llama-b9592-bin-win-hip-radeon-x64.zip` adını taşıyor [read]). `sd-cli.exe`'nin yanına eklenenler yukarıdaki ikinci tabloda.

## Result / Sonuç

Times, VRAM peaks and prompts: see the RX 9070 XT row in `docs/KART_PROFILLERI.md`. / Süreler, VRAM tepeleri ve istemler: `docs/KART_PROFILLERI.md` içindeki RX 9070 XT satırı.
