# 0011

Evict earlier segments weights when the capacity gate fails

- Env flag: SD_H3_EVICT_PAST=1
- Evidence: B56H4: sha 0979f156 = R0 (placement only)
- Default: OFF (no env set = stock behaviour)
- Base: upstream stable-diffusion.cpp 32d516c + 01-taban-hiz-yamalari, applied in series order.
