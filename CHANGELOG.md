# Changelog

## v0.1.0 (draft, not released)
- Memory patches for stable-diffusion.cpp so MiniMax H3 (HyperFlow Flash Q4_K_M) runs on a 4 GB Pascal GPU: single pass up to 209 frames (8.7 s; default; verified by a byte chain) at 640x384, 24 fps. Patches are listed in `docs/YAMALAR.md`.
- Scripts: `kur.ps1` (install), `uret.ps1` (generate), `hiz_kos3.ps1`, quality gates, seam check, byte comparison, separate-process VAE recipe.
- `uret.ps1`: exit-code bug fixed (empty exit code after the engine process ended); a real 5-frame run will be seen in a clean folder [guess, not yet verified].
- Docs: evidence, gates, measurements, common mistakes, license notes (EN + TR).
- Known limits: byte reference only for 56 frames (also with the release binary) and the 141-frame latent (development build); 209 frames passed the quality gates and a byte chain on the development build, the release binary also passed a 209-frame run through `uret.ps1` (run U209), its latent is byte-identical to the development-build run and the video frames and audio are identical (file sha differs because of the container); no direct byte reference for 158-209 frames; passing the numeric gates does not guarantee a good clip (motion consistency is checked by eye); verified on one machine; clean-folder install test pending.
