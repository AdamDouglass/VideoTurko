# Contributing / Katki

**EN** Thank you for helping. Most useful: **tests on other GPUs** (card, driver, frame count, time, VRAM peak, pass/fail of the gates), clearer install steps, and measured improvements to memory use.

Rules that keep results comparable:
- Quality settings stay fixed (6 steps, cfg 1, 640x384, seed 42, non-tiled VAE). A speed-up that lowers quality is not accepted.
- A patch must give a byte-identical 56-frame output to the reference (`docs/KANITLAR.md`, `scripts/bayt_kiyas.py`) or be clearly marked experimental and default-off. Patch files stay LF.
- Every claim needs evidence: measured (with the log), read from a file (with the path), or labelled as a guess.
- No personal paths, names, e-mails or tokens; no model weights or videos in a pull request.
- Keep the Turkish and English text of a section in step.

Docs are kept in English and Turkish only (enough for this project). There are no package dependencies to update, so no dependency bot is configured.

How: open an issue first for bigger changes; small fixes can go straight to a pull request using the template.

**TR** Katki icin tesekkurler. En degerli katki: baska ekran kartlarinda test (kart, surucu, kare sayisi, sure, VRAM tepesi, kapilar), daha net kurulum adimlari ve olculmus bellek iyilestirmeleri. Kalite ayarlari sabit; yama 56 karede referansa bayt ayni olmali ya da deneysel ve varsayilan kapali isaretlenmeli; her iddia kanitli olmali; kisisel yol, model agirligi ve video eklenmez.
