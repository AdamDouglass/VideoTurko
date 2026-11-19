#!/usr/bin/env python
"""bayt_kiyas.py: iki H3 cikti dosyasini (AVI: MJPEG + PCM) karsilastirir.
Kullanim (poetrey venv, izole):
  python -I bayt_kiyas.py <taban.avi> <aday.avi> [--json cikti.json]
Kademe: 1) dosya sha256  2) kare md5 (ffmpeg framemd5) + ses md5  3) yalniz 1-2 farkliysa PSNR (kare, 4x4 bolge), SSIM, ses SNR.
Karar: BAYT_AYNI | PSNR_ADAY (her kare PSNR>=50 ve ses SNR>=50: yonetici onayi gerekir) | RED.
Neden bu ekler: kalite kurali (BRIF_hiz): bayt ayni ya da her kare >=50 dB ve ses >=50 dB SNR.
Yan etki yok: yalniz okur; ffmpeg alt sureci kapanisi beklenir (zombi yok). Cikti: konsol + istege bagli JSON.
"""
import sys, os, json, hashlib, subprocess, re
import numpy as np
import cv2

FFMPEG = os.environ.get("FFMPEG", r"C:\ffmpeg\bin\ffmpeg.exe")
ESIK_PSNR = 50.0
ESIK_SNR = 50.0


def sha256(yol):
    h = hashlib.sha256()
    with open(yol, "rb") as f:
        for blok in iter(lambda: f.read(1 << 20), b""):
            h.update(blok)
    return h.hexdigest()


def calistir(arg):
    # gizli pencere, cikis beklenir (yetim surec yok)
    p = subprocess.run(arg, capture_output=True, creationflags=0x08000000 if os.name == "nt" else 0)
    if p.returncode != 0:
        raise RuntimeError("ffmpeg hata: " + p.stderr.decode(errors="replace")[-300:])
    return p.stdout


def kare_md5(yol):
    cikti = calistir([FFMPEG, "-v", "error", "-i", yol, "-an", "-f", "framemd5", "-"]).decode()
    return [s.split(",")[-1].strip() for s in cikti.splitlines() if s and not s.startswith("#")]


def ses_md5(yol):
    cikti = calistir([FFMPEG, "-v", "error", "-i", yol, "-vn", "-f", "md5", "-"]).decode().strip()
    return cikti.replace("MD5=", "")


def ses_pcm(yol):
    ham = calistir([FFMPEG, "-v", "error", "-i", yol, "-vn", "-f", "s16le", "-acodec", "pcm_s16le", "-"])
    return np.frombuffer(ham, dtype="<i2").astype(np.float64)


def kareler(yol):
    cap = cv2.VideoCapture(yol)
    liste = []
    try:
        while True:
            ok, k = cap.read()
            if not ok:
                break
            liste.append(k)
    finally:
        cap.release()
    return liste


def psnr(a, b):
    mse = np.mean((a.astype(np.float64) - b.astype(np.float64)) ** 2)
    return 99.0 if mse == 0 else 10 * np.log10(255.0 ** 2 / mse)


def bolge_psnr_min(a, b, n=4):
    h, w = a.shape[:2]
    en_kotu = 99.0
    for i in range(n):
        for j in range(n):
            ya, yb = i * h // n, (i + 1) * h // n
            xa, xb = j * w // n, (j + 1) * w // n
            en_kotu = min(en_kotu, psnr(a[ya:yb, xa:xb], b[ya:yb, xa:xb]))
    return en_kotu


def snr_db(ref, test):
    n = min(len(ref), len(test))
    ref, test = ref[:n], test[:n]
    gurultu = np.sum((ref - test) ** 2)
    sinyal = np.sum(ref ** 2)
    if gurultu == 0:
        return 99.0
    if sinyal == 0:
        return -99.0
    return 10 * np.log10(sinyal / gurultu)


def kiyas(taban, aday):
    s = {"taban": taban, "aday": aday}
    s["sha256_taban"], s["sha256_aday"] = sha256(taban), sha256(aday)
    s["dosya_bayt_ayni"] = s["sha256_taban"] == s["sha256_aday"]
    km_t, km_a = kare_md5(taban), kare_md5(aday)
    s["kare_sayisi"] = [len(km_t), len(km_a)]
    s["kare_md5_ayni"] = (km_t == km_a)
    s["kare_md5_farkli_sayisi"] = (sum(1 for x, y in zip(km_t, km_a) if x != y) + abs(len(km_t) - len(km_a)))
    s["ses_md5_ayni"] = (ses_md5(taban) == ses_md5(aday))
    if s["dosya_bayt_ayni"] or (s["kare_md5_ayni"] and s["ses_md5_ayni"]):
        s["karar"] = "BAYT_AYNI"
        return s
    # kademe 3: sayisal fark
    if len(km_t) != len(km_a):
        s["karar"] = "RED"
        s["neden"] = "kare sayisi farkli"
        return s
    kt, ka = kareler(taban), kareler(aday)
    ps = [psnr(a, b) for a, b in zip(kt, ka)]
    bl = [bolge_psnr_min(a, b) for a, b in zip(kt, ka)]
    s["psnr_min"], s["psnr_ort"] = float(min(ps)), float(np.mean(ps))
    s["bolge_psnr_min_4x4"] = float(min(bl))
    en_kotu = int(np.argmin(ps))
    s["en_kotu_kare"] = en_kotu
    try:
        from skimage.metrics import structural_similarity as ssim
        s["ssim_min"] = float(min(ssim(a, b, channel_axis=2) for a, b in zip(kt, ka)))
    except Exception as e:  # skimage yoksa atla, yazilir
        s["ssim_min"] = None
        s["ssim_not"] = "skimage yok: " + str(e)[:80]
    pt, pa = ses_pcm(taban), ses_pcm(aday)
    s["ses_ornek"] = [len(pt), len(pa)]
    s["ses_md5_ayni"] = s["ses_md5_ayni"]
    s["ses_snr_db"] = float(snr_db(pt, pa)) if len(pt) == len(pa) and len(pt) > 0 else None
    s["ses_maks_mutlak_fark"] = float(np.max(np.abs(pt - pa))) if len(pt) == len(pa) and len(pt) > 0 else None
    kare_ok = s["psnr_min"] >= ESIK_PSNR
    ses_ok = s["ses_md5_ayni"] or (s["ses_snr_db"] is not None and s["ses_snr_db"] >= ESIK_SNR)
    s["karar"] = "PSNR_ADAY" if (kare_ok and ses_ok) else "RED"
    s["not"] = "PSNR_ADAY = bayt ayni degil; nedeni yazilir ve yonetici onayi gerekir" if s["karar"] == "PSNR_ADAY" else "kalite kapisi gecmedi"
    return s


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(2)
    sonuc = kiyas(sys.argv[1], sys.argv[2])
    metin = json.dumps(sonuc, indent=2, ensure_ascii=False)
    print(metin)
    if "--json" in sys.argv:
        with open(sys.argv[sys.argv.index("--json") + 1], "w", encoding="utf-8") as f:
            f.write(metin)
    sys.exit(0 if sonuc["karar"] != "RED" else 1)
