# 0020

0015/0019 destination is created by ggml_pad of the first chunk (an op, allocated late) instead of a graph-start leaf

- Env flag: (acts with SD_MLP_SET_OUT / SD_BLOCK_TAIL_FUSE)
- Evidence: Same 56-frame byte gate as 0015/0019 (B56H10b, B56H11: 0979f156...). Experimental, default off; not used by the 209 run.
- Default: OFF (no env set = stock behaviour)
- Base: upstream stable-diffusion.cpp 32d516c + 01-taban-hiz-yamalari, applied in series order.
