# 0016

Never fall back to tiled (approximate) VAE decode; return the error instead

- Env flag: SD_VAE_NO_TILING_FALLBACK=1
- Evidence: Used in F209V2 (tiling 0); error return only
- Default: OFF (no env set = stock behaviour)
- Base: upstream stable-diffusion.cpp 32d516c + 01-taban-hiz-yamalari, applied in series order.
