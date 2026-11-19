# Security / Guvenlik

**EN** If you find a vulnerability, do not open a public issue. Use GitHub private reporting: **Security > Report a vulnerability** on the repository page. Include the version (`git log -1`), how to trigger it and its impact. We will look at reports as soon as we can and credit you if you wish.

Scope: the scripts in `scripts/`, the patches in `patches/` and release packages built from them. Out of scope: the MiniMax H3 model, stable-diffusion.cpp upstream and the NVIDIA CUDA runtime (report to their own projects).

Design notes (not vulnerabilities): the installer verifies every download against a pinned sha256 and stops on a mismatch; `-ExecutionPolicy Bypass` affects only that one PowerShell process, so read `scripts\kur.ps1` before running it; the scripts open no network port and need no administrator rights.

**TR** Guvenlik acigi bulduysaniz herkese acik issue acmayin; GitHub'in ozel bildirimini kullanin (**Security > Report a vulnerability**). Surumu, nasil tetiklendigini ve etkisini yazin. Kapsam: `scripts/`, `patches/` ve bunlardan uretilen paketler; model ve ust projeler kapsam disidir.
