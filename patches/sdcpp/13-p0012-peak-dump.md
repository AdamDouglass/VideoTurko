# 0012

Offline liveness estimate per segment graph (diagnostic; the real compute buffer was about 2x the estimate)

- Env flag: SD_PEAK_DUMP=<segment N>
- Evidence: No arithmetic; diagnostic output only
- Default: OFF (no env set = stock behaviour)
- Base: upstream stable-diffusion.cpp 32d516c + 01-taban-hiz-yamalari, applied in series order.
