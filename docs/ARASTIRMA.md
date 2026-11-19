# ARASTIRMA / Research notes (EN + TR)

Background, measurements, rejected ideas and lessons behind VideoTurko. Labels: **[measured]** we ran it and kept the log, **[read]** taken from a file or document, **[guess]** not verified. Also used: **[design]** designed, not yet seen in a real run, and **[not tried]** never run. Shared glossary with Turkish equivalents (ölçtüm = measured, okudum = read, tahmin = guess, tasarım = design, denenmedi = not tried): README, section Evidence labels. Test machine: GTX 1050 Ti 4 GB (Pascal), 16 GB RAM, i7-7700HQ. Everything below holds for that machine only.

## 1. Starting point [measured]
- Stock stable-diffusion.cpp could not run MiniMax H3 (HyperFlow Flash Q4_K_M, 6 steps) beyond about 56 frames at 640x384 on this card. The 56-frame run took about 560-740 s depending on the VAE path; a non-tiled VAE in a separate process was the quality reference.
- Frame counts follow a 17k+5 grid: 56, 73, 90, 107, 124, 141, 158, 175, 192, 209 [read: engine documentation].

## 2. The wall was a margin gate, not the model [measured + read]
At 90 frames the engine stopped at the first DiT block with "short by about 96 MB". The cause was a safety margin in the model manager (default 1024 MB on Windows with CUDA), not real exhaustion. `SD_VRAM_MARGIN_MB` lowers it. Do not write 0: 0 means "unset" and falls back to 1024. Margins that worked: 512 (90 frames), 256 (107), 96 (124), 48 (141 and above), 1 (209 with a tuned flag set).

## 3. What reached 209 frames [measured]
Margin tuning plus patches that move or shrink memory without changing arithmetic: own graph segment after the input embedding (0009), drop queued prefetch and evict earlier weights when the capacity gate fails (0010, 0011), capture large cut tensors in host RAM (0007, 0017), write chunked attention/q/k/v outputs into preallocated tensors (0013, 0014), never fall back to tiled VAE (0016), VAE embedding cut (0018), and the VAE in a separate process (save/load latent, 0001). Single-pass times: 90 frames 991 s, 107 1146 s, 124 1404 s, 141 1664 s, 158 2006 s, 175 2296 s; 209 frames passed the gates (noise 1.08). Details: `docs/OLCUMLER.md`, `docs/YAMALAR.md`.

## 4. Evidence and its limits
- Byte reference: sha256 `0979f156d548169be03acd1a9d7617102a75333aa48a28d6bbfd1cc5fa3f604d` (56 frames, unpatched path). Patches 0006-0011, 0013, 0014, 0016-0018 reproduced it, or the 141-frame reference [measured].
- There is no byte reference for 158/175/192/209 frames (the unpatched build cannot run them here). We used the same flags and binary chain and the quality gates instead [honest limit].
- Quality gates: frame count, audio, no fallback/alloc errors, raw noise <= 1.5, middle-frame flow > 0.05, texture-normalised noise (see README scale note).

## 5. Rejected or unproven [measured unless noted]
- **Tiled or temporal-tiled VAE:** forbidden. It changes the output; the H3 VAE is not causal, so temporal tiling cannot be made equivalent [read: code].
- **MLP chunk size alone (0006):** the buffer did not shrink; only `blocks.0` gained about 76 MB.
- **0006b chunked QKV alone:** raises the peak by +121.5 MB; usable only with 0014.
- **`SD_MLP_SET_OUT` (0015):** adds roughly N x 21.5 KB of memory (about +320 MB at 209 frames); it increased the peak instead of reducing it. Fixed by 0020 (destination created by pad of the first chunk, not a graph-start leaf); with 0020 it is byte-identical on 56 frames (0979f156...) and part of the series, default off.
- **0019 and 0020 (experimental):** in the series, default off, byte-identical to R0 on 56 frames only (B56H10b/B56H11, R0 sha256 0979f156...); not used by the 209 run.
- **Margin 0, margin 128 with 141 frames, step/cfg/resolution reductions:** invalid or fatal; never a quality route.
- **Chaining parts (`--init-img`):** seams were visible; the scene did not continue cleanly. Not part of this project.

## 6. Lessons
1. A "short by N MB" message can be a safety margin, not a limit: read the code that prints it before redesigning.
2. Estimates need the real inputs: a token count assumed from a formula (16531) differed from the logged one (17147) and made a memory estimate wrong. Take numbers from the log.
3. A patch can enlarge the peak when used alone; judge each patch with and without its partners.
4. Raw noise metrics depend on scene texture. A high reading on a dusty or detailed scene is not by itself proof of degradation, and a low one is not proof of quality: use more than one measure and look at frames.
5. When chaining, take the true last frame (frame count minus one); one run used frame 205 of 209 and the seam collapsed.
6. A stop file that also kills the running job leaves "finished" status without a result: check that the output file and hash exist before trusting a status line.
7. Reusing a job id or an old output path overwrites earlier results: new id, new path.
8. Write "works" only after a clean-folder run from the written instructions.

## TR ozet
Bu belge VideoTurko'nun arkasindaki olcumleri, elenen fikirleri ve dersleri toplar. Duvar bellek degil, motorun 1024 MB guvenlik payi kapisiydi; pay dusurulup bellek yamalariyla (yalniz yer degistiren, aritmetigi degistirmeyen) 209 kareye cikildi. Bayt referansi yalnizca 56 ve 141 karede var; 158-209 karede ayni bayraklar ve kalite kapilari kullanildi. Karolu VAE yasak, 0015/0019/0020 deneysel ve varsayilan kapali. Tum rakamlar tek makine icindir.
