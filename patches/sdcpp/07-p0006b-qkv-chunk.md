# 0006b

Chunked QKV projection. ALONE it raises the peak by +121.5 MB (copies + concat): use together with SD_QKV_SET_OUT (0014)

- Env flag: SD_QKV_CHUNK_MB=<MB>
- Evidence: Measured +121.5 MB alone; byte gate together with 0014 (B141K)
- Default: OFF (no env set = stock behaviour)
- Base: upstream stable-diffusion.cpp 32d516c + 01-taban-hiz-yamalari, applied in series order.
