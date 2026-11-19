# ROADMAP

What we know is not finished, why it matters, how well it is evidenced, and the next step. Labels: **[measured]** we ran it and kept the log, **[read]** taken from code or a document, **[guess]** not verified. Test machine: GTX 1050 Ti 4 GB, 16 GB RAM. Contributions welcome: see `CONTRIBUTING.md`.

| What | Why | Evidence now | Next step |
|---|---|---|---|
| Longer single-pass research | Longer single clips without seams | Not part of this release; no measurement beyond 209 frames [not tried] | Open research question; any new length needs its own measurements and gates first |
| Direct byte reference for 158 to 209 frames | Today byte evidence exists only for 56 frames and the 141-frame latent; longer clips rely on the gate chain | Gate chain passed [measured]; the unpatched build cannot run these lengths on this card [measured] | Run the same recipe on a larger-memory machine or the CPU path to obtain a reference, then compare hashes |
| Speed | 209 frames take about 45 min of sampling plus 3 min of VAE | Sampling about 2730 s and VAE about 173 s with the release binary, 3414 s in total [measured: U209; older development runs 2664 s and 174 s] | Overlap weight loading with compute, fewer copies per block, check the NVMe read path; quality settings stay fixed |
| Other cards and drivers | Only one GPU was tested | One card [measured]; supported architectures of the release build [read] | Collect reports through the hardware-test issue template; try 6 GB cards and newer architectures |
| Re-verify the release binary | Measured numbers come from development builds (`docs/OLCUMLER.md`, section 0); the release binary is a fresh build | 56-frame byte gate passed for the release binary [measured]; 209-frame run through `uret.ps1` passed the gate [measured: U209]; latent byte-identical to the development-build run, frames and audio identical, file sha differs (container) [measured] | Only the 141-frame latent chain is not repeated with the release binary [not tried] |
| Multi-architecture release build | The first release targets Pascal (sm_61) | Pascal build [measured]; others [guess] | Build and test sm_75, sm_86, sm_89 packages; keep sha256 for each |
| Upstream | Patches that are not experimental could help stable-diffusion.cpp users | Upstream PR #2369 (VAE encode padding) is already part of the base [read] | Prepare small, separately tested patches for upstream review; keep experimental ones out |
| Clean-folder install test | The README does not claim "works" until it is seen | Pending | Run `scripts\kur.ps1` then `scripts\uret.ps1` in an empty folder, record log, hashes and time |

## TR ozet
Bu liste bitmemis isleri, nedenlerini, kanit durumunu ve sonraki adimi toplar: daha uzun tek gecis arastirmasi, 158-209 icin dogrudan bayt referansi, hiz, diger kartlar ve cok mimarili surum, upstream, temiz klasor kurulum testi ve surum ikilisiyle 209 kare kontrolu. Her satirda kanit [olctum] / [okudum] / [tahmin] etiketlidir.
