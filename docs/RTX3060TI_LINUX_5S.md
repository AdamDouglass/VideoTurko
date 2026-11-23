# RTX 3060 Ti 8 GB on Linux with a 5-second 1080p output

Community measurements from one Linux rig, taken on 2026-11-22. This run used a custom CUDA build and an experimental four-step profile. The results apply to that profile. The VideoTurko Windows installer, 56-frame byte comparison and VideoTurko quality gate were outside this test.

## Setup

- [read] RTX 3060 Ti (sm_86), 8192 MiB VRAM, Linux, NVIDIA driver 595.99.02. Each run used one GPU. Card memory was sampled every 500 ms with `nvidia-smi`.
- [read] Linux CUDA 12.8.1 engine built for sm_86 from stable-diffusion.cpp `32d516c` with the VideoTurko v0.1.2 patch series and the encoder changes from [stable-diffusion.cpp #2337](https://github.com/leejet/stable-diffusion.cpp/pull/2337) and [#2340](https://github.com/leejet/stable-diffusion.cpp/pull/2340). From #2340, this build applies the changes to the conditioner, the model loader and name conversion.
- [read] HyperFlow Flash FL2VA Q4_K_M, Qwen3-VL 4B Instruct Q4_K_M and the matching P-H3 embeddings connector, one first-frame image, seed 20261122, four Euler steps, `hyperflow-h3-flash-4`, CFG 1 and 24 fps. The engine used `--offload-to-cpu --mmap --max-vram 7.0`, CUDA text encoding, diffusion flash attention, cuBLAS f32 and VAE tiling fallback disabled.
- [read] The same source PNG and prompt were used for both orientations. The prompt asked for a slow camera move through a living room while retaining the layout and furniture. The source was resized to the engine canvas for each run.

## Measurements

| Engine canvas | Final canvas | H3 wall time | Post-processing | Total wall time | Peak card VRAM |
| --- | --- | ---: | ---: | ---: | ---: |
| 640x384 | 1920x1080 | 145.99 s | 16.96 s | 162.94 s | 7551 MiB |
| 384x640 | 1080x1920 | 145.57 s | 16.94 s | 162.51 s | 7551 MiB |

[measured] One run per orientation. Post-processing includes CUDA FP16 Real-ESRGAN general-x4v3, FFmpeg H.264/AAC encoding and output verification. The end-to-end timestamps were rounded independently.

[read] H3 renders the next supported frame count on its 17k+5 grid, 124. The wrapper keeps both endpoints and distributes the four removed frames across the video. It retimes the generated audio to match the 120-frame output.

[measured] FFprobe reported 120 frames at 24 fps and exactly 5.000000 seconds for both the H.264 video and AAC audio in each MP4. These checks cover the output format and timing. Visual quality, other frame counts and VideoTurko's fixed six-step profile on this card remain unmeasured here.
