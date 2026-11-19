# Kendin derle / Build it yourself (EN + TR)

EN: Advanced appendix. Normal users follow the 3-step Quick start in README.md; this page is for building the engine from source.
TR: Ek bolum (ileri duzey). Normal kullanici README.md icindeki 3 adimi izler; bu sayfa motoru kaynaktan derlemek icindir.

Placeholders: `<ROOT>` = a short neutral working directory, `<MODEL_DIR>` = where the model files live. Never put a personal path in scripts.

## 1. Hardware (measured on the reference machine)
- GPU GTX 1050 Ti 4 GB (Pascal, compute capability 6.1), driver 581.29, PCIe Gen3 x8; RAM 15.9 GB (about 9 GB usable); i7-7700HQ 4 cores/8 threads, AVX2 (no AVX-512).
- Put the models on an NVMe SSD (about 1.4 GB/s); on a 2.5-inch HDD (50-130 MB/s) the first steps are 15-25x slower.
- Pascal has no int8 tensor cores, BF16, FP8 or NVFP4: only GGUF K-quants through the dp4a MMQ path are used.

TR: GTX 1050 Ti 4 GB (Pascal, CC 6.1), sürücü 581.29, PCIe Gen3 x8, RAM 15,9 GB (~9 GB kullanılabilir), i7-7700HQ AVX2 (AVX-512 yok). Modeller NVMe'de olsun; HDD'de ilk adımlar 15-25 kat yavaş. Pascal'da int8/BF16/FP8 yok, yalnız GGUF K-nicem (dp4a MMQ).

## 2. Build
Visual Studio 2022 Build Tools (x64 tools), CMake + Ninja, CUDA 12.8 (nvcc). Build in a neutral short root (the `__FILE__` macro embeds source paths into binaries):
```
cmake -S <ROOT>/src -B <ROOT>/build -G Ninja -DCMAKE_BUILD_TYPE=Release -DSD_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=61 -DGGML_NATIVE=OFF -DGGML_BACKEND_DL=ON
cmake --build <ROOT>/build
```
Apply `patches/` onto the pinned stable-diffusion.cpp commit first. Put the CUDA runtime DLLs (cudart, cublas) on PATH, otherwise `sd-cli` exits with STATUS_DLL_NOT_FOUND. Before publishing a binary, scan it for personal paths (UTF-8 and UTF-16): the count must be 0.

TR: VS 2022 Build Tools + CMake/Ninja + CUDA 12.8; nötr kısa kökte derle; yamaları sabit commit'e uygula; cudart/cublas DLL'leri PATH'e; yayından önce ikiliyi kişisel yol için tara (UTF-8 + UTF-16 sıfır olmalı).

## 3. Models (not included)
HyperFlow-H3-Flash DiT (Q4_K_M), Qwen3-VL-32B text encoder (Q4_K_M), Sol video VAE (fp16), audio VAE (fp32). Download from the official pages with a pinned commit and verify sha256. The model license is the MiniMax H3 Community License (see README).


