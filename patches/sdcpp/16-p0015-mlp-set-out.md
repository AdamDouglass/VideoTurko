# 0015

MLP chunk outputs written into one destination via set_inplace (instead of concat copies)

- Env flag: SD_MLP_SET_OUT=1
- Evidence: 56 frames byte-identical to R0 (B56H9k, B56H10b, B56H11: sha256 0979f156...). Alone, 0015 raised memory (+320 MB at 209 frames) because its destination was a graph-start leaf; 0020 fixes that.
- Default: OFF (no env set = stock behaviour)
- Base: upstream stable-diffusion.cpp 32d516c + 01-taban-hiz-yamalari, applied in series order.
