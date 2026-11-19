# 0013

Attention head-group outputs written into one preallocated tensor (set_inplace, pure copy)

- Env flag: SD_ATTN_SET_OUT=1
- Evidence: B141K: sha E5D028F8632BE4FE = P5_141 reference (with 0014/0006)
- Default: OFF (no env set = stock behaviour)
- Base: upstream stable-diffusion.cpp 32d516c + 01-taban-hiz-yamalari, applied in series order.
