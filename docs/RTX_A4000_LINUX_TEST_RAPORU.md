# RTX A4000 16 GB on Linux: test report / test raporu

> EN summary [user-reported]: 19 runs through `./uret.sh` on one RTX A4000 16 GB (Ubuntu Server 24.04, engine built with `scripts/derle_linux.sh`): text-to-video from 56 to 209 frames, first-frame and first+last-frame at 192 frames, one process at 209 frames, a vertical size, three larger sizes and three other prompts. All 19 clips passed the quality gate. Quality settings were not changed. The card ran at 94 C with software thermal slowdown, so the times are those of a throttled card.
>
> TR özet [kullanıcı bildirdi]: tek bir RTX A4000 16 GB'ta (Ubuntu Server 24.04, motor `scripts/derle_linux.sh` ile derlendi) `./uret.sh` ile 19 koşu: 56-209 kare metinden video, 192 karede ilk kare ve ilk+son kare, 209 karede tek süreç, dikey boyut, üç büyük boyut ve üç başka istem. 19 klibin hepsi kalite kapısından geçti. Kalite ayarları değişmedi. Kart 94 C'de yazılımsal ısı kısmasıyla çalıştı; süreler kısılmış kartın süreleridir.

The labels below are the contributor's own. Claude Code (an AI coding agent) ran the tests on the contributor's server. The contributor watched the clips.

Model license (`docs/LISANS_KABUL.txt`): the contributor's own decision, given before the engine build.

**Date:** 2026-11-24. **Commit:** `82cf26c`, no local changes to the scripts.

## Hardware and system

| | |
|---|---|
| Card | NVIDIA RTX A4000, 16 GB (16376 MiB), compute capability 8.6, 9 MiB in use before each run |
| Driver | 595.91.07 |
| RAM | 31 GB, 7 GB swap; lowest available RAM in any run here 27795 MiB (2 s samples) |
| OS | Ubuntu Server 24.04.5, kernel 6.8.0-149 |
| Engine | stable-diffusion.cpp `32d516c` with the repo patches, built for `sm_86` by `scripts/derle_linux.sh` |

`nvidia-smi` name, total memory, driver, compute capability [measured]: `NVIDIA RTX A4000, 16376, 595.91.07, 8.6`.

## Install

- `./kur.sh --kuru`: exit 0, no error line [measured].
- `--kuru` returned 0 although `cmake`, `nvcc` and Python `ensurepip` were all missing: it does not check the build tools [measured].
- The tools were put under the root, with no system package and no sudo: CUDA 12.8 (`nvcc` 12.8.93), g++ 13.4 and cmake 4.5.1 from conda-forge in `engine/toolchain/env` (`derle_linux.sh` looks there), and `.venv` made with `uv` [measured].
- Build: `DERLE_OK` in 29 min 48 s including the source clone, 4 jobs [measured]. A large file copy to the same machine was running meanwhile.
- The four model files were copied from another machine; `./kur.sh --dogrula` reported the right sha256 for all four [measured].
- 5-frame check: `HAZIR / READY`, exit 0 [measured].

## Method

```
./uret.sh --istem docs/ornek_istem_R0.txt --kare <N>
```

