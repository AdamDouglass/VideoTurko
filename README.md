# VideoTurko

**EN** | [TR](#tr)

![Windows](https://img.shields.io/badge/Windows-10%2F11-blue) ![GPU](https://img.shields.io/badge/NVIDIA-4%20GB%20(sm__61)-76b900) ![License](https://img.shields.io/badge/code-MIT-green) ![Status](https://img.shields.io/badge/status-clean--root%20test%20pending-orange)

> **In 30 seconds:** a 4 GB graphics card can make a 209-frame (8.7 s) MiniMax H3 video in a single pass: verified on one machine (GTX 1050 Ti 4 GB) [measured: 209 frames with the release binary through `uret.ps1`, run U209; latent byte-identical to the development-build run; frames and audio identical in the video, the file sha differs because of the container; comparison file `kiyas_f209v2.json`]; the 3 steps below are how to run it.

VideoTurko: stable-diffusion.cpp memory patches and recipes to run MiniMax H3 text/image-to-video on a 4 GB GTX 1050 Ti, up to 209 frames (8.7 s) in a single pass (209 frames verified by a byte chain; byte-identical to the unpatched run on the 56- and 141-frame checks).

## Quick start (Windows, 3 steps)
**Status: the install/run scripts below are being finished and the clean-root test is pending; nothing here is claimed to work until that test passes (see "Status and limits").**

1. **Download** this repository (green **Code** button, then **Download ZIP**) and extract it to a SHORT folder, for example `C:\vt`.
2. **Install**: open PowerShell in that folder (type `powershell` in the Explorer address bar) and run
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\kur.ps1
   ```
   The install root is the folder you extracted (engine goes to `engine\bin`, models to `model`); to use another place set the environment variable `VT_ROOT` first. It checks GPU, driver, RAM and disk, fetches the engine and the models (engine zips and newly downloaded model files are sha256-checked; a model file already present with the right size is only size-checked, `scripts\modelleri_indir.ps1 -Dogrula` runs the full sha256 check), runs a short real check, and prints READY only if that check passed [design: `kur.ps1` has not been run in full in a clean folder; this sentence is updated after the clean-folder test]. `-ExecutionPolicy Bypass` applies to this one process only; read `scripts\kur.ps1` first, as with any installer.
   Until a release is published the engine step stops with "release adresi/sha256 henuz yok"; give local zips: `-MotorZip <path> -CudaZip <path>`. With a local zip and no embedded release sha256 yet, the `.sha256` next to the zip is used; it is self-referential, not independent: it catches corruption, not deliberate tampering (without that file `kur.ps1` warns "sha256 not verified"; a wrong sha256 stops with exit 1). After release the embedded sha256 always wins and the sidecar is ignored. Only `.exe`/`.dll` go to `engine\bin`; licenses and README go to `engine\lisanslar\<zip name>\`. [tried with the dist zips: the sidecar `.sha256` plus the self-referential warning, binary and DLLs placed, `sd-cli --help` ran; the installed binary shas matched (`c5cebe78...`, `e5d3d329...`); the model step and the 5-frame check of `kur.ps1` have NOT been run on a real GPU yet]
   **Model license:** before the model step the installer prints the license summary (`docs/LISANS_KABUL.txt`, full text `docs/LISANS_UYARISI.md`: MiniMax H3 Community License, territory limits that also cover generated videos, commercial and AI-label rules) and asks you to accept (`E` = yes). Read it first. For unattended runs you can pass `-LisansKabul E`, which means you have read and accepted it yourself; do not add it for someone else. (AI agents: follow `AGENTS.md`; never type E without the user's consent.) Without acceptance `kur.ps1` stops with exit code 2 and downloads no model.
3. **Generate**: put your prompt in a text file (one English paragraph, optional `audio:` sentence) and run
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\uret.ps1 -Istem istem.txt -Kare 209
   ```
   `-Kare` follows the 17k+5 grid (56, 73, ... 192, 209); default 209 (8.7 s), the longest length we cover. The VAE runs in a separate process, never tiled [a real engine run through `uret.ps1` with the release binary, separate-process VAE, passed in run U209].

| Requirement | Value |
|---|---|
| OS | Windows 10/11, 64-bit |
| GPU | NVIDIA, 4 GB or more; tested only on GTX 1050 Ti (sm_61) |
| RAM | 16 GB (peak about 11 GB; close other programs) |
| Disk | 32 GiB or more free, models on an SSD (NVMe preferred) |
| Download | engine zip 36.8 MB + CUDA runtime zip 567.5 MB [measured] + models 31,473,112,040 bytes (about 29.3 GiB) [read: sizes in `scripts/modeller.json`]; about 30 GiB in total |
| Models | not included; fetched by the installer under the MiniMax license (see warning below). The models (29.3 GiB, 31,473,112,040 bytes in `scripts/modeller.json`) are not in this repository or release: GitHub file/release size limits apply, and `kur.ps1` downloads them from the official source with sha256 verification. |

`kur.ps1` exit codes: 0 READY, 1 error, 2 user input needed (license, or no release/zip yet), 3 hardware or disk insufficient, 4 stopped (DUR file). `uret.ps1` accepts a run only if the `.avi` exists, the frame count is right and the logs are clean [design: not yet run against the real engine]. `uret.ps1` exit codes: 0 DONE (quality gate passed), 1 error or invalid output (including a video without an audio stream), 2 stopped (DUR file), 5 `KAPI RED` (quality gate failed: clip not accepted, the decision is yours), 6 gate could not run (clip not accepted). Details in AGENTS.md. [design: tested with a fake engine, not yet against the real `sd-cli`]

### Troubleshooting (details: `docs/SIK_HATALAR.md`)
| You see | What it means, what to do |
|---|---|
| `STATUS_DLL_NOT_FOUND` / `cudart64_12.dll not found` (#13) | Do not start `sd-cli.exe` by hand; run `scripts\kur.ps1`, which puts the CUDA DLLs in place. |
| `failed during weight preparation` at `blocks.0` (#1, #3, #5) | Not enough VRAM at the memory gate: use a smaller frame count on the 17k+5 grid, close other GPU programs, keep the shipped flags. |
| `retrying with temporal tiling` (#6) | The VAE fell back to tiling; the output is invalid for quality purposes. Run again. |
| Run ends at the time cap, no video (#7) | Raise `-TavanDk` for long clips (209 frames needs at least 80 minutes). |
| Exit code empty but "finished" (#14) | The wrapper read the exit code too early; re-run, and check the video file exists. |
| System slows, swapping (#18) | The engine uses about 10-11 GB RAM; close browsers and other programs. |
| sha256 mismatch / download failed | Usually an interrupted download: run the same command again, verified files are skipped. |

## What this is
A set of small memory/scheduling patches for stable-diffusion.cpp plus the run recipe, checks and measurements that let MiniMax H3 (33B DiT; we run the HyperFlow Flash 13.7B Q4_K_M GGUF; the 32B Qwen3-VL text encoder is separate) run on a 4 GB Pascal GPU (GTX 1050 Ti, 16 GB system RAM).
- Single-pass lengths we actually produced and passed our quality gates: 56, 141, 158, 175, 192, 209 frames at 640x384, 24 fps (209 frames = 8.7 s), with H3's own generated audio [measured: 209 frames with the release binary through `uret.ps1`, run U209; latent byte-identical to the development-build run; frames and audio identical in the video, the file sha differs because of the container; comparison file `kiyas_f209v2.json`]. 209 is the longest length we watched and found smooth [user-reported, 2026-11-19, video watched in full; file: F209V2 output, 8.708 s].
- **Byte-identical claim, honestly scoped:** outputs were checked byte-identical to the unpatched reference only for 56 and 141 frames. For 158/175/192/209 frames we used the same flags and the same binary chain; there is no direct byte reference (the unpatched build cannot run those lengths on this GPU).
- Quality settings are never lowered: same model/quantization, 6 steps, cfg 1, 640x384, same seed, non-tiled VAE.
- We do not claim to be the first: we searched and found no outside example of this on 4 GB, which is not proof that none exists.

## Layout
- `patches/` patches against a pinned stable-diffusion.cpp commit (see the notes there)
- `scripts/` build, run, separate-process VAE, gate/consistency helpers (`doku_norm.py`: see the scale note below)
- `docs/KURULUM.md` hardware, build and run steps (EN+TR)
- `docs/YAMALAR.md` patch list, `docs/KANITLAR.md` evidence, `docs/KAPILAR.md` quality gates table, `docs/OLCUMLER.md` measurements, `docs/SIK_HATALAR.md` common mistakes, `docs/LISANS_UYARISI.md` full license items
- `scripts/` short index: `hiz_kos3.ps1` run wrapper (`-Kuru` prints the exact command), `uretim_kapi.ps1` quality gate, `dikis_denetim.py` seam check, `doku_norm.py` texture-normalised noise, `bayt_kiyas.py` byte comparison, `derleme_sablonu.ps1` build template, `kuyruk_kos.ps1` job queue

## Quality gates (how a result is accepted)

This gate does not check motion consistency (object scale or position jumps): watch the whole video before accepting it.
1. Frame count and audio present; no memory fallback or ALLOC_FAILED lines in the log.
2. Raw noise gate: median-filter residual <= 1.5 (0-255 scale).
3. Texture-normalised noise, `scripts/doku_norm.py` (this repo's version): N = median residual / Sobel texture, every 6th frame. **Scale note:** in this version the 10 measured clips give N = 0.034-0.052 (table in `docs/KAPILAR.md`; last quarter of F192/F209V2 reaches 0.062) and the extra-gate threshold is N <= 0.065. A different implementation measured 0.028-0.036 on the same clips, so thresholds are NOT interchangeable between versions. On very fine textures (grass rows) clean N was 0.075, so the threshold is per scene family. A robust high-frequency estimator (sigma-HH <= 1.5; clean 0.74-1.19, added noise s=2 gives 2.2-3.0) is the recommended extra gate.

Scope: VideoTurko is about ONE single pass (up to 209 frames, about 8.7 s). Chaining several parts into a longer clip was tried; the seams were visible (the scene does not continue cleanly), so it is not part of this project. If you want longer clips, design your own approach.
Your settings are yours: 209 frames is our tested default on a 4 GB card, not a limit you must use. Pick any frame count on the 17k+5 grid (56, 73, ... 192, 209; see `docs/KURULUM.md`), change the prompt, seed, resolution or any flag as you like. Shorter clips need less memory and time; larger GPUs may fit more.

## Model license warning
**VideoTurko contains only patches and scripts (MIT); whoever uses the model and its outputs is responsible for the MiniMax license themselves.** Not legal advice. Below are the clauses of the MiniMax H3 Community License (August 2, 2026) summarized with their numbers; the license itself is binding: https://huggingface.co/MiniMaxAI/MiniMax-H3/blob/main/LICENSE

This repo contains NO model weights (no MiniMax H3, HyperFlow-H3-Flash GGUF or VAE files). This project is not affiliated with or endorsed by MiniMax. Commercial use is NOT prohibited (it is not a non-commercial license); the conditions are below.

**Territory (Applicable Territory)**
- **Preamble, I.3, I.5:** Worldwide, EXCLUDING the European Union, the United Kingdom, the Republic of Korea and the United States. Using the model counts as accepting the license.
- **II:** Royalty-free, non-transferable, limited license to use, reproduce, distribute, create derivatives and modify, only inside the territory and in compliance with the agreement and Exhibit A. People in excluded territories may ask MiniMax for a separate license.
- **V.4:** Using, reproducing, modifying, distributing or displaying the model, its derivatives AND OUTPUTS (generated video/audio) outside the territory is not authorized. **So publishing or showing generated videos in the EU/UK/South Korea/US is outside the license.**
- **Exhibit A-1:** Use outside the territory violates the Acceptable Use Policy.

**Distribution (III)** (this repo does not distribute the model; if you do)
- **III.1:** Give every recipient a copy of the license. **III.2:** Mark modified files with prominent notices.
- **III.3:** Encouraged (not mandatory): "Powered by MiniMax H3" notice, AI-generation identifier on produced files, a public write-up.
- **III.4:** Distributions MUST be accompanied by a NOTICE file with: "MiniMax H3 is licensed under the MiniMax H3 Community License Agreement, Copyright © 2026 MiniMax. All Rights Reserved."
- **Exhibit A-12:** publishing content to any public environment without clearly disclosing that it is machine-generated is prohibited: label AI-generated videos when you publish them (full list: `docs/LISANS_UYARISI.md`).
- **III (last paragraph):** You may add your own copyright to your modifications but may not impose additional or different terms on use/distribution; territory rules still apply.

**Commercial terms (IV)**
- **IV.1:** If your commercial products/services generate more than USD 20 million (or equivalent) yearly revenue, obtain PRIOR written authorization from api@minimax.io (subject "MiniMax H3 licensing - authorization request").
- **IV.2:** The UI of a commercial product/service using the model must prominently display "MiniMax H3".

**Use restrictions (V)**
- **V.1:** Comply with applicable law (including trade compliance) and Exhibit A. **V.2:** Bind everyone you give access to by terms at least as protective as these restrictions and notify them.
- **V.3:** You may not use the model or its OUTPUTS to improve any other AI model (other than MiniMax H3 and its derivatives). (I.11: distillation and training on synthetic outputs make a model a "derivative"; outputs themselves are not derivatives.)
- **V.5:** If you offer third parties a product/service/hosted service that generates outputs with the model: before and throughout operation, reasonable technical and organizational safeguards, a reporting mechanism, prompt investigation, and removal/disabling/suspension of repeat violators.

**Trademark and rights (VI)**
- **VI.1:** You own the derivative works and model derivatives you create (subject to MiniMax's rights). **VI.2:** MiniMax names/marks are not licensed (beyond what is needed to describe and distribute); the "MiniMax H3" mark may be used only to comply with III.3, within the territory; do not imply affiliation.
- **VI.3:** If you sue MiniMax or anyone alleging the materials/outputs infringe your rights, all your licenses end that day; you defend and indemnify MiniMax against third-party claims arising from your or others' use/distribution.
- **VI.4:** MiniMax claims no rights over outputs; you and your users are responsible for outputs and their use.

**Disclaimers and termination (VII, VIII, IX)**
- **VII.1:** No obligation to support/update. **VII.2:** Model and outputs are provided "AS IS", no warranties; you decide suitability and assume the risk. **VII.3:** MiniMax and affiliates are not liable for any damages (to the extent law permits).
- **VIII.1:** Effective on acceptance/access. **VIII.2:** On breach MiniMax may terminate; you must stop using/distributing, delete copies and notify recipients (VI.1, VI.3, VII, IX survive).
- **IX:** Hong Kong SAR law; exclusive jurisdiction of Hong Kong courts (UN CISG excluded).
- **Additional note:** MiniMax H3's encoder uses Qwen3-VL-32B (Apache 2.0).

**Acceptable Use Policy (Exhibit A)** (do NOT use the model, derivatives or outputs for)
- A-1 use outside the territory; A-2 violating laws or third-party IP; A-3 harming yourself or others; A-4 repurposing/distributing outputs to harm; A-5 circumventing safeguards; A-6 exploiting/harming minors; A-7 verifiably false information to harm others or influence elections; A-8 fake online engagement (fake reviews etc.); A-9 defamation, disparagement, harassment; A-10 malware; A-11 personal data to harm others; **A-12 publishing content to any public environment (including bot posts) without clearly and prominently disclosing it is machine-generated**; A-13 impersonation without consent; A-14 high-risk automated decisions in critical domains (law enforcement, immigration, health, critical infrastructure, credit, employment, housing, education, social scoring, insurance, etc.); A-15 violating other countries'/regions' social, ethical, moral standards; A-16 violent extremism/terrorism; A-17 discrimination/harm based on protected characteristics; A-18 exploiting vulnerable populations; **A-19 military purposes**; A-20 unauthorized/unlicensed professional activity (financial, legal, medical, etc.).
- Note: this is a plain-language summary; the English license text prevails in case of doubt.

## Evidence labels

One set for all documents (older spellings in brackets):
- **[measured]** (TR: ölçtüm, olctum): run in this project, evidence path exists.
- **[read]** (TR: okudum yol, okudum): source or script was read, not run.
- **[design]** (TR: tasarım, tasarim): designed, not yet seen in a real run.
- **[guess]** (TR: tahmin): not verified.
- **[not tried]** (TR: denenmedi): never run.
- **[user-reported]** (TR: kullanıcı bildirdi): stated by the user, with date; not independently measured.
- **[computed]** (TR: hesap; older spellings: calculated, hesap): a number derived from measured inputs, not itself measured; the derivation is written next to it. [proposal] / [öneri] in older text = [guess].

## Known limitations
- **Byte proof** (how to reproduce it yourself: `docs/KANITLAR.md`, "R0 ve latent referansi nasil uretilir"; verified on our sm_61 card, other GPUs may not be byte-identical [guess]): with our patch series (memory flags on) a 56-frame run gave sha256 `0979f156d548169b...`, identical to the reference [measured]; at 141 frames the latent sha256 `E5D028F8632BE4FE...` was identical (with the 0013/0014 flags). Frames 158 to 209 have no direct byte reference; the gate chain is the evidence. Passing the numeric gates does not guarantee a good clip: motion consistency over time is checked by eye (see `docs/KAPILAR.md`).
- **209 frames, which flag set:** the 209-frame byte-chain evidence was taken with the F209V2 flag set on the development build (no block-tail flags, built without patches 0019/0020); `uret.ps1` uses this recipe for 209 frames [read: the script; a real engine run through `uret.ps1` passed in run U209].
- Verified on one card (GTX 1050 Ti 4 GB); other cards were not tried.
- **Which binary was measured:** the 141-frame latent and the byte chain were measured with our development builds. The release binary you download is a fresh build: its 56-frame byte gate passed (next item) and a 209-frame run through `uret.ps1` passed the gate (run U209, 3414 s, VRAM peak 3777 MiB) [measured]; against the development-build 209 run the latent is byte-identical; in the video the frames (md5) and the audio are identical, the AVI file sha256 differs because of the container [measured] (see `docs/OLCUMLER.md`, section 0).
- **Release binary, 56 frames:** the release binary (sd-cli `c5cebe78...`, stable-diffusion.dll `e5d3d329...`) gave a 56-frame result byte-identical to R0 (sha256 `0979f156d548169be03acd1a9d7617102a75333aa48a28d6bbfd1cc5fa3f604d`; per-frame md5 and audio identical), run directly with default flags (no `SD_*` variables), exit code 0, 601 s [measured: run B56VT2, 2026-11-19, finished 23:30; evidence in our work notes, not distributed]. Scope: our sm_61 card and 56 frames only; not a clean-root install test; the 141-frame latent and the 209 chain were measured with the older binary and NOT repeated with this one [not tried]. A first attempt (B56VT, via a helper script) ended silently after 58 s, cause unknown [guess: memory pressure]; the second attempt ran `sd-cli` directly.
- The install and run scripts have not been verified from an empty folder yet (clean-root test pending).
- Roadmap and next steps: `ROADMAP.md`.

## Status and limits
- Verified on one machine (GTX 1050 Ti 4 GB, 16 GB RAM, i7-7700HQ). Other 4 GB cards and other RAM sizes may differ.
- **Default 209 frames (8.7 s):** passed our quality gates (noise 1.08, run F209V2K) [measured: 209 frames with the release binary through `uret.ps1`, run U209; latent byte-identical to the development-build run; frames and audio identical in the video, the file sha differs because of the container; comparison file `kiyas_f209v2.json`]. At 209 frames the DiT VRAM peak was 3777 MiB of 4096 MiB (runs F209b and U209; whole-card `nvidia-smi` reading), a thin margin: other GPU load (the display, other applications) can make the run fail at `blocks.0`; tested only on a GTX 1050 Ti. The display state during that run was not recorded; if your display runs on this card, less VRAM is available [guess: a Windows display load of about 100-300 MB]; if needed, connect the display to an integrated GPU [advice, not tested]. Sampling took 2730 s (run U209: steps of 436-483 s) and the separate-process VAE decode 173 s (stage 2 in total 193 s with the audio decode) [measured: U209 release binary; older development runs: 2664 s and 174 s]. In stage 1 the in-process VAE ran out of memory and fell back to temporal tiling (320 s); that output is discarded, the video comes from the non-tiled stage 2. Peak RAM was not measured in U209. Longer clips than 209 frames are not part of this release.
- **Free RAM matters:** you need about 11 GB of FREE RAM (the engine process holds about 11 GB) [measured]. With too little free RAM the process can die without an error message [guess: observed once by a4 with about 300 MB free RAM while `sd-cli` held about 10 GB]. Do not open other big programs while it runs: on a 16 GB machine only about 0.3-0.5 GB stays free, and under memory pressure the run can die silently. Before you start, close browsers, games and other big programs and check the free RAM.
- **Clean-root test pending:** the install and run scripts have not yet been verified from an empty folder using only these instructions; this section will be updated when that test (including a 56-frame byte comparison against the reference) is recorded.
- No generated videos are shipped here.

---

<a id="tr"></a>
# VideoTurko (TR)

> **30 saniyede:** 4 GB bir ekran kartı 209 karelik (8,7 sn) MiniMax H3 videosunu tek geçişte üretebiliyor: tek makinede doğrulandı (GTX 1050 Ti 4 GB) [ölçtüm: 209 kare, sürüm ikilisiyle, `uret.ps1` üzerinden, koşu U209; latent bayt-aynı; videoda kareler ve ses aynı, dosya sha'sı konteyner nedeniyle farklı; kıyas dosyası `kiyas_f209v2.json`]; aşağıdaki 3 adım nasıl çalıştırılacağını gösterir.

VideoTurko: 4 GB GTX 1050 Ti'de MiniMax H3 ile metinden/görselden videoyu tek seferde 209 kareye (8,7 sn) kadar (209 kare bayt zinciriyle doğrulandı) üretmek için stable-diffusion.cpp bellek yamaları ve tarifler; 56 ve 141 karelik kontrollerde yamasız koşuyla bayt aynı.

## Hızlı başlangıç (Windows, 3 adım)
**Durum: aşağıdaki kurulum/çalıştırma betikleri tamamlanıyor ve temiz kök testi bekliyor; bu test geçene kadar burada hiçbir şeyin çalıştığı iddia edilmez ("Durum ve sınırlar").**

1. **İndir**: bu depoyu indirin (yeşil **Code** düğmesi, **Download ZIP**) ve KISA bir klasöre açın, örneğin `C:\vt`.
2. **Kur**: o klasörde PowerShell açın (Gezgin adres çubuğuna `powershell` yazın) ve çalıştırın:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\kur.ps1
   ```
   Kurulum kökü açtığınız klasördür (motor `engine\bin`, modeller `model` altına gider); başka yer için önce `VT_ROOT` ortam değişkenini ayarlayın. GPU, sürücü, RAM ve disk kontrol edilir; motor ve modeller indirilir (motor zipleri ve yeni indirilen model dosyaları sha256 ile doğrulanır; boyutu doğru olan mevcut model dosyası yalnız boyutla denetlenir, tam sha256 için `scripts\modelleri_indir.ps1 -Dogrula`); kısa gerçek bir kontrol koşulur ve yalnız o geçerse HAZIR yazar [tasarım: `kur.ps1` temiz klasörde baştan sona koşulmadı; temiz kök testinden sonra bu cümle güncellenir]. `-ExecutionPolicy Bypass` yalnız bu sürece uygulanır; her kurulum betiğinde olduğu gibi önce `scripts\kur.ps1`'i okuyun.
   Release yayınlanana kadar motor adımı "release adresi/sha256 henuz yok" diyerek durur; yerel zip verin: `-MotorZip <yol> -CudaZip <yol>`. Yerel zip ve henüz gömülü release sha256'sı yokken zipin yanındaki `.sha256` kullanılır; bu self-referential, bağımsız değildir: bozulmayı yakalar, kasıtlı değiştirmeyi yakalamaz (dosya yoksa `kur.ps1` "sha256 doğrulanmadı" uyarısı verir; yanlış sha256 çıkış 1 ile durur). Release sonrası gömülü sha256 her zaman önceliklidir, yan dosya yok sayılır. `engine\bin`'e yalnız `.exe`/`.dll` gider; lisanslar ve README `engine\lisanslar\<zip adı>\` altına yazılır. [dist zipleriyle denendi: yan `.sha256` ve self-referential uyarısı, ikili ve DLL'ler yerleşti, `sd-cli --help` çalıştı; kurulu ikili sha'ları eşleşti (`c5cebe78...`, `e5d3d329...`); `kur.ps1`'in model adımı ve 5 karelik kontrolü gerçek GPU'da HENÜZ denenmedi]
   **Model lisansı:** model adımından önce kurulum lisans özetini (`docs/LISANS_KABUL.txt`, tam metin `docs/LISANS_UYARISI.md`: MiniMax H3 Community License, üretilen videoları da kapsayan bölge sınırları, ticari kullanım ve yapay zekâ etiketi kuralları) yazar ve kabul etmenizi ister (`E` = evet). Önce okuyun. Gözetimsiz çalıştırmada `-LisansKabul E` verebilirsiniz; bu, lisansı kendinizin okuyup kabul ettiğiniz anlamına gelir, başkası adına eklemeyin. (Yapay zekâ ajanları: `AGENTS.md`; kullanıcı onayı olmadan E vermeyin.) Kabul yoksa `kur.ps1` çıkış kodu 2 ile durur ve model indirmez.
3. **Üret**: istemi bir metin dosyasına yazın (tek paragraf İngilizce, isteğe bağlı `audio:` cümlesi) ve çalıştırın:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\uret.ps1 -Istem istem.txt -Kare 209
   ```
   `-Kare` 17k+5 dizisinden seçilir (56, 73, ... 192, 209); varsayılan 209 (8,7 sn), kapsadığımız en uzun uzunluktur. VAE ayrı süreçte ve karosuz koşar [`uret.ps1` üzerinden sürüm ikilisiyle gerçek motor koşusu, ayrı süreç VAE, U209 koşusunda geçti].

| Gereksinim | Değer |
|---|---|
| İşletim sistemi | Windows 10/11, 64 bit |
| Ekran kartı | NVIDIA, 4 GB ya da üstü; yalnız GTX 1050 Ti (sm_61) ile denendi |
| RAM | 16 GB (tepe yaklaşık 11 GB; diğer programları kapatın) |
| Disk | 32 GiB ya da fazlası boş, modeller SSD'de (NVMe tercih) |
| İndirme | motor zip 36,8 MB + CUDA çalışma zamanı zip 567,5 MB [ölçtüm] + modeller 31.473.112.040 bayt (yaklaşık 29,3 GiB) [okudum: `scripts/modeller.json` boyutları]; toplam yaklaşık 30 GiB |
| Modeller | dahil değil; MiniMax lisansı altında kurulum betiği indirir (aşağıdaki uyarı). Modeller (29,3 GiB, `scripts/modeller.json`'da 31.473.112.040 bayt) bu depoda ya da release'te yok: GitHub dosya/release boyut sınırları geçerli ve `kur.ps1` onları resmi kaynaktan sha256 doğrulamasıyla indirir. |

`kur.ps1` çıkış kodları: 0 HAZIR, 1 hata, 2 kullanıcı girdisi gerekli (lisans ya da henüz release/zip yok), 3 donanım ya da disk yetersiz, 4 durduruldu (DUR dosyası). `uret.ps1` bir koşuyu yalnız `.avi` var, kare sayısı doğru ve loglar temizse kabul eder [tasarım: gerçek motora karşı henüz koşulmadı]. `uret.ps1` çıkış kodları: 0 TAMAM (kalite kapısı geçti), 1 hata ya da geçersiz çıktı (ses akışı olmayan video dahil), 2 durduruldu (DUR dosyası), 5 `KAPI RED` (kalite kapısı geçmedi: klip kabul edilmez, karar sizin), 6 kapı çalışamadı (klip kabul edilmez). Ayrıntı AGENTS.md'de. [tasarım: sahte motorla denendi, gerçek `sd-cli` ile henüz değil]

### Sorun giderme (ayrıntı: `docs/SIK_HATALAR.md`)
| Ne görüyorsunuz | Ne demek, ne yapılır |
|---|---|
| `STATUS_DLL_NOT_FOUND` / `cudart64_12.dll not found` (#13) | `sd-cli.exe`'yi elle başlatmayın; CUDA DLL'lerini yerine koyan `scripts\kur.ps1`'i çalıştırın. |
| `blocks.0` `failed during weight preparation` (#1, #3, #5) | Bellek kapısında VRAM yetmedi: 17k+5 dizisinden daha küçük kare sayısı seçin, diğer GPU programlarını kapatın, verilen bayrakları değiştirmeyin. |
| `retrying with temporal tiling` (#6) | VAE karolu moda düştü; çıktı kalite açısından geçersiz. Yeniden çalıştırın. |
| Süre tavanında durdu, video yok (#7) | Uzun klipler için `-TavanDk` değerini artırın (209 kare en az 80 dakika ister). |
| Çıkış kodu boş ama "bitti" yazdı (#14) | Sarmalayıcı çıkış kodunu erken okudu; yeniden çalıştırın ve video dosyasının varlığına bakın. |
| Sistem yavaşladı, takas (#18) | Motor yaklaşık 10-11 GB RAM kullanır; tarayıcı ve diğer programları kapatın. |
| sha256 tutmadı / indirme başarısız | Genelde yarım kalan indirme: aynı komutu tekrar çalıştırın, doğrulanmış dosyalar atlanır. |

## Bu nedir
MiniMax H3'ü (33B DiT; biz HyperFlow Flash 13,7B Q4_K_M GGUF'u çalıştırıyoruz; 32B Qwen3-VL metin kodlayıcı ayrıdır) 4 GB'lık Pascal ekran kartında (GTX 1050 Ti, 16 GB RAM) çalıştırmak için küçük bellek/zamanlama yamaları, çalıştırma tarifi, kontroller ve ölçümler.
- Gerçekten ürettiğimiz ve kalite kapılarından geçen tek geçiş uzunlukları: 640x384, 24 fps, 56, 141, 158, 175, 192, 209 kare (209 kare = 8,7 sn); sesi H3'ün kendisi üretir [ölçtüm: 209 kare, sürüm ikilisiyle, `uret.ps1` üzerinden, koşu U209; latent bayt-aynı; videoda kareler ve ses aynı, dosya sha'sı konteyner nedeniyle farklı; kıyas dosyası `kiyas_f209v2.json`]. 209, izleyip düzgün bulduğumuz en uzun süredir [kullanıcı bildirdi, 2026-11-19, video baştan sona izlendi; dosya: F209V2 çıktısı, 8,708 sn].
- **Bayt aynılık iddiası dürüst kapsamda:** yamasız referansa bayt aynılık yalnız 56 ve 141 karede doğrulandı. 158/175/192/209 karede aynı bayraklar ve aynı ikili zinciri kullanıldı, doğrudan bayt referansı yok (yamasız sürüm bu uzunlukları bu kartta koşamıyor).
- Kalite ayarları düşürülmez: aynı model/nicem, 6 adım, cfg 1, 640x384, aynı tohum, karosuz VAE.
- "İlk" iddiası yok: aradık, 4 GB'ta benzer dış örnek bulamadık; bu, yok olduğunun kanıtı değildir.

## Düzen
`patches/` (sabit stable-diffusion.cpp commit'ine yamalar), `scripts/` (derleme, çalıştırma, ayrı süreç VAE, kapı/tutarlılık yardımcıları), `docs/KURULUM.md` (donanım, derleme, çalıştırma).

## Kalite kapıları

Bu kapı hareket tutarlılığını (nesne ölçeği/konum sıçraması) denetlemez: kabul etmeden önce videonun tamamını izleyin.
1. Kare sayısı doğru, ses var, günlükte bellek geri-düşme/ALLOC_FAILED satırı yok.
2. Ham gürültü kapısı: medyan süzgeç artığı <= 1,5 (0-255).
3. Dokuya göre normalize gürültü, `scripts/doku_norm.py` (bu deponun sürümü): N = medyan artık / Sobel doku, her 6. kare. **Ölçek notu:** bu sürümde ölçülen 10 klip N = 0,034-0,052 verir (tablo `docs/KAPILAR.md`; F192/F209V2 son çeyrek 0,062'ye çıkar), ek kapı eşiği N <= 0,065. Başka bir gerçekleme aynı kliplerde 0,028-0,036 ölçtü, yani eşikler sürümler arasında DEĞİŞTİRİLEMEZ. Çok ince dokuda (çim sırası) temiz N 0,075 çıktı: eşik sahne ailesine göre. Önerilen ek kapı: yüksek frekans bandı sağlam gürültü tahmini (sigma-HH <= 1,5; temiz 0,74-1,19, s=2 gürültüde 2,2-3,0).

Kapsam: VideoTurko TEK geçiş içindir (209 kareye kadar, yaklaşık 8,7 sn). Parçaları birleştirip uzun video yapmak denendi; dikişler belli oldu (sahne temiz devam etmiyor), bu yüzden projenin parçası değil. Daha uzun video isteyen kendi yolunu kursun.
Ayarlar sizin: 209 kare bizim 4 GB kartta denediğimiz varsayılandır, zorunlu değil. 17k+5 dizisinden istediğiniz kare sayısını seçin (56, 73, ... 192, 209; bkz. `docs/KURULUM.md`); istemi, tohumu, çözünürlüğü ya da herhangi bir bayrağı istediğiniz gibi değiştirin. Kısa video daha az bellek ve süre ister; büyük kartta daha fazlası sığabilir.

## Model lisans uyarısı
**VideoTurko yalnız yamalar ve betikler içerir (MIT); modeli ve çıktıları kullanan kişi MiniMax lisansından kendisi sorumludur.** Hukuki görüş değildir. Aşağıda MiniMax H3 Community License (2 Ağustos 2026) maddeleri numaralarıyla özetlenmiştir; bağlayıcı olan lisansın kendisidir: https://huggingface.co/MiniMaxAI/MiniMax-H3/blob/main/LICENSE

Bu repo model ağırlığı İÇERMEZ (MiniMax H3, HyperFlow-H3-Flash GGUF ve VAE dosyaları yok). Bu proje MiniMax ile bağlantılı ya da onaylı değildir. Ticari kullanım yasak DEĞİLDİR (lisans ticari-olmayan lisansı değildir); şartlar aşağıdadır.

**Bölge (Applicable Territory)**
- **Giriş, I.3, I.5:** Lisans dünya geneli, ama Avrupa Birliği, Birleşik Krallık, Güney Kore ve ABD HARİÇ. Modeli kullanmaya başlamak lisansı kabul etmek sayılır.
- **II:** Telifsiz, devredilemez, sınırlı lisans; kullanma, çoğaltma, dağıtma, türev üretme ve değiştirme yalnız bu bölgede ve sözleşme ile Ek A'ya uyarak serbesttir. Hariç bölgelerdeki kişiler MiniMax'tan ayrı lisans isteyebilir.
- **V.4:** Modeli, türevlerini VE ÇIKTILARI (ürettiğiniz video/ses) hariç bölgelerde kullanmak, çoğaltmak, değiştirmek, dağıtmak ya da göstermek yetkisizdir. **Yani üretilen videoyu AB/BK/Güney Kore/ABD'de yayınlamak ya da göstermek lisans dışıdır.**
- **Ek A-1:** Bölge dışı kullanım, kabul edilebilir kullanım politikasının ihlalidir.

**Dağıtım (III)** (bu repo model dağıtmaz; modeli dağıtırsanız)
- **III.1:** Her alıcıya lisansın kopyasını verin. **III.2:** Değiştirdiğiniz dosyalara belirgin değişiklik notu koyun.
- **III.3:** Teşvik edilir (zorunlu değil): ürüne "Powered by MiniMax H3" notu, üretilen dosyalara yapay zekâ etiketi, deneyim yazısı.
- **III.4:** Dağıtıma şu metni içeren bir NOTICE dosyası eşlik ETMEK ZORUNDADIR: "MiniMax H3 is licensed under the MiniMax H3 Community License Agreement, Copyright © 2026 MiniMax. All Rights Reserved."
- **Ek A-12:** makine üretimi olduğunu açıkça söylemeden herkese açık ortama içerik yayma yasaktır: yapay zekâ ile üretilen videoları yayımlarken etiketleyin (tam liste: `docs/LISANS_UYARISI.md`).
- **III (son paragraf):** Değişikliklerinize kendi telifinizi koyabilirsiniz ama kullanım/dağıtım için ek ya da farklı şart koyamazsınız; bölge kuralları geçerli kalır.

**Ticari şartlar (IV)**
- **IV.1:** Ticari ürün/hizmetleriniz yıllık 20 milyon ABD dolarından (ya da karşılığından) fazla gelir getiriyorsa api@minimax.io adresinden ("MiniMax H3 licensing - authorization request" konusuyla) ÖNCEDEN yazılı izin alın.
- **IV.2:** Modeli kullanan ticari ürün/hizmetin arayüzünde "MiniMax H3" belirgin yazılmalıdır.

**Kullanım kısıtları (V)**
- **V.1:** Yürürlükteki yasalara (ticaret/ihracat uyumu dahil) ve Ek A'ya uyun. **V.2:** Modele ya da onu içeren ürüne erişim verdiğiniz herkesi en az bu kısıtlar kadar koruyucu bağlayıcı şartlara bağlayın ve onlara bildirin.
- **V.3:** Modeli ya da ÇIKTILARINI başka bir yapay zekâ modelini geliştirmek için kullanamazsınız (yalnız MiniMax H3 ve türevleri hariç). (I.11: damıtma ve sentetik veriyle eğitim de "türev" sayılır; çıktının kendisi türev sayılmaz.)
- **V.5:** Üçüncü kişilere model ile çıktı ürettiren bir ürün/hizmet/barındırılan hizmet sunarsanız: önce ve süresince makul teknik ve kurumsal güvenlik önlemleri, ihlal bildirim mekanizması, bildirimde hızlı inceleme, içerik kaldırma/erişim kesme ve tekrarlayanı askıya alma yükümlülüğü.

**Marka ve haklar (VI)**
- **VI.1:** Yaptığınız türev işlere ve model türevlerine (MiniMax'ın haklarına tabi) siz sahipsiniz. **VI.2:** MiniMax adı/markası lisanslı değil (yalnız modeli anlatmak/dağıtmak için gerekli ölçüde); "MiniMax H3" markası yalnız III.3 uyumu için bölge içinde kullanılabilir; ortaklık ima etmeyin.
- **VI.3:** MiniMax'a ya da başkasına, materyalin/çıktının hakkınızı ihlal ettiği iddiasıyla dava açarsanız tüm lisanslarınız o gün sona erer; modelin sizce ya da başkalarınca kullanım/dağıtımından doğan üçüncü kişi taleplerinde MiniMax'ı savunur ve tazmin edersiniz.
- **VI.4:** MiniMax çıktılar üzerinde hak iddia etmez; çıktıdan ve sonraki kullanımından siz ve kullanıcılarınız sorumlusunuz.

**Sorumluluk reddi ve fesih (VII, VIII, IX)**
- **VII.1:** MiniMax destek/güncelleme/yeni sürüm vermek zorunda değil. **VII.2:** Model ve çıktılar "OLDUĞU GİBİ", garantisiz; uygunluğu belirlemek ve riski üstlenmek size ait. **VII.3:** MiniMax ve bağlıları hiçbir zarardan sorumlu değildir (yasanın izin verdiği ölçüde).
- **VIII.1:** Sözleşme kabul/erişim anında başlar. **VIII.2:** İhlalde MiniMax feshedebilir; fesihte model kullanımını/dağıtımını hemen bırakır, kopyaları silersiniz ve alıcıları bilgilendirirsiniz (VI.1, VI.3, VII, IX fesihten sonra da sürer).
- **IX:** Hukuk Hong Kong ÖİB hukukudur; yetkili mahkemeler Hong Kong mahkemeleridir (BM Mal Satımı Sözleşmesi uygulanmaz).
- **Ek not:** MiniMax H3 kodlayıcısı Qwen3-VL-32B (Apache 2.0) kullanır.

**Kabul edilebilir kullanım politikası (Ek A)** (modeli, türevlerini ve çıktıları şunlar için KULLANMAYIN)
- A-1 bölge dışı kullanım; A-2 yasaları ya da üçüncü kişilerin fikri haklarını ihlal; A-3 kendinize/başkasına zarar; A-4 çıktıyı zarar vermek için yeniden kullanma/dağıtma; A-5 güvenlik önlemlerini aşma; A-6 reşit olmayanları sömürme/zarar; A-7 zarar vermek ya da seçimleri etkilemek için doğrulanabilir biçimde yanlış bilgi; A-8 sahte çevrimiçi etkileşim (sahte yorum vb.); A-9 iftira, aşağılama, taciz; A-10 kötü amaçlı yazılım; A-11 zarar vermek için kişisel veri; **A-12 makine üretimi olduğunu açık ve belirgin söylemeden herkese açık ortama (bot gönderileri dahil) içerik yayma**; A-13 rızasız başkasını taklit; A-14 kritik alanlarda (kolluk, göç, sağlık, kritik altyapı, kredi, istihdam, konut, eğitim, sosyal puanlama, sigorta vb.) yüksek riskli otomatik karar; A-15 başka ülke/bölgelerin toplumsal, etik, ahlaki değerlerini ihlal; A-16 şiddet içerikli aşırıcılık/terör; A-17 korunan özelliklere dayalı ayrımcılık/zarar; A-18 savunmasız grupların zayıflığını istismar; **A-19 askeri amaç**; A-20 izinsiz/ruhsatsız mesleki faaliyet (finans, hukuk, tıp vb.).
- Not: Bu metin sade dilde özettir; belirsizlikte lisansın İngilizce metni geçerlidir.

## Kanıt etiketleri

Tüm belgelerde tek set (eski yazımlar parantezde):
- **[ölçtüm]** (EN: measured, olctum): bu projede koşuldu, kanıt yolu var.
- **[okudum yol]** (EN: read, okudum): kaynak ya da betik okundu, koşulmadı.
- **[tasarım]** (EN: design, tasarim): tasarlandı, gerçek koşuda görülmedi.
- **[tahmin]** (EN: guess): doğrulanmadı.
- **[denenmedi]** (EN: not tried): hiç koşulmadı.
- **[kullanıcı bildirdi]** (EN: user-reported): kullanıcı söyledi, tarihli; bağımsız ölçülmedi.
- **[hesap]** (EN: computed; eski yazımlar: calculated): ölçülen girdilerden türetilmiş sayı, kendisi ölçülmedi; hesap yolu yanında yazılı. Eski metindeki [öneri] / [proposal] = [tahmin].

## Bilinen sınırlar
- **Bayt kanıtı** (kendiniz nasıl üretirsiniz: `docs/KANITLAR.md`, "R0 ve latent referansi nasil uretilir"; sm_61 kartımızda doğrulandı, başka GPU'larda bayt aynı olmayabilir [tahmin]): yama serimizle (bellek bayrakları açık) 56 karelik koşu referansla aynı sha256 `0979f156d548169b...` verdi [ölçtüm]; 141 karede latent sha256 `E5D028F8632BE4FE...` aynı çıktı (0013/0014 bayraklarıyla). 158-209 karede doğrudan bayt referansı yok; kanıt kapı zinciridir. Sayısal kapılardan geçmek iyi klip garantisi vermez: zaman içinde hareket tutarlılığı gözle denetlenir (`docs/KAPILAR.md`).
- **209 kare, hangi bayrak seti:** 209 karelik bayt zinciri kanıtı geliştirme derlemesinde F209V2 bayrak setiyle alındı (blok-sonu bayrağı yok, 0019/0020 yamasız derleme); `uret.ps1` 209 kare için bu tarifi kullanır [okudum: betik; `uret.ps1` üzerinden gerçek motor koşusu U209'da geçti].
- Tek kartta doğrulandı (GTX 1050 Ti 4 GB); başka kartlar denenmedi.
- **Hangi ikili ölçüldü:** 141 kare latent ve bayt zinciri geliştirme derlemelerimizle ölçüldü. İndirdiğiniz sürüm ikilisi yeni bir derlemedir: 56 kare bayt kapısı geçti (sonraki madde) ve `uret.ps1` üzerinden 209 kare koşusu kapıyı geçti (koşu U209, 3414 sn, VRAM tepesi 3777 MiB) [ölçtüm]; geliştirme derlemesi 209 koşusuyla latent bayt-aynı; videoda kareler (md5) ve ses aynı, AVI dosya sha256'sı konteyner nedeniyle farklı [ölçtüm] (`docs/OLCUMLER.md`, bölüm 0).
- **Sürüm ikilisi, 56 kare:** sürüm ikilisi (sd-cli `c5cebe78...`, stable-diffusion.dll `e5d3d329...`) 56 karede R0 ile bayt aynı sonuç verdi (sha256 `0979f156d548169be03acd1a9d7617102a75333aa48a28d6bbfd1cc5fa3f604d`; kare md5 ve ses aynı); doğrudan, varsayılan bayraklarla (hiç `SD_*` yok), çıkış kodu 0, 601 sn [ölçtüm: koşu B56VT2, 2026-11-19, bitiş 23:30; kanıt çalışma notlarımızda, dağıtılmıyor]. Kapsam: yalnız sm_61 kartımız ve 56 kare; temiz kök kurulum testi değil; 141 kare latent ve 209 zinciri eski ikiliyle ölçüldü, bununla TEKRARLANMADI [denenmedi]. İlk deneme (B56VT, yardımcı betikle) 58 sn'de sessizce bitti, neden bilinmiyor [tahmin: bellek baskısı]; ikinci deneme `sd-cli`'yi doğrudan çalıştırdı.
- Kurulum ve çalıştırma betikleri boş klasörde henüz doğrulanmadı (temiz kök testi bekliyor).
- Yol haritası ve sonraki adımlar: `ROADMAP.md`.

## Durum ve sınırlar
Tek makinede doğrulandı (GTX 1050 Ti 4 GB, 16 GB RAM, i7-7700HQ). Başka 4 GB kartlar ve RAM boyutları farklı olabilir. **Varsayılan 209 kare (8,7 sn):** kalite kapılarından geçti (gürültü 1,08, koşu F209V2K) [ölçtüm: 209 kare, sürüm ikilisiyle, `uret.ps1` üzerinden, koşu U209; latent bayt-aynı; videoda kareler ve ses aynı, dosya sha'sı konteyner nedeniyle farklı; kıyas dosyası `kiyas_f209v2.json`]. 209 karede DiT VRAM tepesi 4096 MiB içinde 3777 MiB idi (koşular F209b ve U209; tüm kart için `nvidia-smi` okuması), pay ince: başka GPU yükü (ekran, başka uygulamalar) koşuyu `blocks.0`'da düşürebilir; yalnız GTX 1050 Ti'de denendi. O koşuda ekran durumu kayıtlı değil; ekranınız bu karta bağlıysa kullanılabilir VRAM daha azdır [tahmin: Windows ekran yükü yaklaşık 100-300 MB]; gerekirse ekranı tümleşik GPU'ya bağlayın [tahmin, denenmedi]. Örnekleme 2730 sn (U209: adımlar 436-483 sn), ayrı süreç VAE çözmesi 173 sn sürdü (2. aşama toplam 193 sn, ses çözme dahil) [ölçtüm: U209 sürüm ikilisi; eski geliştirme koşuları: 2664 sn ve 174 sn]. 1. aşamada süreç içi VAE belleği aşıp karolu çözmeye düştü (320 sn); o çıktı atılır, video karosuz 2. aşamadan gelir. U209'da RAM tepesi ölçülmedi. 209 karedan uzun klipler bu sürümün parçası değil. **Temiz kök testi bekliyor:** kurulum ve çalıştırma betikleri boş klasörde yalnız bu talimatla henüz doğrulanmadı; test (56 karede referansa bayt kıyası dahil) kaydedilince bu bölüm güncellenir. Çıktı videolar depoda yok.
- **Boş RAM önemli:** yaklaşık 11 GB BOŞ RAM gerekir (motor süreci yaklaşık 11 GB tutar) [ölçtüm]. Boş RAM azsa süreç hata mesajı vermeden ölebilir [tahmin: a4 bir kez gözledi, boş RAM yaklaşık 300 MB iken `sd-cli` yaklaşık 10 GB tutuyordu]. Koşu sürerken başka büyük program açmayın: 16 GB'lık makinede boş pay yalnız yaklaşık 0,3-0,5 GB kalır ve bellek baskısında koşu sessizce ölebilir. Başlamadan önce tarayıcı, oyun ve diğer büyük programları kapatın, boş RAM'e bakın.
