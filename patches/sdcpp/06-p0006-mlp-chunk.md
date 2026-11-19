# 0006

Cap the MLP token chunk so fc1/swiglu intermediates stay small

- Env flag: SD_MLP_CHUNK_MB=<MB>
- Evidence: B56C3/B56M4: 56 frames byte-identical to R0
- Default: OFF (no env set = stock behaviour)
- Base: upstream stable-diffusion.cpp 32d516c + 01-taban-hiz-yamalari, applied in series order.
