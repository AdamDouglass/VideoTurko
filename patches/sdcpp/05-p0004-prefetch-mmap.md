# 0004

Ask the OS to read the mmap-ed model ahead (PrefetchVirtualMemory)

- Env flag: SD_PREFETCH_MMAP_MATCH=<substring of model file name>
- Evidence: Order of reads only; bytes unchanged
- Default: OFF (no env set = stock behaviour)
- Base: upstream stable-diffusion.cpp 32d516c + 01-taban-hiz-yamalari, applied in series order.
