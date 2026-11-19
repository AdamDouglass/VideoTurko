# 0006c

Equal-sized chunks when the env cap is set (no tiny tail chunk: small batches may pick another matmul kernel)

- Env flag: (with SD_MLP_CHUNK_MB)
- Evidence: Part of the 0006 gates
- Default: OFF (no env set = stock behaviour)
- Base: upstream stable-diffusion.cpp 32d516c + 01-taban-hiz-yamalari, applied in series order.
