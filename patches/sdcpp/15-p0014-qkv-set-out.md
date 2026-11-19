# 0014

Chunked q/k/v written into preallocated tensors (set_inplace, pure copy)

- Env flag: SD_QKV_SET_OUT=1 (+ SD_QKV_CHUNK_MB)
- Evidence: B141K: sha E5D028F8632BE4FE
- Default: OFF (no env set = stock behaviour)
- Base: upstream stable-diffusion.cpp 32d516c + 01-taban-hiz-yamalari, applied in series order.
