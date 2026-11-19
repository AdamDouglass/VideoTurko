# 0017

Capacity estimate no longer counts cut tensors that go to host RAM (with 0007)

- Env flag: SD_CUT_CACHE_HOST_MB=<MB>
- Evidence: F209V2K/F141Vh2K byte-identical; estimate only
- Default: OFF (no env set = stock behaviour)
- Base: upstream stable-diffusion.cpp 32d516c + 01-taban-hiz-yamalari, applied in series order.