Model files (pinned commits, sizes and sha256 are in `scripts/modeller.json`; total 29.31 GiB). A newly downloaded model file is sha256-verified before it counts as done; a model file that already exists with the right size is skipped after a size check only, so run `modelleri_indir.ps1 -Dogrula` (or link with `-ModelKlasoru`, which hashes) for a full sha256 check [read: scripts/modelleri_indir.ps1]. Two separate ways:
- (a) Target folder `<MODEL_DIR>`: `kur.ps1` with env `VT_MODEL_DIR` (default `<ROOT>\model`), or `scripts/modelleri_indir.ps1 -Hedef <dir>` directly. Default `-Kuru` = report only; `-Dogrula` = size+sha256 check; `-Baslat -LisansKabul E|Y` = download. Pinned-commit HTTPS only, `.part` + Range resume, size+sha256 verified before the file is put in place; a corrupt `.part` is deleted with a warning and restarts from zero. A `DUR` file stops it cleanly.
- (b) Link an existing folder: `kur.ps1 -ModelKlasoru <existing_folder>`. For each of the four files in `modeller.json` the file there is hashed (sha256; reads up to ~29 GB, minutes on an HDD); if it matches, it is hard-linked (same drive) or copied into `<MODEL_DIR>` and NOT downloaded. A missing or non-matching file prints a warning and is downloaded normally. The existing folder is only read, never modified. [not tried: not yet run with the real model files]
- Disk: at least 32 GiB free on the model drive (29.31 GiB of files). Time: the 605 MB audio VAE took 66 s including sha256 (~9 MB/s here) [measured, small file only]; the full 29.31 GiB is roughly 55 min at that rate [tahmin], it depends on your line speed.
- License: the script shows `docs/LISANS_KABUL.txt` and does not download until you pass `-LisansKabul E` (TR) or `Y` (EN); the acceptance is stored next to the models.
TR: (a) Hedef klasor: `VT_MODEL_DIR` (varsayilan `<ROOT>\model`) ya da `modelleri_indir.ps1 -Hedef <klasor>`; indirme + sha256 dogrulama. (b) Var olan klasoru bagla: `kur.ps1 -ModelKlasoru <klasor>`; dort dosyanin sha256'si eslesirse hardlink (ayni surucu) ya da kopya ile baglanir, indirilmez; eslesmeyen uyari verip normal iner; kaynak klasore dokunulmaz. Modeller sha256 ile dogrulanmadan HAZIR denmez. Disk en az 32 GiB bos (29,31 GiB dosya); sure: 605 MB ses VAE 66 sn olculdu, tam indirme ~55 dk [tahmin], hat hizina bagli.
## 4. Run recipe
Full command (exact flags, as used by `scripts/hiz_kos3.ps1`; run `scripts/hiz_kos3.ps1 -Kuru` to print the exact command line without running it):
```
sd-cli -M vid_gen \n  --diffusion-model <MODEL_DIR>/minimax_h3_fl2va_hyperflow_flash_14b-Q4_K_M.gguf \n  --llm <MODEL_DIR>/qwen3vl_32b_minimax_h3-Q4_K_M.gguf \n  --vae <MODEL_DIR>/minimax_h3_sol_vae_fp16.safetensors \n  --audio-vae <MODEL_DIR>/minimax_h3_audio_vae_fp32.safetensors \n  --prompt-file <prompt.txt> -W 640 -H 384 --video-frames <N> --fps 24 \n  --steps 6 --sampling-method euler --sigmas hyperflow-h3-flash-6 --cfg-scale 1.0 \n  --rng cpu --seed 42 -t 4 --diffusion-fa \n  --model-args minimax_h3_attn_chunk_budget=0.05 \n  --offload-to-cpu --mmap --backend te=cpu \n  [--init-img <real last frame of the previous part>] --log-level debug -o <out>.avi
```
`<N>` follows 17k+5: 56, 73, 90, 107, 124, 141, 158, 175, 192, 209. Use NO `--vae-tiling` and NO `--temporal-tiling` (the non-tiled VAE is the quality reference; `hiz_kos3.ps1` always runs with the non-tiled VAE: `--vae-tiling` and `--temporal-tiling` are not added). `<out>.avi` is the output file (`-o`).
Measured: 56 frames about 560-590 s, 175 frames about 2300 s per pass; VRAM peak about 3.8-3.9 GB; RAM peak about 11.5 GB (close other applications).

TR: aynı komut; `hiz_kos3.ps1` her zaman karosuz VAE ile koşar (`--vae-tiling` ve `--temporal-tiling` eklenmez); karosuz VAE kalite referansıdır; sonraki parçalarda `--init-img` önceki parçanın GERÇEK son karesi. Ölçülen: 56 kare ~560-590 sn, 175 kare ~2300 sn; VRAM tepe ~3,8-3,9 GB; RAM tepe ~11,5 GB.

## 5. Checks and common mistakes
Quality gates are in the README. Common mistakes: (1) init image taken from the wrong frame (we once used frame 205 of 209 and the seam SSIM dropped to 0.66), (2) trusting the raw noise gate on dense textures (use the texture-normalised or sigma-HH gates), (3) missing DLLs on PATH, (4) running two GPU jobs at once (use a single GPU lock), (5) RAM pressure: with less than 16 GB RAM the model reads may fall into the page file.

TR: sık hatalar: yanlış kareden başlangıç görseli, dokulu sahnede ham gürültü kapısına güvenmek, DLL eksikliği, aynı anda iki GPU işi, RAM baskısı.

## 6. Privacy
No personal paths, user names, e-mail addresses or chat IDs in this repo; docs use `<ROOT>` and `<MODEL_DIR>`. No model weights or generated videos are included.
