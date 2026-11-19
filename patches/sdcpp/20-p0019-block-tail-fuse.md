# 0019

Per-chunk block tail: out_proj + residual + norm2/modulate + MLP + gated residual written into one destination (removes full-length intermediates)

- Env flag: SD_BLOCK_TAIL_FUSE=1
- Evidence: 56 frames byte-identical to R0 with the flag on (B56H11: sha256 0979f156..., together with MLP_SET_OUT). No byte reference for 141+ frames. Its effect is not visible in the log; only the capacity gate margin shows it.
- Default: OFF (no env set = stock behaviour)
- Base: upstream stable-diffusion.cpp 32d516c + 01-taban-hiz-yamalari, applied in series order.
