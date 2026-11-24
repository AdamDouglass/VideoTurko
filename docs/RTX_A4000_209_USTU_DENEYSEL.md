# RTX A4000 above 209 frames: experiment / 209 kare üstü deneme

> EN summary [user-reported, PR #18; maintainers did not repeat the runs]: **not a supported length; 209 stays the recommended maximum.** On the same RTX A4000 16 GB (Linux) as `RTX_A4000_LINUX_TEST_RAPORU.md`, text-to-video at 640x384 ran from 226 to 481 frames with `VT_MAX_KARE` and passed the gate at every length tried; 515 stopped on an engine assertion, not on VRAM. Some clips showed prompt-following flaws that the gate does not detect. No change to the 209 limit is proposed.
>
> TR özet [kullanıcı bildirdi, PR #18; bakımcılar tekrar etmedi]: **desteklenen uzunluk değildir; önerilen üst sınır 209 kalır.** `RTX_A4000_LINUX_TEST_RAPORU.md` ile aynı RTX A4000 16 GB'ta (Linux) 640x384 metinden video, `VT_MAX_KARE` ile 226-481 kare arasında denenen her uzunlukta kapıdan geçti; 515 kare VRAM'de değil, motordaki bir assert'te durdu. Bazı kliplerde kapının görmediği, isteme uymama kusurları vardı. 209 sınırını değiştirme önerisi yoktur.

**Date:** 2026-11-24. **Commit, card, engine and method:** as in `RTX_A4000_LINUX_TEST_RAPORU.md`. Quality settings were not changed. Two processes (the script's default at these lengths), one run per row, seed 42. The card peaked at 93-94 C in every completed run; the times are those of a throttled card.

```
VT_MAX_KARE=<N> ./uret.sh --istem docs/ornek_istem_R0.txt --kare <N>
```

## Sample prompt [user-reported]

| Frames | Length | Time | VRAM peak | Gate | Noise / flow / N | Contributor's viewing |
|---|---|---|---|---|---|---|
| 226 | 9.4 s | 246 s | 14143 MiB | passed | 0.66 / 2.99 / 0.028 | fine |
| 243 | 10.1 s | 266 s | 14487 MiB | passed | 0.62 / 4.04 / 0.027 | fine |
| 277 | 11.5 s | 311 s | 15235 MiB | passed | 0.62 / 3.47 / 0.028 | fine, but the cat's left eye stays plain black |
| 311 | 13.0 s | 363 s | 15639 MiB | passed | 0.54 / 3.95 / 0.028 | fine; eyes as at 277, very good in the final zoom |
| 345 | 14.4 s | 411 s | 15603 MiB | passed | 0.82 / 2.55 / 0.026 | fine; left eye weak again |
| 379 | 15.8 s | 458 s | 15403 MiB | passed | 0.67 / 3.03 / 0.027 | no problem seen |
| 413 | 17.2 s | 513 s | 14561 MiB | passed | 0.59 / 2.84 / 0.027 | clean, including the head movement at the end |
| 447 | 18.6 s | 559 s | 15005 MiB | passed | 0.56 / 1.62 / 0.030 | different angle, solid, no errors |
| 481 | 20.0 s | 618 s | 15457 MiB | passed | 0.61 / 3.60 / 0.027 | only the left eye is bad, the rest is solid |
| 515 | 21.5 s | 19 s | - | no video | - | exit 1, see below |

Lengths between these rows, including 498, were not tried [not tried]. The sampler flagged another GPU process in the 243-frame run; its name was not recorded.

## Other prompts, 345 frames [user-reported]

The same three prompts as in the 209-frame table of the other report, with the time slices rescaled.

| Scene | Time | VRAM peak | Gate | Noise / flow / N | Contributor's viewing |
|---|---|---|---|---|---|
| Earthworms, flood | 461 s | 15671 MiB | passed | 1.05 / 2.48 / 0.045 | the worms have expressions but look like small balls, not worms; the ending is better than at 209 |
| Frog leap | 444 s | 15653 MiB | passed | 0.73 / 0.47 / 0.035 | more detailed frog and a cleaner rise than at 209 |
| City in the hair | 455 s | 15435 MiB | passed | 1.05 / 5.90 / 0.034 | lice sharper than at 209; the camera goes straight out instead of pulling back, which looks like an editing error; the face is clear at the end |

## Why 515 stopped

```
ggml.c:3555: GGML_ASSERT(offset < (size_t)(1 << 30)) failed
```

- [user-reported] `sd-cli` exit 134 (abort) while building the graph, with 179 MiB of VRAM in use; `uret.sh` reports it as `VT-E-LATENT`, exit 1. Not retried.
- [read] The backtrace resolves to `ggml_set_inplace` called from `MiniMaxH3::Attention::project_qkv` (`addr2line`). The assertion is in `ggml_set_impl`. `SD_QKV_SET_OUT` (patch 0014) is read in `minimax_h3.hpp`, and `uret.sh` sets it only for two processes.
- [guess] The preallocated buffer of patch 0014 passes 1 GiB between 481 and 515 frames at this size. Whether one process gets past this point was not tried, so the VRAM limit of the card is unknown.

## What this does and does not show

- The flaws seen are about following the prompt (subject shape, eyes, last camera move), not about the flow; the contributor noted no black frames in the sample-prompt clips up to 345 frames and the earthworm clip, where this was checked explicitly.
- The eye flaw does not grow steadily with length: seen at 277, 311, 345 and 481, not noted at 226, 243, 379, 413 and 447. One seed per clip, and the 345-frame scenes also have longer time slices, so length is not shown to be the cause.
- The gate passed every completed clip, including those with flaws: a pass does not check prompt following or motion consistency.
- The contributor's conclusion: the frame count can be raised on this card, but 209 is the safer choice and enough for the purpose of this project.
