# 0001

Save/load the sampled video latent so the VAE can run in a separate process

- Env flag: SD_VIDEO_LATENT_SAVE=<file>, SD_VIDEO_LATENT_LOAD=<file>
- Evidence: Bit-exact float32 round trip; F192V/F209V2 used it (video + audio latent stored)
- Default: OFF (no env set = stock behaviour)
- Base: upstream stable-diffusion.cpp 32d516c + 01-taban-hiz-yamalari, applied in series order.