One run per row, seed 42, `f32` cuBLAS set by the script. At 640x384, 56 and 107 frames ran in one process and longer ones in two (the script's own rule), unless stated. Time is the wall time of `uret.sh` including the gate. VRAM is the whole card, `nvidia-smi` every 2 s, so short spikes can be missed. A peak is not a minimum requirement: three other prompts at 209 frames peaked about 1.8 GB lower.

## Text-to-video, 640x384 [measured]

| Frames | Time | VRAM peak | Gate | Noise / flow / N |
|---|---|---|---|---|
| 56 | 52 s | 10965 MiB | passed | 0.68 / 3.60 / 0.030 |
| 107 | 90 s | 11165 MiB | passed | 0.74 / 3.20 / 0.028 |
| 141 | 149 s | 13669 MiB | passed | 0.54 / 3.37 / 0.025 |
| 158 | 176 s | 14149 MiB | passed | 0.74 / 4.01 / 0.027 |
| 175 | 193 s | 14663 MiB | passed | 0.59 / 2.94 / 0.031 |
| 192 | 210 s | 15151 MiB | passed | 0.67 / 3.55 / 0.032 |
| 209 | 229 s | 15647 MiB | passed | 0.59 / 3.05 / 0.029 |

Contributor's viewing: all fine, no black frames.

## One process, image inputs and vertical [measured]

| Run | Frames | Time | VRAM peak | Gate | Noise / flow / N | Contributor's viewing |
|---|---|---|---|---|---|---|
| `--tek-asama` | 209 | 190 s | 13261 MiB | passed | 0.62 / 3.22 / 0.031 | fine |
| `--init-img` | 192 | 268 s | 15325 MiB | passed | 0.48 / 1.89 / 0.025 | very smooth |
| `--init-img` + `--end-img` | 192 | 330 s | 15523 MiB | passed | 0.49 / 1.66 / 0.024 | very smooth |
| `-W 384 -H 640` | 141 | 149 s | 13669 MiB | passed | 0.56 / 1.63 / 0.031 | fine |

The input images are the first and last frame of the 209-frame clip above. The one-process run was faster and used less VRAM than the two-process run at 209 frames; one run each.

## Larger sizes [measured]

The gate is calibrated at 640x384 and reads lower noise at larger sizes, so these passes are weaker evidence; the viewing column matters more here.

| Size | Frames | Time | VRAM peak | Gate | Noise / flow / N | Contributor's viewing |
|---|---|---|---|---|---|---|
| 832x480 | 56 | 82 s | 10857 MiB | passed | 0.45 / 3.95 / 0.024 | very good quality |
| 832x480 | 141 | 246 s | 14155 MiB | passed | 0.54 / 3.59 / 0.027 | fine |
| 832x480 | 209 | 391 s | 15625 MiB | passed | 0.49 / 3.18 / 0.026 | very good, better than the ones before it |
| 1024x576 | 56 | 140 s | 14723 MiB | passed | 0.48 / 3.44 / 0.022 | clearly higher resolution |
| 1280x704 | 56 | 215 s | 15493 MiB | passed | 0.34 / 4.79 / 0.023 | very good resolution |

1024x576 and 1280x704 were not tried above 56 frames [not tried].

## Other prompts, 209 frames, 640x384 [measured]

Three of the contributor's own four-slice prompts; only the time slices were rescaled to the clip length.

| Scene | Time | VRAM peak | Gate | Noise / flow / N | Contributor's viewing |
|---|---|---|---|---|---|
| Earthworms, flood | 291 s | 13855 MiB | passed | 1.28 / 3.46 / 0.048 | more detailed than the same scene at 158 frames on the contributor's RTX 3060 Laptop; the worms tangle together at the end |
| Frog leap | 265 s | 13827 MiB | passed | 0.87 / 0.79 / 0.039 | good |
| City in the hair | 271 s | 13821 MiB | passed | 0.90 / 7.32 / 0.032 | no problem seen |

The first of these runs overlapped with a video re-encode on the same machine, so its time may be slightly high.

## Notes

- **Temperature** [measured]: 94 C peak in 17 of the 19 runs here (56 frames: 76 C, 107 frames: 92 C). Software thermal slowdown was active in the one detailed reading, with 1380-1470 MHz of 2100 MHz and the fan at 76%. Hardware thermal slowdown stayed at 0 us in every reading. The limits the card reports: 98 C max operating, 100 C slowdown, 103 C shutdown.
- **Another GPU process** [measured]: the sampler flagged a process other than `sd-cli` in the 192-frame text-to-video run and in the earthworm run. For the 192-frame run it was one sample out of 101, at 183 MiB and 0% load. The name was not recorded; [guess] `sd-cli` starting or ending.
- **Not done** [not tried]: byte comparison with the reference, repeat runs, other seeds.
