# 0007

Graph-cut tensors of at least N MB captured into host RAM instead of VRAM (pure copy)

- Env flag: SD_CUT_CACHE_HOST_MB=<MB>
- Evidence: B56H9k R0; F209V2K/F141Vh2K byte-identical (with 0017)
- Default: OFF (no env set = stock behaviour)
- Base: upstream stable-diffusion.cpp 32d516c + 01-taban-hiz-yamalari, applied in series order.
